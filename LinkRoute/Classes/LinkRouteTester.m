//
//  LinkRouteTester.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/28.
//

#import "LinkRouteTester.h"
#import "LinkRoute+Binding.h"
#import <objc/runtime.h>

@interface LinkRouteTester ()

@property (nonatomic, strong) NSMutableArray *routers;
@property (nonatomic, strong) NSMutableDictionary *moduleDict;

@end

@implementation LinkRouteTester

/// 单例对象
+ (instancetype)shared{
    static LinkRouteTester *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LinkRouteTester alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _routers = [NSMutableArray array];
        _moduleDict = [NSMutableDictionary dictionary];
    }
    return self;
}

/// 是否开始捕获信息
- (BOOL)shouldStartTest {
    return YES;
}

/// 捕获信息
- (void)interceptTestRouter:(NSString * _Nullable)url {
    [LinkRouteTester.shared.routers addObject:url];
}

- (void)interceptTestService:(Protocol * _Nullable)serviceProtocol withModule:(Class<LinkRouteProtocol> _Nullable)moduleClass {
    [LinkRouteTester.shared.moduleDict setValue:moduleClass forKey:NSStringFromProtocol(serviceProtocol)];
}

/// 开始健康测试
+ (void)startTest {
    dispatch_queue_t serialQueue = dispatch_queue_create("com.linkroute.test.cn", DISPATCH_QUEUE_SERIAL);
    
    __block NSMutableArray *routeExceptions = [NSMutableArray array];
    
    /// 路由链接
    NSArray *routes = [LinkRouteTester.shared.routers copy];
    dispatch_sync(serialQueue, ^{
        for (NSString *url in routes) {
            if (![LinkRoute canOpenURL:url]) {
                [routeExceptions addObject:url];
            }
        }
    });
    
    
    __block NSMutableDictionary *moduleExceptions = [NSMutableDictionary dictionary];
    
    /// 模块协议
    NSDictionary *moduleDict = [LinkRouteTester.shared.moduleDict copy];
    dispatch_sync(serialQueue, ^{
        for (NSString *protocolStr in moduleDict.allKeys) {
            Protocol *protocol = NSProtocolFromString(protocolStr);
            NSObject *moduleInstance = [LinkRoute createService:protocol];
            
            //获取方法列表描述
            unsigned int methodCount = 0;
            struct objc_method_description *method_description_list = protocol_copyMethodDescriptionList(protocol, YES, YES, &methodCount);
            for (int i = 0; i < methodCount ; i ++){
                struct objc_method_description description = method_description_list[i];
                SEL selector = NSSelectorFromString(NSStringFromSelector(description.name));
                if (![moduleInstance respondsToSelector:selector]) {
                    NSMutableArray *curArray = [moduleExceptions objectForKey:NSStringFromClass(moduleInstance.class)];
                    if (!curArray) {
                        curArray = [NSMutableArray array];
                        [moduleExceptions setObject:curArray forKey:NSStringFromClass(moduleInstance.class)];
                    }
                    [curArray addObject:NSStringFromSelector(selector)];
                }
            }
            free(method_description_list);
        }
    });
    
    NSLog(@"\n\n🦌LinkRoute🦌麟鹿🦌 \n🙈开始测试🙈\n🔥路由异常情况🔥\n%@\n🔥模块异常情况🔥\n%@\n⛔测试任务完成⛔\n\n", routeExceptions, moduleExceptions);
}

@end
