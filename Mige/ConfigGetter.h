//
//  ConfigGetter.h
//  Mige
//
//  Created by Taro Minowa on 3/12/13.
//  Copyright (c) 2013 Higepon Taro Minowa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ConfigGetterDelegate
-(void)didReceiveConfig:(NSDictionary*)config;
@end

@interface ConfigGetter : NSObject
+ (void)getConfig:(id<ConfigGetterDelegate>)delegate;
@property id<ConfigGetterDelegate> delegate;
@property NSMutableData* responseData;
@end
