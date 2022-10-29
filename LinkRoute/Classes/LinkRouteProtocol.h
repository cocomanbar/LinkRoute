//
//  LinkRouteProtocol.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define LinkRouteDefaultPriority 100

/**
 *  当前 Module 为非单例时
 *      用完即丢，无状态保持，设计类似BeeHive
 *      支持解绑关系
 *
 *  当前 Module 为单例时, 以下4个方法均需实现
 *      避免将路由设计成单例造成内存的占用
 */

@protocol LinkRouteProtocol <NSObject, UIApplicationDelegate>

@required

/// 是否为常住内存单例，默认 false.
+ (BOOL)singleton;

@optional

/// 请使用该方法构建
+ (instancetype)shared;

/// 启动优先级，越大越优先
+ (NSUInteger)modulePriority;

/// 启动模块
- (void)setupModule;

/// 默认主线程启动初始化，是否需要在异步启动
+ (BOOL)async;

@end

NS_ASSUME_NONNULL_END
