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
#import "ConfigGetter.h"

@interface ViewController () <SpeechToTextModuleDelegate, ConfigGetterDelegate>

@property UIButton* recordButton;
@property UILabel* commandLabel;
@property SpeechToTextModule* speechToText;
@property BOOL animationShouldStop;

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
// Google search


// Next step
//   How to handle google query in config

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
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(130, 320, 60, 60)];
    [self.recordButton setBackgroundImage:img forState:UIControlStateNormal];

    [self.recordButton addTarget:self
            action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.recordButton];
    [self record:self.recordButton];
    [ConfigGetter getConfig:self];
    

	// Do any additional setup after loading the view, typically from a nib.
}

// This is called when SpeechToText posts audio data to Google API
- (void)showLoadingView
{
    self.animationShouldStop = YES;
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
//    NSDictionary* googleSearch = [[NSDictionary alloc] initWithObjectsAndKeys:@"num_params", 2, @"url", @"http://www.google.com/search?q=%s", nil];
    NSDictionary* commandDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 @"comgooglemaps://?saddr=&daddr=Suite+900,+1355+Market+St,+San+Francisco,+CA&directionsmode=transit", @"directions to Twitter",
                                    @"twitter://post?message=", @"Twitter", @"fb://publish/?text=", @"Facebook",
                                    @"twitter://timeline", @"home",
                                    @"twitter://mentions", @"connect",
                                    @"googlegmail://co?subject=&body=&to=higepon@gmail.com", @"Gmail",
//                                    googleSearch, @"Google",
                                    @"camplus://", @"camera",
                                 @"foursquare://", @"Foursquare",
                                    @"jp.gocro.smartnews://", @"news", nil];

    
    
    self.commandLabel.text = [self extractTextFromJson:data];
    NSArray* words = [self.commandLabel.text componentsSeparatedByString: @" "];    
    // split by string
    // if first word is found at the dictionary, then get value as Dictionary
    //   check the keyword length
    //   tokenize
    //   check the length
    //   create url
    //   then go
    //   anything else
/*
    // split string
    NSArray* words = [self.commandLabel.text componentsSeparatedByString: @" "];
    if ([words count] > 1) {
        NSString* first = [words objectAtIndex:0];
        NSDictionary* action = [commandDict objectForKey:first];
        if (action) {
            NSNumber* numParams = [action objectForKey:@"num_params"];
            if ([words count] - 1 == numParams.intValue) {
                NSString* url = [action objectForKey:@"url"];
                NSString* result = url;
                if (url) {
                    for (int i = 0; i < numparams.intValue; i++) {
                        result = [NSString stringWithFormat:result, []
                    }
                    
                }
            }
            
        }
    }
    
    NSLog(@"%@", words);
                                  */
    NSString* url;
    if ([words count] > 1 && [[words objectAtIndex:0] isEqualToString:@"Google"]) {
        
        NSArray* keywords = [words subarrayWithRange:NSMakeRange(1, words.count - 1)];
        url = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", [keywords componentsJoinedByString:@"%20"]];
    } else {
        url = [commandDict objectForKey:self.commandLabel.text];
    }
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
    [self startRecordingAnimation];
    [self.speechToText beginRecording];
}

- (void)recordingAnimationLoop
{
    static double angle = 0;
    if (self.animationShouldStop) {
        NSLog(@"HHHH");
        CGContextRef context = UIGraphicsGetCurrentContext();
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationDuration:0.15];
        [UIView setAnimationDelegate:self];
        [self.recordButton  setTransform:CGAffineTransformMakeRotation(0)];
        [UIView commitAnimations];
        return;
    }
    angle += 0.125;
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDuration:0.15];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(endAnimation)];
    
#if 0
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.02, 1.02)];
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.04, 1.04)];
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.06, 1.06)];
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.04, 1.04)];
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.02, 1.02)];
    [self.recordButton setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
#endif
    [self.recordButton  setTransform:CGAffineTransformMakeRotation(angle * M_PI)];
    
    [UIView commitAnimations];
}

- (void)startRecordingAnimation
{
    self.animationShouldStop = NO;
    [self recordingAnimationLoop];
}

- (void)endAnimation
{
    [self recordingAnimationLoop];
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

- (void)didReceiveConfig:(NSDictionary *)config
{
    NSLog(@"Config=%@", config);
}
@end
