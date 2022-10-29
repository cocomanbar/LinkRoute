//
//  LRModule3.m
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import "LRModule3.h"

LinkRouteService(LRModule3, LRModule3Protocol)

@implementation LRModule3

#pragma mark - Module Must Imp

+ (BOOL)singleton{
    return YES;
}

+ (instancetype)shared{
    static LRModule3 *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LRModule3 alloc] init];
    });
    return _instance;
}

+ (BOOL)async{
    return YES;
}

- (NSInteger)modulePriority{
    return LinkRouteDefaultPriority+101;
}

- (void)setupModule{
    NSLog(@"启动了模块 - %@  在线程 - %@", NSStringFromClass(self.class), NSThread.currentThread.debugDescription);
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    NSLog(@"模块3 执行了 %@", NSStringFromSelector(_cmd));
}

#pragma mark - Support Public

@end
