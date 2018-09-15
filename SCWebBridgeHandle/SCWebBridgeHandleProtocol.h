//
//  SCWebBridgeHandle.h
//  jsbridgeTest
//
//  Created by 心情 on 2018/4/11.
//  Copyright © 2018年 sky. All rights reserved.
//

#ifndef SCWebBridgeHandle_h
#define SCWebBridgeHandle_h

@protocol SCWebBridgeHandleProtocol<NSObject>

@required
@property (nonatomic, readonly, strong) WebViewJavascriptBridge *bridge;
- (void)install;

@optional

/**
 设置模块名.不会与父类模块名合并
 @return 模块名
 */
+ (NSString *)moduleName;

/**
 自定义注册 js 方法.当生成方法不能满足需求时,在本方法中注册
 */
- (void)additionRegisters;

/**
 保存通用参数用于各方法调用

 @param info 保存的参数值
 @param key 参数名
 */
- (void)setUserInfo:(id)info forKey:(NSString *)key;

@end


#endif /* SCWebBridgeHandle_h */
