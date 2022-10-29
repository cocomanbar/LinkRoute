//
//  LinkRoute+Exce.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import "LinkRoute+Exce.h"

// Exception
NSExceptionName LRExceptionName = @"LRExceptionName";

// Exception userInfo keys
NSString *const LRExceptionCode = @"code";
NSString *const LRExceptionReason = @"reason";

NSString *const LRExceptionURL = @"url";
NSString *const LRExceptionModule = @"module";
NSString *const LRExceptionProtocol = @"protocol";

static LinkRouteExceptionHandle _lr_handler = nil;

@implementation LinkRoute (Exce)

+ (void)setExceptionHandler:(LinkRouteExceptionHandle _Nullable )aHandler{
    _lr_handler = aHandler;
}

+ (LinkRouteExceptionHandle _Nullable )handle{
    return _lr_handler;
}

@end

@implementation NSException (LinkRoute)

- (LinkRouteLevel)lr_exceptionLevel {
    return [self.userInfo[LRExceptionCode] integerValue];
}

@end
