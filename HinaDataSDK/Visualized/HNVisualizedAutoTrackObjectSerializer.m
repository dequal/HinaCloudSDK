//
// HNObjectSerializer.m
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "NSInvocation+HNHelpers.h"
#import "HNClassDescription.h"
#import "HNLog.h"
#import "HNObjectIdentityProvider.h"
#import "HNVisualizedAutoTrackObjectSerializer.h"
#import "HNObjectSerializerConfig.h"
#import "HNObjectSerializerContext.h"
#import "HNPropertyDescription.h"
#import "HNWebElementView.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNJavaScriptBridgeManager.h"
#import "HNVisualizedManager.h"
#import "HNConstants+Private.h"

@interface HNVisualizedAutoTrackObjectSerializer ()
@end

@implementation HNVisualizedAutoTrackObjectSerializer {
    HNObjectSerializerConfig *_configuration;
    HNObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(HNObjectSerializerConfig *)configuration
               objectIdentityProvider:(HNObjectIdentityProvider *)objectIdentityProvider {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }
    
    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject {
    NSParameterAssert(rootObject != nil);
    if (!rootObject) {
        return nil;
    }

    HNObjectSerializerContext *context = [[HNObjectSerializerContext alloc] initWithRootObject:rootObject];
    
    @try {// 遍历 _unvisitedObjects 中所有元素，解析元素信息
        while ([context hasUnvisitedObjects]) {
            [self visitObject:[context dequeueUnvisitedObject] withContext:context];
        }
    } @catch (NSException *e) {
        HNLogError(@"Failed to serialize objects: %@", e);
    }

    NSMutableDictionary *serializedObjects = [NSMutableDictionary dictionaryWithDictionary:@{
        @"objects" : [context allSerializedObjects],
        @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    }];
    return [serializedObjects copy];
}

- (void)visitObject:(NSObject *)object withContext:(HNObjectSerializerContext *)context {
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);

    [context addVisitedObject:object];

    // 获取构建单个元素的所有属性
    NSMutableDictionary *propertyValues = [[NSMutableDictionary alloc] init];

    // 获取当前类以及父类页面结构需要的 name,superclass、properties
    HNClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        // 遍历自身和父类的所需的属性及类型，合并为当前类所有属性
        for (HNPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            // 根据是否符号要求（是否显示等）构建属性，通过 KVC 和 NSInvocation 动态调用获取描述信息
            id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];         // $递增作为元素 id
            propertyValues[propertyDescription.key] = propertyValue;
        }
    }

    if (NSClassFromString(@"FlutterView") && [object isKindOfClass:NSClassFromString(@"FlutterView")]) {
        UIView *flutterView = (UIView *)object;
        [[HNVisualizedObjectSerializerManager sharedInstance] enterWebViewPageWithView:flutterView];

        [self checkFlutterElementInfoWithView:flutterView];
    }
    if ([object isKindOfClass:WKWebView.class]) {
        // 针对 WKWebView 数据检查
        WKWebView *webView = (WKWebView *)object;

        [[HNVisualizedObjectSerializerManager sharedInstance] enterWebViewPageWithView:webView];

        [self checkWKWebViewInfoWithWebView:webView];
    } else {
        SEL isWebViewSEL = NSSelectorFromString(@"isWebViewWithObject:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:isWebViewSEL] && [self performSelector:isWebViewSEL withObject:object]) {
#pragma clang diagnostic pop
            // 暂不支持非 WKWebView，添加弹框
            [[HNVisualizedObjectSerializerManager sharedInstance] enterWebViewPageWithView:nil];
        }
    }

    NSArray *classNames = [self classHierarchyArrayForObject:object];
    if ([object isKindOfClass:HNWebElementView.class]) {
        HNWebElementView *touchView = (HNWebElementView *)object;
        classNames = @[touchView.tagName];
    }

    propertyValues[@"element_level"] = @([context currentLevelIndex]);
    NSDictionary *serializedObject = @{ @"id": [_objectIdentityProvider identifierForObject:object],
                                        @"class": classNames, // 遍历获取父类名称
                                        @"attr": propertyValues };

    [context addSerializedObject:serializedObject];
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object {
    NSMutableArray *classHierarchy = [[NSMutableArray alloc] init];
    
    Class aClass = [object class];
    while (aClass) {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }
    return [classHierarchy copy];
}

- (NSInvocation *)invocationForObject:(id)object
              withSelectorDescription:(HNPropertySelectorDescription *)selectorDescription {
    
    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");
    
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;
    
    if (methodSignature) {
        NSAssert([methodSignature numberOfArguments] == 2, @"Unexpected number of arguments!");
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue
propertyDescription:(HNPropertyDescription *)propertyDescription
            context:(HNObjectSerializerContext *)context {
    
    if ([context isVisitedObject:propertyValue]) {
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([self isNestedObjectType:propertyDescription.type]) {
        [context enqueueUnvisitedObject:propertyValue];
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]) {
        NSMutableArray *arrayOfIdentifiers = [[NSMutableArray alloc] init];
        if ([propertyValue isKindOfClass:[NSArray class]]) {
            [context enqueueUnvisitedObjects:propertyValue];
        } else if ([propertyValue isKindOfClass:[NSSet class]]) {
            [context enqueueUnvisitedObjects:[(NSSet *)propertyValue allObjects]];
        }

        for (id value in propertyValue) {
            [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
        }
        propertyValue = [arrayOfIdentifiers copy];
    }

    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object
     withPropertyDescription:(HNPropertyDescription *)propertyDescription
                     context:(HNObjectSerializerContext *)context {
    HNPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;
    
    // 使用 kvc 解析属性
    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        
        id valueForKey = [object valueForKey:selectorDescription.selectorName];
        
        // 将获取到的属性属于 classes 中的元素添加到 _unvisitedObjects 中，递增生成当前元素唯一 Id
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];
        
        return value;
    } else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        
        // 通过 NSInvocation 构造并动态调用 selector，获取元素描述信息
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            [invocation sa_setArgumentsFromArray:@[]];
            [invocation invokeWithTarget:object];
            
            id returnValue = [invocation sa_returnValue];
            
            id value = [self propertyValue:returnValue
                       propertyDescription:propertyDescription
                                   context:context];
            if (value) {
                return value;
            }
        }
    }
    return nil;
}

- (BOOL)isNestedObjectType:(NSString *)typeName {
    return [_configuration classWithName:typeName] != nil;
}

- (HNClassDescription *)classDescriptionForObject:(NSObject *)object {
    NSParameterAssert(object != nil);
    
    Class aClass = [object class];
    while (aClass != nil) {
        HNClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];
        if (classDescription) {
            return classDescription;
        }
        
        aClass = [aClass superclass];
    }
    
    return nil;
}

#pragma mark webview
- (void)checkFlutterElementInfoWithView:(UIView *)flutterView {
    // 延时检测是否 Flutter SDK 版本是否正确
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 延迟判断是否存在 Flutter SDK 发送数据
        HNVisualizedPageInfo *currentWebPageInfo = [[HNVisualizedObjectSerializerManager sharedInstance] queryPageInfoWithType:HNVisualizedPageTypeFlutter];
        if (currentWebPageInfo.pageType != HNVisualizedPageTypeFlutter) {
            return;
        }
        // 已成功注入页面信息
        if (currentWebPageInfo.screenName.length > 0 || currentWebPageInfo.elementSources.count > 0) {
            return;
        }
        NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
        alertInfo[@"title"] = HNLocalizedString(@"HNVisualizedPageErrorTitle");
        alertInfo[@"message"] = HNLocalizedString(@"HNVisualizedFlutterPageErrorMessage");
        alertInfo[@"link_text"] =  HNLocalizedString(@"HNVisualizedConfigurationDocument");
        alertInfo[@"link_url"] = @"https://manual.hinadata.cn/sa/latest/flutter-22257963.html";
        if ([HNVisualizedManager defaultManager].visualizedType == HinaDataVisualizedTypeHeatMap) {
            alertInfo[@"title"] = HNLocalizedString(@"HNAppClickHNnalyticsPageErrorTitle");
        }
        [currentWebPageInfo registWebAlertInfos:@[alertInfo]];
    });
}

/// 检查 WKWebView 相关信息
- (void)checkWKWebViewInfoWithWebView:(WKWebView *)webView {
    HNVisualizedPageInfo *webPageInfo = [[HNVisualizedObjectSerializerManager sharedInstance] readWebPageInfoWithWebView:webView];

    // 存在有效 web 元素数据
    if (webPageInfo.url || (webPageInfo.elementSources.count > 0 && webPageInfo.pageType == HNVisualizedPageTypeWeb)) {
        return;
    }

    NSMutableString *javaScriptSource = [NSMutableString string];
    // 如果未接收到 H5 页面元素信息，异常场景处理
    // 当前 WKWebView 是否注入可视化全埋点 Bridge 标记
    NSArray<WKUserScript *> *userScripts = webView.configuration.userContentController.userScripts;
    // 防止重复注入标记（js 发送数据，是异步的，防止 hinadata_visualized_mode 已经注入完成，但是尚未接收到 js 数据）
    __block BOOL isContainVisualized = NO;
    [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        // 已注入可视化扫码状态标记
        if ([obj.source containsString:kHNJSBridgeVisualizedMode]) {
            isContainVisualized = YES;
            *stop = YES;
        }
    }];

    if (isContainVisualized) {
        // 只有包含可视化全埋点 Bridge 标记，并且未接收到 JS 页面信息，需要检测 JS SDK 集成情况
        [self checkJSSDKIntegrationWithWebView:webView];
    } else {
        // 注入 bridge 属性值，标记当前处于可视化全埋点扫码状态
        NSString *visualizedMode = [HNJavaScriptBridgeBuilder buildVisualBridgeWithVisualizedMode:YES];
        [javaScriptSource appendString:visualizedMode];

    }

    /* 主动通知 JS SDK 发送数据：
     1. 存在部分场景，H5 页面内元素滚动，JS SDK 无法检测，如果 App 截图变化，直接通知 JS SDK 遍历最新页面元素数据发送
     2. 可能先进入 H5，再扫码开启可视化全埋点，此时未成功注入标记，通过调用 JS 方法，手动通知 JS SDK 发送数据
     */
    NSString *jsMethodString = [HNJavaScriptBridgeBuilder buildCallJSMethodStringWithType:HNJavaScriptCallJSTypeVisualized jsonObject:nil];
    [javaScriptSource appendString:jsMethodString];
    [webView evaluateJavaScript:javaScriptSource completionHandler:^(id _Nullable response, NSError *_Nullable error) {
        if (error) {
            /*
             如果 JS SDK 尚未加载完成，可能方法不存在；
             等到 JS SDK加载完成检测到 hinadata_visualized_mode 会尝试发送数据页面数据
             */
            HNLogDebug(@"window.hinadata_app_call_js error：%@", error);
        }
    }];
}

/// 检测 JS SDK 是否集成
- (void)checkJSSDKIntegrationWithWebView:(WKWebView *)webView {
    // 延时检测是否集成 JS SDK（JS SDK 可能存在延时动态加载）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 延迟判断是否存在 js 发送数据
        HNVisualizedPageInfo *currentWebPageInfo = [[HNVisualizedObjectSerializerManager sharedInstance] readWebPageInfoWithWebView:webView];
        if (currentWebPageInfo.url) {
            return;
        }
        // 注入了 bridge 但是未接收到数据
        NSString *javaScript = [HNJavaScriptBridgeBuilder buildCallJSMethodStringWithType:HNJavaScriptCallJSTypeCheckJSSDK jsonObject:nil];
        [webView evaluateJavaScript:javaScript completionHandler:^(id _Nullable response, NSError *_Nullable error) {
            if (!error) {
                return;
            }
            NSDictionary *userInfo = error.userInfo;
            NSString *exceptionMessage = userInfo[@"WKJavaScriptExceptionMessage"];
            // js 环境未定义此方法，可能是未集成 JS SDK 或者 JS SDK 版本过低
            if (exceptionMessage && [exceptionMessage containsString:@"undefined is not a function"]) {
                NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
                alertInfo[@"title"] = HNLocalizedString(@"HNVisualizedPageErrorTitle");
                alertInfo[@"message"] = HNLocalizedString(@"HNVisualizedJSError");
                alertInfo[@"link_text"] = HNLocalizedString(@"HNVisualizedConfigurationDocument");
                alertInfo[@"link_url"] = @"https://manual.hinadata.cn/sa/latest/tech_sdk_client_web_use-7548173.html";
                if ([HNVisualizedManager defaultManager].visualizedType == HinaDataVisualizedTypeHeatMap) {
                    alertInfo[@"title"] = HNLocalizedString(@"HNAppClickHNnalyticsPageErrorTitle");
                }
                NSMutableDictionary *alertInfoMessage = [@{ @"callType": @"app_alert", @"data": @[alertInfo] } mutableCopy];
                [[HNVisualizedObjectSerializerManager sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo:alertInfoMessage];
            }
        }];
    });
}

@end
