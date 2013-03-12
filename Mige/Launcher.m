//
//  Launcher.m
//  Mige
//
//  Created by Taro Minowa on 3/5/13.
//  Copyright (c) 2013 Higepon Taro Minowa. All rights reserved.
//

#import "Launcher.h"

@implementation Launcher

+ (BOOL)tryOpenURL:(NSString*)url
{
    UIApplication* ourApplication = [UIApplication sharedApplication];
    BOOL isAppInstalled = [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:url]];
    if(isAppInstalled) {
        NSURL *ourURL = [NSURL URLWithString:url];
        [ourApplication openURL:ourURL];
        return YES;
    }else {
        return NO;
    }
}

@end
