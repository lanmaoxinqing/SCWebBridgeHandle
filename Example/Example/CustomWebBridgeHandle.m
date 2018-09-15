//
//  CustomWebBridgeHandle.m
//  Example
//
//  Created by 心情 on 2018/9/15.
//  Copyright © 2018年 心情. All rights reserved.
//

#import "CustomWebBridgeHandle.h"

@implementation CustomWebBridgeHandle

- (void)excludeTest {
    
}

- (void)SCWebBridgeInject(test) {
    
}

- (void)SCWebBridgeInject(testParam:(id)data) {
    NSLog(@"%@", data);
}

- (id)SCWebBridgeInject(testReturn) {
    return @"response from native";
}

- (id)SCWebBridgeInject(testParamReturn:(id)data) {
    NSLog(@"%@", data);
    return @"response from native";
}


- (void)SCWebBridgeInject(testCallback:(WVJBResponseCallback)callback) {
    callback(@"response from native callback");
}


- (void)SCWebBridgeInject(test:(id)data :(WVJBResponseCallback)callback) {
    NSLog(@"%@", data);
    callback(@"response from native callback");
}

- (void)SCWebBridgeInject(test:(id)data callback:(WVJBResponseCallback)callback) {
    NSLog(@"%@", data);
    callback(@"response from native callback");
}




@end
