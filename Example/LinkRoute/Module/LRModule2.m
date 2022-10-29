//
//  LRModule2.m
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import "LRModule2.h"

LinkRouteService(LRModule2, LRModule2Protocol)

@implementation LRModule2

#pragma mark - Module Must Imp

+ (BOOL)singleton{
    return NO;
}

- (void)dealloc {
    NSLog(@"销毁了模块 - %@", NSStringFromClass(self.class));
}

#pragma mark - Support Public

//- (void)say {}

//- (void)say1:(NSString *)name {}

@end
