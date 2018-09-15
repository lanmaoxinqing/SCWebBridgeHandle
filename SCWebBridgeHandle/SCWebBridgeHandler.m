//
//  SCWebBridgeHandler.m
//  jsbridgeTest
//
//  Created by 心情 on 2018/4/10.
//  Copyright © 2018年 sky. All rights reserved.
//

#import "SCWebBridgeHandler.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <JavaScriptCore/JavaScriptCore.h>

typedef NS_OPTIONS(NSUInteger, SCEncodingType) {
    SCEncodingTypeMask       = 0xFF, ///< mask of type value
    SCEncodingTypeUnknown    = 0, ///< unknown
    SCEncodingTypeVoid       = 1, ///< void
    SCEncodingTypeBool       = 2, ///< bool
    SCEncodingTypeInt8       = 3, ///< char / BOOL
    SCEncodingTypeUInt8      = 4, ///< unsigned char
    SCEncodingTypeInt16      = 5, ///< short
    SCEncodingTypeUInt16     = 6, ///< unsigned short
    SCEncodingTypeInt32      = 7, ///< int
    SCEncodingTypeUInt32     = 8, ///< unsigned int
    SCEncodingTypeInt64      = 9, ///< long long
    SCEncodingTypeUInt64     = 10, ///< unsigned long long
    SCEncodingTypeFloat      = 11, ///< float
    SCEncodingTypeDouble     = 12, ///< double
    SCEncodingTypeLongDouble = 13, ///< long double
    SCEncodingTypeObject     = 14, ///< id
    SCEncodingTypeClass      = 15, ///< Class
    SCEncodingTypeSEL        = 16, ///< SEL
    SCEncodingTypeBlock      = 17, ///< block
    SCEncodingTypePointer    = 18, ///< void*
    SCEncodingTypeStruct     = 19, ///< struct
    SCEncodingTypeUnion      = 20, ///< union
    SCEncodingTypeCString    = 21, ///< char*
    SCEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    SCEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    SCEncodingTypeQualifierConst  = 1 << 8,  ///< const
    SCEncodingTypeQualifierIn     = 1 << 9,  ///< in
    SCEncodingTypeQualifierInout  = 1 << 10, ///< inout
    SCEncodingTypeQualifierOut    = 1 << 11, ///< out
    SCEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    SCEncodingTypeQualifierByref  = 1 << 13, ///< byref
    SCEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    SCEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    SCEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    SCEncodingTypePropertyCopy         = 1 << 17, ///< copy
    SCEncodingTypePropertyRetain       = 1 << 18, ///< retain
    SCEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    SCEncodingTypePropertyWeak         = 1 << 20, ///< weak
    SCEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    SCEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    SCEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

/**
 Get the type from a Type-Encoding string.
 
 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
extern SCEncodingType SCEncodingGetType(const char *typeEncoding);
extern SCEncodingType SCEncodingInputTypeForMethod(Method method, unsigned int index);


@interface SCWebBridgeHandler()

@property (nonatomic, strong) NSDictionary *includeMap;
@property (nonatomic, strong) NSMutableDictionary *userInfo;

@end

@implementation SCWebBridgeHandler

+ (NSString *)moduleName {
    return @"";
}

- (instancetype)initWithBridge:(WebViewJavascriptBridge *)bridge {
    if (self = [super init]) {
        self.bridge = bridge;
    }
    return self;
}

//+ (NSArray<NSString *> *)excludeSelectors {
//    return @[
//             NSStringFromSelector(@selector(excludeSelectors)),
//             NSStringFromSelector(@selector(install)),
//             NSStringFromSelector(@selector(setBridge:)),
//             ];
//}

- (NSMutableDictionary *)userInfo {
    if (!_userInfo) {
        _userInfo = [NSMutableDictionary new];
    }
    return _userInfo;
}

- (void)setUserInfo:(id)info forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    [self.userInfo setObject:info forKey:key];
}

- (void)setBridge:(WebViewJavascriptBridge *)bridge {
    _bridge = bridge;
    [self install];
}

- (NSDictionary *)includeMap {
    if (!_includeMap) {
        _includeMap = [NSMutableDictionary dictionary];
    }
    return _includeMap;
}

- (void)additionRegisters {
    
}

//MARK:- install

- (NSString *)prefix {
    //js 方法名前缀
    NSString *prefix = nil;
    if ([self.class respondsToSelector:@selector(moduleName)]) {
        prefix = [self.class moduleName];//test
        if (prefix.length > 0) {
            prefix = [prefix stringByAppendingString:@"."];//test.
        }
    }
    return prefix;
}

- (NSArray *)filtedMethodNames {
    unsigned int count = 0;
    Class clazz = self.class;
    NSMutableArray *filtedMethodNames = [NSMutableArray new];
    while (![clazz isEqual:[SCWebBridgeHandler class]]) {//查找父类方法
        Method *methodList = class_copyMethodList(clazz, &count);
        for (int i = 0; i < count; i++) {
            NSString *methodName = [NSString stringWithUTF8String:sel_getName(method_getName(methodList[i]))];
            //被过滤,不解析为 js 方法
            if (![methodName hasPrefix:SCWebBridgePrefix]) {
                continue;
            }
            SEL sel = NSSelectorFromString(methodName);
            Method ocMethod = class_getInstanceMethod(self.class, sel);
            unsigned int argCount = method_getNumberOfArguments(ocMethod);
            //参数超过2个,不支持转为 js 方法,直接过滤
            if (argCount > 4) {
                continue;
            }
            [filtedMethodNames addObject:methodName];
        }
        free(methodList);
        clazz = [clazz superclass];
    }
    return [filtedMethodNames copy];
}

- (NSString *)jsMethodNameForOCMethodName:(NSString *)methodName prefix:(NSString *)prefix {
    NSMutableString *jsMethodName = [methodName mutableCopy];
    [jsMethodName replaceOccurrencesOfString:SCWebBridgePrefix withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsMethodName.length)];
    //多参方法,第二个是匿名参数
    if ([jsMethodName rangeOfString:@"::"].location != NSNotFound) {
    }
    //多参方法,去除冒号,第二个参数首字母大写. e.g.
    //[test:method:] -> testMethod
    else {
        NSUInteger colonIndex = [jsMethodName rangeOfString:@":"].location;
        if (colonIndex != NSNotFound && colonIndex < jsMethodName.length - 2) {
            NSRange letterRange = NSMakeRange(colonIndex + 1, 1);
            NSString *letter = [jsMethodName substringWithRange:letterRange];
            [jsMethodName replaceCharactersInRange:letterRange withString:[letter uppercaseString]];
        }
    }
    [jsMethodName replaceOccurrencesOfString:@":" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsMethodName.length)];
    if (prefix.length > 0) {
        [jsMethodName insertString:prefix atIndex:0];
    }
    return jsMethodName;
}

- (void)install {
    NSString *prefix = [self prefix];
    NSArray *filtedMethodNames = [self filtedMethodNames];
    //注册 js
    for (NSString *methodName in filtedMethodNames) {
        NSString *jsMethodName = [self jsMethodNameForOCMethodName:methodName prefix:prefix];
        __weak typeof(self) weakSelf = self;
        WVJBHandler handle = ^(id data, WVJBResponseCallback responseCallback) {
            __strong typeof(self) strongSelf = weakSelf;
            SEL sel = NSSelectorFromString(methodName);
            Method ocMethod = class_getInstanceMethod(self.class, sel);
            if (!strongSelf || ocMethod == NULL) {
                return;
            }
            unsigned int argCount = method_getNumberOfArguments(ocMethod);
            /*
             参数检查
             */
            if (argCount == 4) {
                SCEncodingType paramType = SCEncodingInputTypeForMethod(ocMethod, 2);
                SCEncodingType callbackType = SCEncodingInputTypeForMethod(ocMethod, 3);
                if ((paramType & SCEncodingTypeMask) != SCEncodingTypeObject ||
                    (callbackType & SCEncodingTypeMask) != SCEncodingTypeBlock) {
                    NSAssert(NO, @"%@参数格式有误,只允许传入 `id` 或 `WVJBResponseCallback`", methodName);
                    responseCallback(nil);
                    return;
                }
            }
            if (argCount == 3) {
                SCEncodingType inputType = SCEncodingInputTypeForMethod(ocMethod, 2);
                if ((inputType & SCEncodingTypeMask) != SCEncodingTypeObject &&
                    (inputType & SCEncodingTypeMask) != SCEncodingTypeBlock) {
                    NSAssert(NO, @"%@参数格式有误,只允许传入 `id` 或 `WVJBResponseCallback`", methodName);
                    responseCallback(nil);
                    return;
                }
            }
            char *type = method_copyReturnType(ocMethod);
            SCEncodingType returnType = SCEncodingGetType(type);
            free(type);
            if ((returnType & SCEncodingTypeMask) != SCEncodingTypeVoid &&
                (returnType & SCEncodingTypeMask) != SCEncodingTypeObject) {
                NSAssert(NO, @"%@返回值必须是 void 或 id", methodName);
                responseCallback(nil);
                return;
            }
            
            id result = nil;
            //无返回值
            if ((returnType & SCEncodingTypeMask) == SCEncodingTypeVoid) {
                //无入参
                if (argCount == 2) {
                    void (*invoke)(id, SEL) = (void (*)(id, SEL))objc_msgSend;
                    invoke(strongSelf, sel);
                    responseCallback(nil);
                }
                //有入参,判断是不是回调
                else if (argCount == 3) {
                    SCEncodingType inputType = SCEncodingInputTypeForMethod(ocMethod, 2);
                    //id
                    if ((inputType & SCEncodingTypeMask) == SCEncodingTypeObject) {
                        void (*invoke)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
                        invoke(strongSelf, sel, data);
                        responseCallback(nil);
                    }
                    //block
                    else if ((inputType & SCEncodingTypeMask) == SCEncodingTypeBlock) {
                        void (*invoke)(id, SEL, WVJBResponseCallback) = (void (*)(id, SEL, WVJBResponseCallback))objc_msgSend;
                        invoke(strongSelf, sel, responseCallback);
                    }
                }
                //有两个入参,第一个是参数,第二个是回调
                else if (argCount == 4) {
                    void (*invoke)(id, SEL, id, WVJBResponseCallback) = (void (*)(id, SEL, id, WVJBResponseCallback))objc_msgSend;
                    invoke(strongSelf, sel, data, responseCallback);
                }
            }
            //有返回值
            else {
                //无入参
                if (argCount == 2) {
                    id (*invoke)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
                    result = invoke(strongSelf, sel);
                    responseCallback(result);
                }
                //有入参,判断是不是回调
                else if (argCount == 3) {
                    SCEncodingType inputType = SCEncodingInputTypeForMethod(ocMethod, 2);
                    //id
                    if ((inputType & SCEncodingTypeMask) == SCEncodingTypeObject) {
                        id (*invoke)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
                        result = invoke(strongSelf, sel, data);
                        responseCallback(result);
                    }
                    //block
                    else if ((inputType & SCEncodingTypeMask) == SCEncodingTypeBlock) {
                        id (*invoke)(id, SEL, WVJBResponseCallback) = (id (*)(id, SEL, WVJBResponseCallback))objc_msgSend;
                        result = invoke(strongSelf, sel, responseCallback);
                    }
                }
                //有两个入参,第一个是参数,第二个是回调
                else if (argCount == 4) {
                    id (*invoke)(id, SEL, id, WVJBResponseCallback) = (id (*)(id, SEL, id, WVJBResponseCallback))objc_msgSend;
                    result = invoke(strongSelf, sel, data, responseCallback);
                }
            }
        };
        
        [self.bridge registerHandler:jsMethodName
                             handler:handle];
    }
    
    [self additionRegisters];
}

@end

//MARK:- c methods
SCEncodingType SCEncodingInputTypeForMethod(Method method, unsigned int index) {
    unsigned int argCount = method_getNumberOfArguments(method);
    if (index > argCount - 1) {
        return SCEncodingTypeUnknown;
    }
    char type[128] = {};
    method_getArgumentType(method, index, type, 128);
    return SCEncodingGetType(type);
}

SCEncodingType SCEncodingGetType(const char *typeEncoding) {
    char *type = (char *)typeEncoding;
    if (!type) return SCEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return SCEncodingTypeUnknown;
    
    SCEncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r': {
                qualifier |= SCEncodingTypeQualifierConst;
                type++;
            } break;
            case 'n': {
                qualifier |= SCEncodingTypeQualifierIn;
                type++;
            } break;
            case 'N': {
                qualifier |= SCEncodingTypeQualifierInout;
                type++;
            } break;
            case 'o': {
                qualifier |= SCEncodingTypeQualifierOut;
                type++;
            } break;
            case 'O': {
                qualifier |= SCEncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R': {
                qualifier |= SCEncodingTypeQualifierByref;
                type++;
            } break;
            case 'V': {
                qualifier |= SCEncodingTypeQualifierOneway;
                type++;
            } break;
            default: { prefix = false; } break;
        }
    }
    
    len = strlen(type);
    if (len == 0) return SCEncodingTypeUnknown | qualifier;
    
    switch (*type) {
        case 'v': return SCEncodingTypeVoid | qualifier;
        case 'B': return SCEncodingTypeBool | qualifier;
        case 'c': return SCEncodingTypeInt8 | qualifier;
        case 'C': return SCEncodingTypeUInt8 | qualifier;
        case 's': return SCEncodingTypeInt16 | qualifier;
        case 'S': return SCEncodingTypeUInt16 | qualifier;
        case 'i': return SCEncodingTypeInt32 | qualifier;
        case 'I': return SCEncodingTypeUInt32 | qualifier;
        case 'l': return SCEncodingTypeInt32 | qualifier;
        case 'L': return SCEncodingTypeUInt32 | qualifier;
        case 'q': return SCEncodingTypeInt64 | qualifier;
        case 'Q': return SCEncodingTypeUInt64 | qualifier;
        case 'f': return SCEncodingTypeFloat | qualifier;
        case 'd': return SCEncodingTypeDouble | qualifier;
        case 'D': return SCEncodingTypeLongDouble | qualifier;
        case '#': return SCEncodingTypeClass | qualifier;
        case ':': return SCEncodingTypeSEL | qualifier;
        case '*': return SCEncodingTypeCString | qualifier;
        case '^': return SCEncodingTypePointer | qualifier;
        case '[': return SCEncodingTypeCArray | qualifier;
        case '(': return SCEncodingTypeUnion | qualifier;
        case '{': return SCEncodingTypeStruct | qualifier;
        case '@': {
            if (len == 2 && *(type + 1) == '?')
                return SCEncodingTypeBlock | qualifier;
            else
                return SCEncodingTypeObject | qualifier;
        }
        default: return SCEncodingTypeUnknown | qualifier;
    }
}
