//
//  ViewController.m
//  Example
//
//  Created by 心情 on 2018/9/15.
//  Copyright © 2018年 心情. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

#import "CustomWebBridgeHandle.h"


#define SC_STRING_MAKER(str)      #str

NSString * const SCWebViewJavaScriptBridge = @SC_STRING_MAKER(
                                                              ;(function(callback) {
    if (window.WebViewJavascriptBridge) {
        return callback(WebViewJavascriptBridge);
    }
    if (window.WVJBCallbacks) {
        return window.WVJBCallbacks.push(callback);
    }
    window.WVJBCallbacks = [callback];
    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'https://__bridge_loaded__';
    document.documentElement.appendChild(WVJBIframe);
    setTimeout(function () {
        document.documentElement.removeChild(WVJBIframe);
        window.JSBridge = WebViewJavascriptBridge;
        var event = new Event('JSBridgeLoaded');
        document.dispatchEvent(event);
    }, 0);
})(function (bridge) {
    
});
                                                              );

#undef MZ_STRING_MAKER



@interface ViewController ()<UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@property (nonatomic, strong) CustomWebBridgeHandle *bridgeHandle;

@property (nonatomic, strong) WKWebView *webview2;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge2;
@property (nonatomic, strong) CustomWebBridgeHandle *bridgeHandle2;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.webview.delegate = self;
    self.webview2.navigationDelegate = self;
    self.webview2.UIDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"CustomWebBridge" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    
    UIWebView *webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [self.view addSubview:webview];
    [webview loadRequest:[NSURLRequest requestWithURL:url]];
    self.webview = webview;

    WKWebView *webview2 = [[WKWebView alloc] init];
    [self.view addSubview:webview2];
    [webview2 loadRequest:[NSURLRequest requestWithURL:url]];
    self.webview2 = webview2;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webview.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 200);
    self.webview2.frame = CGRectMake(0, 300, CGRectGetWidth(self.view.frame), 200);
}

//MARK:- setup
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
    self.bridgeHandle = [[CustomWebBridgeHandle alloc] initWithBridge:self.bridge];
    [self.webview stringByEvaluatingJavaScriptFromString:SCWebViewJavaScriptBridge];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.bridge2 = [WebViewJavascriptBridge bridgeForWebView:webView];
    self.bridgeHandle2 = [[CustomWebBridgeHandle alloc] initWithBridge:self.bridge2];
    [self.webview2 evaluateJavaScript:SCWebViewJavaScriptBridge completionHandler:nil];
}

//MARK:- UI delegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
