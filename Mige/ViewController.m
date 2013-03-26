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

typedef enum {
    STATE_RECORDING,
    STATE_PROCESSING,
    STATE_STOP
} State;

@interface ViewController () <SpeechToTextModuleDelegate, ConfigGetterDelegate>

@property UIButton* recordButton;
@property UILabel* commandLabel;
@property SpeechToTextModule* speechToText;
@property BOOL animationShouldEventuallyStop;
@property int rotationIndex;
@property State state;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.rotationIndex = 0;
    self.state = STATE_STOP;
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
    self.state = STATE_PROCESSING;
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
    self.state = STATE_STOP;
    return YES;
}

- (void)record:(UIButton*)button
{
    if (self.state == STATE_STOP) {
        self.commandLabel.text = @"recording...";
        self.state = STATE_RECORDING;
        [self startRecordingAnimation];
        [self.speechToText beginRecording];
    }
}

- (void)recordingAnimationLoop
{
    const double ANGLE_DELTA = 0.125;
    const int MAX_ROTATION_INDEX = 1 / ANGLE_DELTA;
    BOOL buttonInOrigin = self.rotationIndex % MAX_ROTATION_INDEX == 1;
    BOOL animationStopImmediately = (self.state != STATE_RECORDING) && buttonInOrigin;
    if (animationStopImmediately) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDuration:0.15];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(endAnimation)];
    [self.recordButton  setTransform:CGAffineTransformMakeRotation(ANGLE_DELTA * self.rotationIndex * 2 * M_PI)];
    self.rotationIndex++;
    [UIView commitAnimations];
}

- (void)startRecordingAnimation
{
    self.animationShouldEventuallyStop = NO;
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
