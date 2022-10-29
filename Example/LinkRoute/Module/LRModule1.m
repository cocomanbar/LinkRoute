//
//  LRModule1.m
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import "LRModule1.h"

LinkRouteService(LRModule1, LRModule1Protocol)

@implementation LRModule1

#pragma mark - Module Must Imp

+ (BOOL)singleton{
    return YES;
}

+ (instancetype)shared{
    static LRModule1 *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LRModule1 alloc] init];
    });
    return _instance;
}

+ (BOOL)async{
    return NO;
}

- (NSInteger)modulePriority{
    return LinkRouteDefaultPriority+100;
}

- (void)setupModule{
    NSLog(@"启动了模块 - %@  在线程 - %@", NSStringFromClass(self.class), NSThread.currentThread.debugDescription);
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    NSLog(@"模块1 执行了 %@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    NSLog(@"模块1 执行了 %@", NSStringFromSelector(_cmd));
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultFailed);
    }
}


#pragma mark - Support Public

// 实现IMP
- (void)sayHello:(NSString *)name {
    NSLog(@"%@ say helo to %@", NSStringFromClass(self.class), name);
}

// 检测未实现
//- (void)sayHello:(NSString *)name toTime:(NSString *)aTime {}

@end
