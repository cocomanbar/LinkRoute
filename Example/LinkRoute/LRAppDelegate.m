//
//  LRAppDelegate.m
//  LinkRoute
//
//  Created by cocomanbar on 10/27/2022.
//  Copyright (c) 2022 cocomanbar. All rights reserved.
//

#import "LRAppDelegate.h"
#import <LinkRoute/LinkRouteHeader.h>

@implementation LRAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = application.delegate.window;
    if (!window) {
        window = [[UIWindow alloc] init];
        window.frame = [UIScreen mainScreen].bounds;
        application.delegate.window = window;
    }
    
    /**
     *  启动所有单例模块
     */
    [LinkRoute setupAllModules];
    
    /**
     *  同时转发消息到所有模块接收此调用的单例模块
     */
    [LinkRoute checkAllModulesWithSelector:_cmd arguments:@[LRSafe(application), LRSafe(launchOptions)]];
    
    
    // 测试转发block函数
//    [self application:application didReceiveRemoteNotification:@{@"key":@"haha"} fetchCompletionHandler:^(UIBackgroundFetchResult result) {
//        NSLog(@"UIBackgroundFetchResult = %ld", result);
//    }];
    
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [LinkRoute checkAllModulesWithSelector:_cmd arguments:@[LRSafe(application), LRSafe(launchOptions)]];
    
    return YES;
}

// 转发类型
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /**
     *  同时转发消息到所有模块接收此调用的单例模块
     */
    [LinkRoute checkAllModulesWithSelector:_cmd arguments:@[LRSafe(application)]];
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    /**
     *  同时转发消息到所有模块接收此调用的单例模块
     */
    [LinkRoute checkAllModulesWithSelector:_cmd arguments:@[LRSafe(application), LRSafe(userInfo), LinkRouteWrapBlock(completionHandler)]];
    
}

@end
