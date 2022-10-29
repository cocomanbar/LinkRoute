#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "LinkRoute+Binding.h"
#import "LinkRoute+Exce.h"
#import "LinkRoute+Jump.h"
#import "LinkRoute.h"
#import "LinkRouteAnnotation.h"
#import "LinkRouteHeader.h"
#import "LinkRouteIntercepterProtocol.h"
#import "LinkRouteProtocol.h"

FOUNDATION_EXPORT double LinkRouteVersionNumber;
FOUNDATION_EXPORT const unsigned char LinkRouteVersionString[];

