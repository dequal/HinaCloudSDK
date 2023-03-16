//
// AppDelegate.m
// SensorsData
//
// Created by 曹犟 on 15/7/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AppDelegate.h"
#import <HinaCloudSDK/HinaCloudSDK.h>
//@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"
//@"BHRfsTQS"  @"yt888"
static NSString* Sa_Default_ServerURL = @"https://loanetc.mandao.com/hn?token=BHRfsTQS";

@interface AppDelegate ()

@end
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    HNBuildOptions *options = [[HNBuildOptions alloc] initWithServerURL:Sa_Default_ServerURL launchOptions:launchOptions];
    options.autoTrackEventType = HNAutoTrackAppStart | HNAutoTrackAppEnd | HNAutoTrackAppClick | HNAutoTrackAppScreen;
    options.flushNetworkPolicy = HNNetworkTypeALL;
    options.enableTrackAppCrash = YES;
    
//   options.flushInterval = 10 * 1000;
//   options.flushPendSize = 100;
    
    options.enableHeatMap = YES;
    options.enableVisualizedAutoTrack = YES;
    options.enableJSBridge = YES;
    options.enableLog = YES;
    options.maxCacheSize = 20000;

    [HinaCloudSDK startWithConfigOptions:options];

    [[HinaCloudSDK sharedInstance] registerSuperProperties:@{@"AAA":UIDevice.currentDevice.identifierForVendor.UUIDString}];
    [[HinaCloudSDK sharedInstance] registerCommonProperties:^NSDictionary * _Nonnull{
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

    [[HinaCloudSDK sharedInstance] trackAppInstallWithProperties:@{@"testValue" : @"testKey"}];
    //[[HinaCloudSDK sharedInstance] addHeatMapViewControllers:[NSArray arrayWithObject:@"DemoController"]];

    [[HinaCloudSDK sharedInstance] enableTrackScreenOrientation:YES];
    [[HinaCloudSDK sharedInstance] enableTrackGPSLocation:YES];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    if ([[HinaCloudSDK sharedInstance] canHandleURL:url]) {
        [[HinaCloudSDK sharedInstance] handleSchemeUrl:url];
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([[HinaCloudSDK sharedInstance] canHandleURL:userActivity.webpageURL]) {
        [[HinaCloudSDK sharedInstance] handleSchemeUrl:userActivity.webpageURL];
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
    //@"group.cn.com.sensorsAnalytics.share"
    [[HinaCloudSDK sharedInstance]trackEventFromExtensionWithGroupIdentifier:@"group.cn.com.sensorsAnalytics.share" completion:^(NSString *identifiy ,NSArray *events){

    }];
//  NSArray  *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier: @"group.cn.com.sensorsAnalytics.share"];
//   NSLog(@"applicationDidBecomeActive::::::%@",eventArray);
//   for (NSDictionary *dict in eventArray  ) {
//       [[HinaCloudSDK sharedInstance]track:dict[SA_EVENT_NAME] withProperties:dict[SA_EVENT_PROPERTIES]];
//   }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[[SAAppExtensionDataManager sharedInstance]deleteEventsWithGroupIdentifier:@"dd"];
    //[[SAAppExtensionDataManager sharedInstance]readAllEventsWithGroupIdentifier:NULL];
    //[[SAAppExtensionDataManager sharedInstance]writeEvent:@"eee" properties:@"" groupIdentifier:@"ff"];
    //[[SAAppExtensionDataManager sharedInstance]fileDataCountForGroupIdentifier:@"ff"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

