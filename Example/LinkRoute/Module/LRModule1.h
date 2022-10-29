//
//  LRModule1.h
//  LinkRoute_Example
//
//  Created by tanxl on 2022/10/29.
//  Copyright © 2022 cocomanbar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LinkRoute/LinkRouteHeader.h>
#import "LRModule1Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LRModule1 : NSObject
<LRModule1Protocol, LinkRouteProtocol>

@end

NS_ASSUME_NONNULL_END
