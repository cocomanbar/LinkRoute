//
//  LRModule1Protocol.h
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LRModule1Protocol <NSObject>

/// Description
/// @param name name description
- (void)sayHello:(NSString *)name;

/// Description
/// @param name name description
/// @param aTime aTime description
- (void)sayHello:(NSString *)name toTime:(NSString *)aTime;

@end

NS_ASSUME_NONNULL_END
