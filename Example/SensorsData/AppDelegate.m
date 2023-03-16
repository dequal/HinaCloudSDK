//
// AppDelegate.m
// HinaData
//
// Created by 曹犟 on 15/7/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import "AppDelegate.h"
#import <HinaDataSDK/HinaDataSDK.h>

//static NSString* Sa_Default_ServerURL = @"http://sdk-test.cloud.hinadata.cn:8006/sa?project=default&token=95c73ae661f85aa0";
static NSString* Hn_Default_ServerURL = @"https://loanetc.mandao.com/ha?token=yt888";   //yt888  BHRfsTQS

@interface AppDelegate ()

@end
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    HNConfigOptions *options = [[HNConfigOptions alloc] initWithServerURL:Hn_Default_ServerURL launchOptions:launchOptions];
    options.autoTrackEventType = HinaDataEventTypeAppStart | HinaDataEventTypeAppEnd | HinaDataEventTypeAppClick | HinaDataEventTypeAppViewScreen;
    options.flushNetworkPolicy = HinaDataNetworkTypeALL;
    options.enableTrackAppCrash = YES;
//   options.flushInterval = 10 * 1000;
//   options.flushBulkSize = 100;
    options.enableHeatMap = YES;
    options.enableVisualizedAutoTrack = YES;
    options.enableJavaScriptBridge = YES;
    options.enableLog = YES;
    options.maxCacheSize = 20000;
    [HinaDataSDK startWithConfigOptions:options];

    [[HinaDataSDK sharedInstance] registerSuperProperties:@{@"AAA":UIDevice.currentDevice.identifierForVendor.UUIDString}];
    [[HinaDataSDK sharedInstance] registerDynamicSuperProperties:^NSDictionary * _Nonnull{
        __block UIApplicationState appState;
        if (NSThread.isMainThread) {
            appState = UIApplication.sharedApplication.applicationState;
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                appState = UIApplication.sharedApplication.applicationState;
            });
        }
        return @{@"__APPState__":@(appState)};
    }];

    [[HinaDataSDK sharedInstance] trackAppInstallWithProperties:@{@"testValue" : @"testKey"}];
    //[[HinaDataSDK sharedInstance] addHeatMapViewControllers:[NSArray arrayWithObject:@"DemoController"]];

    [[HinaDataSDK sharedInstance] enableTrackScreenOrientation:YES];
    [[HinaDataSDK sharedInstance] enableTrackGPSLocation:YES];
    
    return YES;
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    if ([[HinaDataSDK sharedInstance] canHandleURL:url]) {
        [[HinaDataSDK sharedInstance] handleSchemeUrl:url];
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([[HinaDataSDK sharedInstance] canHandleURL:userActivity.webpageURL]) {
        [[HinaDataSDK sharedInstance] handleSchemeUrl:userActivity.webpageURL];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //@"group.cn.com.hinaData.share"
    [[HinaDataSDK sharedInstance]trackEventFromExtensionWithGroupIdentifier:@"group.cn.com.hinaData.share" completion:^(NSString *identifiy ,NSArray *events){

    }];
//  NSArray  *eventArray = [[HNAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier: @"group.cn.com.hinaData.share"];
//   NSLog(@"applicationDidBecomeActive::::::%@",eventArray);
//   for (NSDictionary *dict in eventArray  ) {
//       [[HinaDataSDK sharedInstance]track:dict[HN_EVENT_NAME] withProperties:dict[HN_EVENT_PROPERTIES]];
//   }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[[HNAppExtensionDataManager sharedInstance]deleteEventsWithGroupIdentifier:@"dd"];
    //[[HNAppExtensionDataManager sharedInstance]readAllEventsWithGroupIdentifier:NULL];
    //[[HNAppExtensionDataManager sharedInstance]writeEvent:@"eee" properties:@"" groupIdentifier:@"ff"];
    //[[HNAppExtensionDataManager sharedInstance]fileDataCountForGroupIdentifier:@"ff"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

