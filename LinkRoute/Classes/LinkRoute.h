//
//  LinkRoute.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <Foundation/Foundation.h>
#import "LinkRouteProtocol.h"
#import "LinkRouteTestProtocol.h"

#define LRSafe(obj) obj ?: [NSNull null]

NS_ASSUME_NONNULL_BEGIN

@interface LinkRoute : NSObject

/// 注册关联 Protocol-Module
+ (void)registerService:(Protocol *_Nonnull)serviceProtocol withModule:(Class<LinkRouteProtocol> _Nonnull)moduleClass;

/// 获取与Protocol关联的Module
+ (_Nullable id)createService:(Protocol *_Nonnull)serviceProtocol;

/// 解绑关联，只针对非单例对象
+ (void)unregisterService:(Protocol*_Nonnull)serviceProtocol;

/// 返回当前注册的Module
+ (NSArray<Class<LinkRouteProtocol>> *_Nonnull)allRegisteredModules;

/// 初始化单例Module，该方法执行在 `application:didFinishLaunchingWithOptions:` 或应用较早启动的时机
+ (void)setupAllModules;

/// 执行AppDelegate系统级别方法的消息转发,每个Module可选择实现对应的监听方法处理数据
+ (BOOL)checkAllModulesWithSelector:(nonnull SEL)selector arguments:(nullable NSArray *)arguments;

#pragma mark - Debug

/// 组件异常打印
+ (void)setEnbleLog:(BOOL)enble;
+ (BOOL)enbleLog;

/// 组件异常检测
+ (void)registerTester:(id<LinkRouteTestProtocol>)aTester;
+ (id <LinkRouteTestProtocol> _Nullable)aTester;

@end

NS_ASSUME_NONNULL_END
