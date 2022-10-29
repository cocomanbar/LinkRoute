//
//  LinkRoute+Exce.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <LinkRoute/LinkRoute.h>

NS_ASSUME_NONNULL_BEGIN

#define LRLog(msg) NSLog(@"[LinkRoute<麟鹿>]：%@", (msg))
#define LRString(fmt, ...) [NSString stringWithFormat:fmt, ##__VA_ARGS__]

typedef NS_ENUM(NSInteger, LinkRouteLevel){
    LinkRouteLevelUnknow = 1000,
    LinkRouteLevelModuleNotFound,
    LinkRouteLevelApiNotFound,
    LinkRouteLevelUrlInvalid,
    LinkRouteLevelUrlHandleNotFound,
};

// Exception
extern NSExceptionName _Nonnull LRExceptionName;

// Exception userInfo keys
extern NSString *const _Nonnull LRExceptionCode;
extern NSString *const _Nonnull LRExceptionReason;

extern NSString *const _Nonnull LRExceptionURL;
extern NSString *const _Nonnull LRExceptionModule;
extern NSString *const _Nonnull LRExceptionProtocol;

typedef void(^LinkRouteExceptionHandle)(NSException * _Nullable exception);

// 异常处理
@interface LinkRoute (Exce)

+ (void)setExceptionHandler:(LinkRouteExceptionHandle _Nullable )aHandler;

+ (LinkRouteExceptionHandle _Nullable )handle;

@end

@interface NSException (LinkRoute)

- (LinkRouteLevel)lr_exceptionLevel;

@end

NS_ASSUME_NONNULL_END
