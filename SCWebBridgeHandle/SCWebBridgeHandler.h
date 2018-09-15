//
//  SCWebBridgeHandler.h
//  jsbridgeTest
//
//  Created by 心情 on 2018/4/10.
//  Copyright © 2018年 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#import "SCWebBridgeHandleProtocol.h"

/**
 建立 OC 和 JS 方法映射, 供 JSBridge 进行js注入.继承本类来自定义需要注入的 js.
 * 映射只接受最多一个 `id` 和一个 `WVJBResponseCallback`入参的 OC 方法. 转换后的 js 方法, 第二个参数首字母大写
 * 被`SCWebBridgeInject`包裹的方法名才会注入
 * 如未提供`WVJBResponseCallback`入参,返回值会自动传递给 JS
 * 如提供了`WVJBResponseCallback`入参,手动调用来控制回调时机
 * 使用 moduleName 来指定 namespace.

 e.g.
 
 模块名:
 oc
 + (NSString *)moduleName {
     return @"test";
 }
 - (void)SCWebBridgeInject(test);
 html
 JSBridge.callHandler('test.test');

 入参和返回值
 oc
 - (id)SCWebBridgeInject(testParamReturn:(id)data);
 html
 JSBridge.callHandler('testReturn', data, function(response) {});

 匿名回调
 oc
 - (void)SCWebBridgeInject(test:(id)data :(WVJBResponseCallback)callback);
 html
 JSBridge.callHandler('test', data, function(response) {});
 
 回调
 oc
 - (void)SCWebBridgeInject(test:(id)data callback:(WVJBResponseCallback)callback);
 html
 JSBridge.callHandler('testCallback', data, function(response) {});

 */

#define SCWebBridgePrefix @"__SC_BRIDGE_INJECT__"
#define SCWebBridgeInject(Selector) __SC_BRIDGE_INJECT__##Selector

@interface SCWebBridgeHandler : NSObject<SCWebBridgeHandleProtocol>

@property (nonatomic, strong, readonly) NSMutableDictionary *userInfo;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;

- (instancetype)initWithBridge:(WebViewJavascriptBridge *)bridge;

- (void)additionRegisters NS_REQUIRES_SUPER;

@end
