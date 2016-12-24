//
//  LJWebViewController.m
//  LJwebView
//
//  Created by liujie on 16/12/23.
//  Copyright © 2016年 liujie. All rights reserved.
//

#import "LJWebViewController.h"
#import <WebKit/WebKit.h>
@interface LJWebViewController ()<UIWebViewDelegate,WKUIDelegate,WKNavigationDelegate>

@property (nonatomic,strong) UIWebView * webView;
@property (nonatomic,strong) WKWebView * wkWebView;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *closeBarButtonItem;
@property (nonatomic, strong) id <UIGestureRecognizerDelegate>delegate;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIProgressView *loadingProgressView;
@property (nonatomic, strong) UIButton *reloadButton;

@end

@implementation LJWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatWebView];
    [self creatNaviItem];
    [self loadRequest];


    // Do any additional setup after loading the view.
}

-(void)creatWebView{
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self CreatreloadButton];//创建加载button
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {

        WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
        configuration.preferences = [[WKPreferences alloc] init];
        configuration.userContentController = [[WKUserContentController alloc] init];
        self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64) configuration:configuration];
        self.wkWebView.navigationDelegate = self;
        self.wkWebView.UIDelegate = self;
        //添加此属性可触发侧滑返回上一网页与下一网页操作
        _wkWebView.allowsBackForwardNavigationGestures = YES;
        //        //进度监听
        [_wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
        [self.view addSubview:self.wkWebView];
//创建进度条
        self.loadingProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, 2)];
        _loadingProgressView.progressTintColor = [UIColor redColor];
        [self.view addSubview:self.loadingProgressView];
    }else{

        self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
        self.webView.delegate = self;
        if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 10.0 && _canDownRefresh) {
            //            _webView.scrollView.refreshControl = self.refreshControl;
        }
        [self.view addSubview:self.webView];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        //获取进度条变化
        _loadingProgressView.progress = [change[@"new"] floatValue] ;
        if (_loadingProgressView.progress == 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _loadingProgressView.hidden = YES;
            });
        }
    }
}
-(void)dealloc{
    [self.wkWebView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.wkWebView stopLoading];
    [self.webView stopLoading];
    self.wkWebView.UIDelegate = nil;
    self.wkWebView.navigationDelegate = nil;
    self.webView.delegate = nil;
}
#pragma mark - 创建加载失败的时候的视图
- (void)CreatreloadButton {
        _reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reloadButton.frame = CGRectMake(0, 0, 150, 150);
        _reloadButton.center = self.view.center;
        _reloadButton.layer.cornerRadius = 75.0;
        [_reloadButton setBackgroundImage:[UIImage imageNamed:@"sure_placeholder_error"] forState:UIControlStateNormal];
        [_reloadButton setTitle:@"您的网络有问题，请检查您的网络设置,\n点击刷新" forState:UIControlStateNormal];
        [_reloadButton addTarget:self action:@selector(webViewReload) forControlEvents:(UIControlEventTouchUpInside)];
        [_reloadButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_reloadButton setTitleEdgeInsets:UIEdgeInsetsMake(200, -50, 0, -50)];
        _reloadButton.titleLabel.numberOfLines = 0;
        _reloadButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        CGRect rect = _reloadButton.frame;
        rect.origin.y -= 100;
        _reloadButton.frame = rect;
        _reloadButton.enabled = NO;
       [self.view addSubview:_reloadButton];
}
-(void)webViewReload{
    [_webView reload];
    [_wkWebView reload];
}
#pragma mark 导航按钮
-(void)creatNaviItem{
    [self showLeftBarButtonItem];
}
-(void)showLeftBarButtonItem {
    if ([self.webView canGoBack] || [self.wkWebView canGoBack]) {
        self.navigationItem.leftBarButtonItems = @[self.backBarButtonItem,self.closeBarButtonItem];
    } else{
    self.navigationItem.leftBarButtonItem = self.backBarButtonItem;
    }
}
- (void)showRightBarButtonItem {
    
}
- (UIBarButtonItem*)backBarButtonItem {
    if (!_backBarButtonItem) {

        _backBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    }
    return _backBarButtonItem;
}
- (UIBarButtonItem*)closeBarButtonItem {
    if (!_closeBarButtonItem) {
        _closeBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    }
    return _closeBarButtonItem;
}
- (void)back:(UIBarButtonItem*)item {
    if ([_webView canGoBack] || [_wkWebView canGoBack]) {
        [_webView goBack];
        [_wkWebView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)close:(UIBarButtonItem*)item {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark 加载请求
- (void)loadRequest {
//    if (![self.url hasPrefix:@"http"]) {//是否具有http前缀
//        self.url = [NSString stringWithFormat:@"http://%@",self.url];
//    }
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0) {
        [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
    }
}
#pragma mark WebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    webView.hidden = NO;
    // 不加载空白网址
    if ([request.URL.scheme isEqual:@"about"]) {
        webView.hidden = YES;
        return NO;
    }
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //导航栏配置
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self showLeftBarButtonItem];
    [_refreshControl endRefreshing];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    webView.hidden = YES;
}

#pragma mark WKNavigationDelegate

#pragma mark 加载状态回调
//页面开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{

    webView.hidden = NO;
    self.loadingProgressView.hidden = NO;
    if ([webView.URL.scheme isEqualToString:@"about"]) {
        webView.hidden = YES;
    }

}
//页面加载完成
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    //导航栏配置
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
        self.navigationItem.title = title;
    }];
    
    [self showLeftBarButtonItem];
}
//页面加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    webView.hidden = YES;
    NSLog(@"页面加载失败");
}
//HTTPS认证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
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
