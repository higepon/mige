//
//  ViewController.m
//  Mige
//
//  Created by Taro Minowa on 3/5/13.
//  Copyright (c) 2013 Higepon Taro Minowa. All rights reserved.
//

#import "ViewController.h"
#import "SpeechToTextModule.h"
#import "Launcher.h"

@interface ViewController () <SpeechToTextModuleDelegate>

@property UIButton* recordButton;
@property UIButton* stopButton;
@property UILabel* commandLabel;
@property SpeechToTextModule* speechToText;

@end

@implementation ViewController

// Make the button bigger
// Start recording whenever it's comming foreground.
//   No need to push the button
//   show status "recording" or "stop"
// Register more commands
// Good parts

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.speechToText = [[SpeechToTextModule alloc] init];
    self.speechToText.delegate = self;
    self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.recordButton setTitle:@"record" forState:UIControlStateNormal];
    self.recordButton.frame = CGRectMake(10, 10, 100, 30);
    [self.recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.recordButton];
    
    self.commandLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 200, 200, 100)];
    [self.view addSubview:self.commandLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onForeground)
                                                               name:UIApplicationDidBecomeActiveNotification object:nil];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)onForeground
{
    NSLog(@"Foreground!");
    [self.speechToText beginRecording];    
}

- (NSString*)extractTextFromJson:(NSData*)data
{
    NSError* myError = nil;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&myError];
    
    NSArray* hypotheses = [json objectForKey:@"hypotheses"];
    if (hypotheses.count > 0) {
        NSDictionary* hypothesis = [hypotheses objectAtIndex:0];
        return [hypothesis objectForKey:@"utterance"];
    }
    return @"";
}



- (BOOL)didReceiveVoiceResponse:(NSData *)data
{
    NSDictionary* commandDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 @"comgooglemaps://?saddr=&daddr=Suite+900,+1355+Market+St,+San+Francisco,+CA&directionsmode=transit", @"directions to Twitter", @"value2", @"key2", nil];
    
    self.commandLabel.text = [self extractTextFromJson:data];
    NSString* url = [commandDict objectForKey:self.commandLabel.text];
    if (url) {
        if ([Launcher tryOpenURL:url]) {
            NSLog(@"YES");
        } else {
            NSLog(@"NO");
        }
    }
    NSLog(@"command was %@", self.commandLabel.text);
    return YES;
}

- (void)record:(UIButton*)button
{
    NSLog(@"start");
    [self.speechToText beginRecording];
}

- (void)stop:(UIButton*)button
{
    NSLog(@"stop");
    [self.speechToText stopRecording:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
