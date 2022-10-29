//
//  LRModule2Protocol.h
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LRModule2Protocol <NSObject>

- (void)say;

- (void)say1:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
