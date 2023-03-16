//
// TestViewController.m
// HinaDataSDK
//
// Created by hina on 2022/9/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import "TestViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Test";
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onControlClick:(id)sender {
    NSLog(@"****:onControlClick");
}

- (IBAction)onButtonClick:(id)sender {
    NSLog(@"****:onButtonClick");
}

- (IBAction)onButtonClick2:(id)sender {
    NSLog(@"****:onButtonClick2");
}
@end
