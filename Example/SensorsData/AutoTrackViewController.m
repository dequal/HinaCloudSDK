//
// AutoTrackViewController.m
// HinaDataSDK
//
// Created by hina on 2022/4/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import "AutoTrackViewController.h"
#import <HinaDataSDK/HinaDataSDK.h>
#import "TestViewController.h"

@interface AutoTrackViewController ()<HNUIViewAutoTrackDelegate>

@property (weak, nonatomic) IBOutlet UIButton *myButton1;
@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UISwitch *myUISwitch;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@end

@implementation AutoTrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStyleDone target:self action:@selector(nextAction)];
    self.navigationItem.rightBarButtonItem = rightItem;

    self.myLabel.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longTouchUpInside:)];
    [self.myLabel addGestureRecognizer:longGestureRecognizer];

    UITapGestureRecognizer *imageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewTouchUpInside:)];
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:imageViewTapGestureRecognizer];

    [self.myButton1 setAttributedTitle:[[NSAttributedString alloc]initWithString:@"attributedTitle - button1" attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:13], NSForegroundColorAttributeName: [UIColor redColor] }] forState:UIControlStateNormal];

    [self.myLabel setAttributedText:[[NSAttributedString alloc]initWithString:@"attributedText-longGesture" attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:13], NSForegroundColorAttributeName: [UIColor redColor] }]];
    //   self.myLabel.text = @"text----";

}
-(IBAction)stepperOnClick:(UIStepper*)sender {
    NSLog(@"step on:%f",sender.value);
}

-(IBAction)sliderAction:(UISlider*)sender {
    NSLog(@"slider on:%f",sender.value);
}

-(IBAction)picSwitchClick:(UISwitch *)sender {
    NSLog(@"switch on:%d",sender.on);
}

- (IBAction)onButton1Click:(UIButton *)sender {
}

- (IBAction)segmentOnClick:(UISegmentedControl *)sender {
    
}

- (IBAction)pageValueChanged:(UIPageControl *)sender {

}

-(void) longTouchUpInside:(UILongPressGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    NSLog(@"%@手势长按",label.text);

}

-(void) imageViewTouchUpInside:(UITapGestureRecognizer *)recognizer{
    NSLog(@"UIImageView被点击了");

}

- (void)nextAction {
    TestViewController *nextVC = [[TestViewController alloc] init];
    [self.navigationController pushViewController:nextVC animated:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
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

@end