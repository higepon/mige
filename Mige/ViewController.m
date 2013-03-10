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
//   search parts available for free
// Tweet URL

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.speechToText = [[SpeechToTextModule alloc] init];
    self.speechToText.delegate = self;
    
    self.commandLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 240, 200, 50)];
    self.commandLabel.backgroundColor = [UIColor blackColor];
    self.commandLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.commandLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onForeground)
                                                               name:UIApplicationDidBecomeActiveNotification object:nil];
    
    UIImage* img = [UIImage imageNamed:@"Voice_Memos.png"];
    UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(130, 180, 60, 60)];
    [btn setBackgroundImage:img forState:UIControlStateNormal];

    [btn addTarget:self
            action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: btn];
	// Do any additional setup after loading the view, typically from a nib.
}

// This is called when SpeechToText posts audio data to Google API
- (void)showLoadingView
{
    self.commandLabel.text = @"processing...";    
}

- (void)onForeground
{
    [self.speechToText beginRecording];
    self.commandLabel.text = @"recording...";
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
                                 @"comgooglemaps://?saddr=&daddr=Suite+900,+1355+Market+St,+San+Francisco,+CA&directionsmode=transit", @"directions to Twitter",
                                    @"twitter://post?message=", @"Twitter", @"fb://publish/?text=", @"Facebook",
                                    @"googlegmail:///co?subject=&body=&to=higepon@gmail.com", @"Gmail", nil];

    
    
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
    self.commandLabel.text = @"recording...";
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
