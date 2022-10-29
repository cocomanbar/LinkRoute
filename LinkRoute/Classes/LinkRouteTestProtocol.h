//
//  LinkRouteTestProtocol.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LinkRouteProtocol;

@protocol LinkRouteTestProtocol <NSObject>

@required

/// 单例对象
+ (instancetype)shared;

/// 是否开始捕获信息
- (BOOL)shouldStartTest;

@optional

/// 捕获信息
- (void)interceptTestRouter:(NSString * _Nullable)url;
- (void)interceptTestService:(Protocol * _Nullable)serviceProtocol withModule:(Class<LinkRouteProtocol> _Nullable)moduleClass;

/// 开始健康测试
+ (void)startTest;

@end

NS_ASSUME_NONNULL_END


