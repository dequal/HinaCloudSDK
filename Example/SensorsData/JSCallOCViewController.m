//
// JSCallOCViewController.m
// HinaDataSDK
//
// Created by hina on 16/9/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import "JSCallOCViewController.h"
#import <HinaDataSDK/HinaDataSDK.h>
#import <WebKit/WebKit.h>

@interface JSCallOCViewController ()<WKNavigationDelegate, WKUIDelegate>
@property WKWebView *webView;
@end
@implementation JSCallOCViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.title = @"WKWebView";

    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"JSCallOC.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];

    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;

    [self.view addSubview:_webView];

    //网址
//   NSString *httpStr=@"https://www.hinadata.cn/test/in.html";
//   NSURL *httpUrl=[NSURL URLWithString:httpStr];
//   NSURLRequest *request=[NSURLRequest requestWithURL:httpUrl];

    [self.webView loadRequest:request];

}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
}

@end

