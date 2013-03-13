//
//  ConfigGetter.m
//  Mige
//
//  Created by Taro Minowa on 3/12/13.
//  Copyright (c) 2013 Higepon Taro Minowa. All rights reserved.
//

#import "ConfigGetter.h"

@implementation ConfigGetter

- (id)initWithDelegate:(id<ConfigGetterDelegate>)delegate
{
    self = [super init];
    self.delegate = delegate;
    self.responseData = [NSMutableData data];
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate didReceiveConfig:NULL];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError* myError = nil;
    NSDictionary* ret = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&myError];
    [self.delegate didReceiveConfig:ret];
}

+ (void)getConfig:(id<ConfigGetterDelegate>)delegate
{
    ConfigGetter* getter = [[ConfigGetter alloc] initWithDelegate:delegate];
    NSString* urlString = @"https://gist.github.com/higepon/5149511/raw/";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    id req = [[NSURLConnection alloc] initWithRequest:request delegate:getter];
    if (req == nil) {
        [delegate didReceiveConfig:NULL];
        return;
    }
}

@end
