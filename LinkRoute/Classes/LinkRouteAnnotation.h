//
//  LinkRouteAnnotation.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// SectName 0~16 length
#ifndef LinkRouteSectName
#define LinkRouteSectName "LinkRouteSects"
#endif

#define LinkRouteDATA(sectname) __attribute((used, section("__DATA,"#sectname" ")))

#define LinkRouteService(impl,servicename) \
char * k##servicename##_service LinkRouteDATA(LinkRouteSects) = "{ \""#impl"\" : \""#servicename"\"}";

NS_ASSUME_NONNULL_END

@interface LinkRouteAnnotation : NSObject

@end
