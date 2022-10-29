//
//  LinkRoute+Binding.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import "LinkRoute+Binding.h"
#import "LinkRoute+Exce.h"

static NSString *lr_special_characters = @"/?&.";
static NSString * const lr_route_wildcard_charactet = @"~";

NSString *const lr_route_url = @"lr_route_url";
NSString *const lr_route_completion = @"lr_route_completion";
NSString *const lr_route_userInfo = @"lr_route_userInfo";

@implementation LinkRoute (Binding)

/**
 *  保存了所有已注册的 URL
 *  结构类似 @{@"beauty": @{@":id": {@"_", [block copy]}}}
*/
+ (NSMutableDictionary*)routes {
    @synchronized (self) {
        static NSMutableDictionary *_routes;
        if (!_routes) {
            _routes = [NSMutableDictionary dictionary];
        }
        return _routes;
    }
}

+ (void)bindURL:(NSString * _Nonnull)urlStr toHandler:(LinkRouteHandler)handler {
    NSAssert(urlStr, @"Bind an invalid url");
    NSMutableDictionary *subRoutes = lookForURLStr(urlStr);
    if (handler && subRoutes) {
        subRoutes[@"_"] = [handler copy];
    }
}

+ (void)bindURL:(NSString * _Nonnull)urlStr toObjectHandler:(LinkRouteObjectHandler)handler{
    NSAssert(urlStr, @"Bind an invalid url");
    NSMutableDictionary *subRoutes = lookForURLStr(urlStr);
    if (handler && subRoutes) {
        subRoutes[@"_"] = [handler copy];
    }
}

+ (void)unbindURL:(NSString * _Nullable)urlStr{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:pathComponentsFromURL(urlStr)];
    if (!pathComponents || !pathComponents.count) {
        return;
    }
    // 只删除该 urlStr 的最后一级
    // 假如 urlStr 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
    NSString *components = [pathComponents componentsJoinedByString:@"."];
    NSMutableDictionary *route = [self.routes valueForKeyPath:components];
    if (route.count >= 1) {
        NSString *lastComponent = [pathComponents lastObject];
        [pathComponents removeLastObject];
        
        // 有可能是根 key，这样就是 self.routes 了
        route = self.routes;
        if (pathComponents.count) {
            NSString *componentsWithoutLast = [pathComponents componentsJoinedByString:@"."];
            route = [self.routes valueForKeyPath:componentsWithoutLast];
        }
        [route removeObjectForKey:lastComponent];
    }
}

+ (void)openURL:(NSString * _Nullable)urlStr{
    [self openURL:urlStr completion: nil];
}

+ (void)openURL:(NSString * _Nullable)urlStr completion:(nullable void (^)(id result))completion{
    [self openURL:urlStr withUserInfo:nil completion:completion];
}

+ (void)openURL:(NSString * _Nullable)urlStr withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable void (^)(id result))completion{
    [self openURL:urlStr matchExactly:true withUserInfo:userInfo completion:completion];
}

+ (void)openURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable void (^)(id result))completion {
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = extractParametersFromURL(urlStr, exactly);
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }];
    
    NSString *reasion = nil;
    LinkRouteLevel errorLevel = LinkRouteLevelUnknow;
    if (parameters && parameters.count) {
        LinkRouteHandler handler = parameters[@"block"];
        if (completion) {
            parameters[lr_route_completion] = completion;
        }
        if (userInfo) {
            parameters[lr_route_userInfo] = userInfo;
        }
        if (handler) {
            [parameters removeObjectForKey:@"block"];
            handler(parameters);
            return;
        }
        reasion = @"not found router handler";
        errorLevel = LinkRouteLevelUrlHandleNotFound;
    } else {
        reasion = @"invalid url";
        errorLevel = LinkRouteLevelUrlInvalid;
    }
    
    !LinkRoute.enbleLog ?: LRLog(reasion);
    NSMutableDictionary *exceptionInfo = [NSMutableDictionary dictionary];
    [exceptionInfo setObject:@(errorLevel) forKey:LRExceptionCode];
    [exceptionInfo setObject:urlStr?:@"" forKey:LRExceptionURL];
    [exceptionInfo setObject:reasion forKey:LRExceptionReason];
    NSException *exception = [[NSException alloc] initWithName:LRExceptionName
                                                        reason:reasion
                                                      userInfo:exceptionInfo];
    LinkRouteExceptionHandle exceptionHandler = [LinkRoute handle];
    if (exceptionHandler) {
        exceptionHandler(exception);
    }
}

+ (BOOL)canOpenURL:(NSString * _Nullable)urlStr{
    return [self canOpenURL:urlStr matchExactly:true];
}

+ (BOOL)canOpenURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly {
    if (!urlStr || !urlStr.length) {
        return NO;
    }
    if (extractParametersFromURL(urlStr, exactly) && [extractParametersFromURL(urlStr, exactly) objectForKey:@"block"]) {
        return YES;
    }
    return NO;
}

+ (id)objectForURL:(NSString * _Nullable)urlStr{
    return [self objectForURL:urlStr withUserInfo:nil];
}

+ (id)objectForURL:(NSString * _Nullable)urlStr withUserInfo:(NSDictionary * _Nullable)userInfo{
    return [self objectForURL:urlStr matchExactly:true withUserInfo:userInfo];
}

+ (id)objectForURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly withUserInfo:(NSDictionary * _Nullable)userInfo {
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = extractParametersFromURL(urlStr, exactly);
    
    NSString *reasion;
    LinkRouteLevel errorLevel = LinkRouteLevelUnknow;
    if (parameters && parameters.count) {
        LinkRouteObjectHandler handler = parameters[@"block"];
        if (handler) {
            if (userInfo) {
                parameters[lr_route_userInfo] = userInfo;
            }
            [parameters removeObjectForKey:@"block"];
            return handler(parameters);
        }
        reasion = @"not found router object handler";
        errorLevel = LinkRouteLevelUrlHandleNotFound;
    } else {
        reasion = @"invalid url";
        errorLevel = LinkRouteLevelUrlInvalid;
    }
    !LinkRoute.enbleLog ?: LRLog(reasion);
    NSMutableDictionary *exceptionInfo = [NSMutableDictionary dictionary];
    [exceptionInfo setObject:@(errorLevel) forKey:LRExceptionCode];
    [exceptionInfo setObject:reasion forKey:LRExceptionReason];
    [exceptionInfo setObject:urlStr?:@"" forKey:LRExceptionURL];
    NSException *exception = [[NSException alloc] initWithName:LRExceptionName
                                                        reason:reasion
                                                      userInfo:exceptionInfo];
    LinkRouteExceptionHandle exceptionHandler = [LinkRoute handle];
    if (exceptionHandler) {
        exceptionHandler(exception);
    }
    return nil;
}

#pragma mark - Static Function

FOUNDATION_STATIC_INLINE NSMutableDictionary *lookForURLStr(NSString *urlStr){
    NSArray *pathComponents = pathComponentsFromURL(urlStr);
    NSMutableDictionary *subRoutes = LinkRoute.routes;
    
    for (NSString* pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    // bind时会检查url - path
    if (subRoutes.count) {
        NSCAssert(NO, @"url path already has existed, parameters maybe different");
    }
    
#ifdef DEBUG
    if ([LinkRoute.aTester respondsToSelector:@selector(shouldStartTest)] && [LinkRoute.aTester shouldStartTest]) {
        if ([LinkRoute.aTester respondsToSelector:@selector(interceptTestRouter:)]) {
            [LinkRoute.aTester interceptTestRouter:urlStr];
        }
    }
#endif
    return subRoutes;
}

FOUNDATION_STATIC_INLINE NSMutableDictionary *extractParametersFromURL(NSString *urlStr, BOOL matchExactly){
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (!urlStr || !urlStr.length) {
        return parameters;
    }
    
    parameters[lr_route_url] = urlStr;
    NSMutableDictionary* subRoutes = LinkRoute.routes;
    NSArray* pathComponents = pathComponentsFromURL(urlStr);
    
    BOOL found = NO;
    // borrowed from HHRouter(https://github.com/Huohua/HHRouter)
    for (NSString* pathComponent in pathComponents) {
        
        // 对 key 进行排序，这样可以把 ~ 放到最后
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }];
        
        for (NSString* key in subRoutesKeys) {
            if ([key isEqualToString:pathComponent] || [key isEqualToString:lr_route_wildcard_charactet]) {
                found = YES;
                subRoutes = subRoutes[key];
                break;
            } else if ([key hasPrefix:@":"]) {
                found = YES;
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                // 再做一下特殊处理，比如 :id.html -> :id
                if (checkIfContainsSpecialCharacter(key)) {
                    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:lr_special_characters];
                    NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                    if (range.location != NSNotFound) {
                        // 把 pathComponent 后面的部分也去掉
                        newKey = [newKey substringToIndex:range.location - 1];
                        NSString *suffixToStrip = [key substringFromIndex:range.location];
                        newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suffixToStrip withString:@""];
                    }
                }
                parameters[newKey] = newPathComponent;
                break;
            } else if (matchExactly) {
                found = NO;
            }
        }
    }
    
    // 如果没有找到该 pathComponent 并且是全匹配时，就返回
    if (!found && matchExactly) {
        return nil;
    }
    
    // 如果没有找到该 pathComponent 对应的 handler
    if (!found && !subRoutes[@"_"]) {
        return nil;
    }
    
    // Extract Params From Query.
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:urlStr] resolvingAgainstBaseURL:false].queryItems;
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    // handler
    if (subRoutes[@"_"]) {
        parameters[@"block"] = [subRoutes[@"_"] copy];
    }
    return parameters;
}

FOUNDATION_STATIC_INLINE NSArray *pathComponentsFromURL(NSString *urlStr){
    NSMutableArray *pathComponents = [NSMutableArray array];
    if (!urlStr || !urlStr.length) {
        return [pathComponents copy];
    }
    if (urlStr.length && [urlStr rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [urlStr componentsSeparatedByString:@"://"];
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        [pathComponents addObject:pathSegments[0]];
        // 如果只有协议，那么放一个占位符
        urlStr = pathSegments.lastObject;
        if (!urlStr.length) {
            [pathComponents addObject:lr_route_wildcard_charactet];
        }
    }
    for (NSString *pathComponent in [[NSURL URLWithString:urlStr] pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

FOUNDATION_STATIC_INLINE BOOL checkIfContainsSpecialCharacter(NSString *checkedString){
    NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:lr_special_characters];
    return [checkedString rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound;
}

#pragma mark - Utils

+ (nullable NSString *)generateURLWithPattern:(NSString * _Nullable)pattern parameters:(NSArray * _Nullable)parameters {
    NSInteger startIndexOfColon = 0;
    NSMutableArray *placeholders = [NSMutableArray array];
    
    for (int i = 0; i < pattern.length; i++) {
        NSString *character = [NSString stringWithFormat:@"%c", [pattern characterAtIndex:i]];
        if ([character isEqualToString:@":"]) {
            startIndexOfColon = i;
        }
        if ([lr_special_characters rangeOfString:character].location != NSNotFound && i > (startIndexOfColon + 1) && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon);
            NSString *placeholder = [pattern substringWithRange:range];
            if (!checkIfContainsSpecialCharacter(placeholder)) {
                [placeholders addObject:placeholder];
                startIndexOfColon = 0;
            }
        }
        if (i == pattern.length - 1 && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon + 1);
            NSString *placeholder = [pattern substringWithRange:range];
            if (!checkIfContainsSpecialCharacter(placeholder)) {
                [placeholders addObject:placeholder];
            }
        }
    }
    
    __block NSString *parsedResult = pattern;
    [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        idx = parameters.count > idx ? idx : parameters.count - 1;
        parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:parameters[idx]];
    }];
    
    return parsedResult;
}

+ (void)debugAllRouters{
#ifdef DEBUG
    NSDictionary *router = [self.routes copy];
    LRLog(([NSString stringWithFormat:@":\n%@", router]));
#endif
}

@end
