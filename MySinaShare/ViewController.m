//
//  ViewController.m
//  MySinaShare
//
//  Created by 蔡成汉 on 15/1/12.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "ViewController.h"
#import "WeiboSDK.h"

@interface ViewController ()<WBHttpRequestDelegate>
{
    NSString *accessToken;//授权令牌
    NSDate *expirationDate;//授权过期时间
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //注册通告 -- 用于发送消息
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(authorSuccess:) name:@"authorSuccess" object:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initiaNav];
    
    [self prepareToShare];
    
    //创建一个新浪微博分享的按钮
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shareButton.frame = CGRectMake((self.view.frame.size.width - 200.0)/2, 100, 200, 30);
    [shareButton setTitle:@"新浪微博分享" forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [shareButton addTarget:self action:@selector(shareButtonIsTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
}

-(void)initiaNav
{
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    titleLabel.text = @"新浪微博分享";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:20];
    self.navigationItem.titleView = titleLabel;
}

#pragma mark - 向微博注册appId
-(void)prepareToShare
{
    [WeiboSDK registerApp:@"2045436852"];
    [self getUserInfo];
}

-(void)shareButtonIsTouch:(UIButton *)paramSender
{
    //首先获取WeiboSDK的DeviceToken，如果能够获取的到，则直接进行分享。如果获取不到，则进行授权，然后再进行分享。
    
//    [self doShare];
    
    //关于新浪微博SSO登陆问题 -- 只有安装有微博客户端才可以SSO登陆
    
    //首先获取DeviceToken -- 如果能够获取到DeviceToken，则执行分享操作。如果获取不到DeviceToken，则执行授权登陆。授权登陆分为SSO登陆和普通登陆
    
    
    //判断是否授权、授权过期时间
    if (accessToken == nil)
    {
        //则需要授权 -- 这里需要区分SSO授权和普通授权，但是新版SDK貌似在SSO授权里集成了普通的网页授权
        //此处可直接使用SSO授权
        [self doSSOLogin];
    }
    else
    {
        //判断是否过期
        //进一步判断 -- 授权是否过期
        NSString *tpExpirationTimeString = [NSString stringWithFormat:@"%.0f",[expirationDate timeIntervalSince1970]];
        NSString *timeString = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
        if ([timeString longLongValue] <[tpExpirationTimeString longLongValue])
        {
            //表示授权没有过期 -- 则可直接分享
            [self doShare];
        }
        else
        {
            //表示授权过期了 -- 则需要重新授权
            [self doSSOLogin];
        }
    }
}

//SSO登陆
-(void)doSSOLogin
{
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = @"http://www.sina.com";
    request.scope = @"all";
    [WeiboSDK sendRequest:request];
}

-(void)doShare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //此处的消息发送需要分为有客户端和没有客户端2种情况。对于有客户端，会直接调用客户端进行发送；没有客户端，则需要使用api进行消息发送。
        BOOL isCanShareInWeiboAPP = [WeiboSDK isCanShareInWeiboAPP];
        if (isCanShareInWeiboAPP == YES)
        {
            //使用微博客户端进行分享
            //1.创建消息
            WBMessageObject *message = [WBMessageObject message];
            message.text = @"123456";
            
            
            //            WBImageObject *image = [WBImageObject object];
            //            image.imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"[NSData dataWithContentsOfURL:[NSURL URLWithString:share.thumbImage]]"]];
            //            message.imageObject = image;
            
            WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message];
            [WeiboSDK sendRequest:request];
        }
        else
        {
            //通过URL进行分享
            NSMutableDictionary *parDic = [NSMutableDictionary dictionary];
            [parDic setObject:@"#东京在线#http://tech.qq.com/zt2012/tmtdecode/252.htm" forKey:@"status"];
            [parDic setObject:@"http://fanp4.yokacdn.com/fanup/201403/06/e82aff2705717a398450b40aa9fef15c.jpg" forKey:@"url"];
            
            [WBHttpRequest requestWithAccessToken:accessToken url:@"https://api.weibo.com/2/statuses/upload_url_text.json" httpMethod:@"POST" params:parDic delegate:self withTag:@"upload_url_text"];
        }
    });
}

#pragma mark - 授权成功 -- 来自于授权成功的通告
-(void)authorSuccess:(NSNotification *)notification
{
    [self getUserInfo];
    [self doShare];
}

-(void)getUserInfo
{
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"oauthUser.dic"];

    NSDictionary *paramDic = [NSDictionary dictionaryWithContentsOfFile:documentsDirectory];
    if (paramDic != nil)
    {
        //分别获取accessToken和expirationDate
        NSString *tpAccessToken = [NSString stringWithFormat:@"%@",[paramDic objectForKey:@"accessToken"]];
        NSDate *tpExpirationDate = [paramDic objectForKey:@"expirationDate"];
        accessToken = tpAccessToken;
        expirationDate = tpExpirationDate;
    }
}


/**
 收到一个来自微博Http请求的响应
 
 @param response 具体的响应对象
 */
- (void)request:(WBHttpRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    
}

/**
 收到一个来自微博Http请求失败的响应
 
 @param error 错误信息
 */
- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error
{
    
}

/**
 收到一个来自微博Http请求的网络返回
 
 @param result 请求返回结果
 */
- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result
{
    
}

/**
 收到一个来自微博Http请求的网络返回
 
 @param data 请求返回结果
 */
- (void)request:(WBHttpRequest *)request didFinishLoadingWithDataResult:(NSData *)data
{
    
}

/**
 收到快速SSO授权的重定向
 
 @param URI
 */
- (void)request:(WBHttpRequest *)request didReciveRedirectResponseWithURI:(NSURL *)redirectUrl
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
