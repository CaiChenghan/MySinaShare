//
//  AppDelegate.m
//  MySinaShare
//
//  Created by 蔡成汉 on 15/1/12.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "WeiboSDK.h"

@interface AppDelegate ()<WeiboSDKDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    ViewController *viewController = [[ViewController alloc]init];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [WeiboSDK handleOpenURL:url delegate:self];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [WeiboSDK handleOpenURL:url delegate:self];
}


/**
 收到一个来自微博客户端程序的请求
 
 收到微博的请求后，第三方应用应该按照请求类型进行处理，处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
 @param request 具体的请求对象
 */
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
    
}

/**
 收到一个来自微博客户端程序的响应
 
 收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class])
    {
        //发送结果的回调
    }
    else if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
        //需要进行判断，关于授权成功以及失败的问题 -- 通过statusCode进行判断 -- 如果statusCode<0，则说明授权失败
        NSLog(@"%ld",response.statusCode);
        if (response.statusCode<0)
        {
            //授权失败
        }
        else
        {
            //授权成功
            //认证结果 -- 获取用户的userID、accessToken、expirationDate等信息。同时将这些信息存储起来，在下次分享时进行赋值，这样就可以避免重复授权问题。
            WBAuthorizeResponse* authoResponse = (WBAuthorizeResponse*)response;
            
            //保存accessToken
            [self saveUserInfo:authoResponse];
            
            //授权成功
            [[NSNotificationCenter defaultCenter]postNotificationName:@"authorSuccess" object:nil];
        }
    }
}

-(void)saveUserInfo:(WBAuthorizeResponse *)response
{
    //获取文件路径
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"oauthUser.dic"];
    
    //构建存储字典
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    [paramDic setObject:response.accessToken forKey:@"accessToken"];
    [paramDic setObject:response.expirationDate forKey:@"expirationDate"];
    
    //以写文件的方式存储到Document目录下。
    [paramDic writeToFile:documentsDirectory atomically:YES];
}

@end
