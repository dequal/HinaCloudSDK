//
// DemoController.m
// HinaDataSDK
//
// Created by ZouYuhan on 1/19/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import "TestTableViewController.h"
#import "TestCollectionViewController.h"
#import <Foundation/Foundation.h>

#import "zlib.h"

#import "DemoController.h"

@implementation DemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.hinaDataDelegate = self;
}

- (NSDictionary *)getTrackProperties {
    return @{@"shuxing" : @"Gaga"};
}

- (NSString *)getScreenUrl {
    return @"WoShiYiGeURL";
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

- (void)testTrack {
    [[HinaDataSDK sharedInstance] track:@"testTrack" withProperties:@{@"testName":@"testTrack 测试"}];
}

- (void)testTrackSignup {
    [[HinaDataSDK sharedInstance] login:@"newId"];
}

- (void)testTrackInstallation {
    [[HinaDataSDK sharedInstance] trackAppInstallWithProperties:nil];
}

- (void)testProfileSet {
    [[HinaDataSDK sharedInstance] set:@"name" to:@"caojiang"];
}

- (void)testProfileAppend {
    [[HinaDataSDK sharedInstance] append:@"array" by:[NSSet setWithObjects:@"123", nil]];
}

- (void)testProfileIncrement {
    [[HinaDataSDK sharedInstance] increment:@"age" by:@1];
}

- (void)testProfileUnset {
    [[HinaDataSDK sharedInstance] unset:@"age"];
}

- (void)testProfileDelete {
    [[HinaDataSDK sharedInstance] deleteUser];
}

- (void)testFlush {
    [[HinaDataSDK sharedInstance] flush];
}

- (void)testCodeless {
    
}

- (NSDictionary *)hinaData_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath {
    return @{@"hinaDelegatePath":[NSString stringWithFormat:@"tableView:%ld-%ld",(long)indexPath.section,(long)indexPath.row]};
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    switch (row) {
        case 0:{
            NSLog(@"测试track");
            [self testTrack];
            TestTableViewController *vc =  [[TestTableViewController alloc] init];
            //TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc]init];
            [self.navigationController pushViewController:vc  animated:YES];
        }
            break;
        case 1l: {
            NSLog(@"测试track_signup");
            [self testTrackSignup];
            TestCollectionViewController_A *collectionVC = [[TestCollectionViewController_A alloc] init];
            [self.navigationController pushViewController:collectionVC animated:YES];
        }
            break;
        case 2l:{
            NSLog(@"测试track_installation");
            [self testTrackInstallation];
            TestCollectionViewController_B *vc =  [[TestCollectionViewController_B alloc] init];
            //TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc]init];
            [self.navigationController pushViewController:vc  animated:YES];
            break;
        }
        case 3l:
            NSLog(@"测试profile_set");
            [self testProfileSet];
            break;
        case 4l:
            NSLog(@"测试profile_append");
            [self testProfileAppend];
            break;
        case 5l:
            NSLog(@"测试profile_increment");
            [self testProfileIncrement];
            break;
        case 6l:
            NSLog(@"测试profile_unset");
            [self testProfileUnset];
            break;
        case 7l:
            NSLog(@"测试profile_delete");
            [self testProfileDelete];
            break;
        case 8l:
            NSLog(@"测试flush");
            [self testFlush];
            break;
        case 9l:
            NSLog(@"进入全埋点测试页面");
            [self testCodeless];
            break;
        default:
            break;
    }
}

@end
