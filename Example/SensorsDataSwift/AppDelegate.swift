//
// AppDelegate.swift
// HinaDataSwift
//
// Created by hina on 2022/11/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


import UIKit
import HinaDataSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        //MARK:初始化sdk
        let options = HNConfigOptions(serverURL: "http://sdk-test.cloud.hinadata.cn:8006/sa?project=default&token=95c73ae661f85aa0", launchOptions: launchOptions)
        options.maxCacheSize = 10000;
        options.autoTrackEventType = [.eventTypeAppClick,.eventTypeAppStart,.eventTypeAppEnd,.eventTypeAppViewScreen]
        options.enableVisualizedAutoTrack = true
        options.enableHeatMap = true
        HinaDataSDK.start(configOptions: options)

        HinaDataSDK.sharedInstance()?.setFlushNetworkPolicy(HinaDataNetworkType.typeALL)

        let dict: Dictionary = ["key": "value", "key1": "value1"]
        HinaDataSDK.sharedInstance()?.track("testEvent", withProperties: dict)
        HinaDataSDK.sharedInstance()?.enableTrackScreenOrientation(true)

        window = UIWindow()
        let rootVC: UIViewController = ViewController()
        window?.rootViewController = UINavigationController(rootViewController: rootVC)
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

