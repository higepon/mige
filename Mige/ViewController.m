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

@property NSDictionary* config;
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
    self.config = NULL;
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



- (NSDictionary *)defaultConfig
{
    static NSDictionary* config = NULL;
    if (config == NULL) {
#if 0
        config = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 @"comgooglemaps://?saddr=&daddr=Suite+900,+1355+Market+St,+San+Francisco,+CA&directionsmode=transit", @"directions to Twitter",
                                 @"twitter://post?message=", @"Twitter",
                                 @"fb://publish/?text=", @"Facebook",
                                 @"twitter://timeline", @"home",
                                 @"twitter://mentions", @"connect",
                                 @"googlegmail://co?subject=&body=&to=higepon@gmail.com", @"Gmail",
                                 @"camplus://", @"camera",
                                 @"foursquare://", @"Foursquare",
                  @"jp.gocro.smartnews://", @"news", nil];
#else
        config = [[NSDictionary alloc] init];
#endif
    }
    return config;
}

- (BOOL)didReceiveVoiceResponse:(NSData *)data
{
    NSDictionary* config = self.config == NULL ? [self defaultConfig] : self.config;
    self.commandLabel.text = [self extractTextFromJson:data];
    NSArray* words = [self.commandLabel.text componentsSeparatedByString: @" "];    

    NSString* url;
    if ([words count] > 1 && [[words objectAtIndex:0] isEqualToString:@"Google"]) {
        
        NSArray* keywords = [words subarrayWithRange:NSMakeRange(1, words.count - 1)];
        url = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", [keywords componentsJoinedByString:@"%20"]];
    } else {
        url = [config objectForKey:self.commandLabel.text];
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
    if ([self.commandLabel.text isEqualToString:@""]) {
        [self record:self.recordButton];
    }
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
    self.config = config;
}
@end
