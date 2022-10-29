//
//  LinkRouteWrapBlock.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/29.
//

#import "LinkRouteWrapBlock.h"

@implementation LinkRouteWrapBlock

+ (instancetype)wrapBlock:(void *)aBlock {
    LinkRouteWrapBlock *wrapBlock = [[LinkRouteWrapBlock alloc] init];
    wrapBlock.aBlock = aBlock;
    return wrapBlock;
}

@end
