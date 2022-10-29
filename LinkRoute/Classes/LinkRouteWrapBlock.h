//
//  LinkRouteWrapBlock.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 返回一个包裹着block的objc对象，用于消息转发 或组件间传递
#define LinkRouteWrapBlock(block)   \
[LinkRouteWrapBlock wrapBlock:((__bridge void *)(block))]   \

@interface LinkRouteWrapBlock : NSObject

@property (nonatomic, nullable) void *aBlock;

+ (instancetype)wrapBlock:(void *)aBlock;

@end

NS_ASSUME_NONNULL_END
