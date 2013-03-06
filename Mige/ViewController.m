//
//  ViewController.m
//  Mige
//
//  Created by Taro Minowa on 3/5/13.
//  Copyright (c) 2013 Higepon Taro Minowa. All rights reserved.
//

#import "ViewController.h"
#import "SpeechToTextModule.h"

@interface ViewController ()

@property SpeechToTextModule* speechToText;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.speechToText = [[SpeechToTextModule alloc] init];    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
