//
//  LinkRoute.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import "LinkRoute.h"
#import "LinkRouteTester.h"
#import "LinkRouteWrapBlock.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "LinkRoute+Exce.h"

#define LR [LinkRoute shared]
#define ModuleDict [[LinkRoute shared] moduleDict]
#define ModuleInvokeDict [[LinkRoute shared] moduleInvokeDict]

@interface LinkRoute ()

@property (nonatomic, strong) NSMutableDictionary *moduleDict;          // <moduleProtocolName, moduleClass>
@property (nonatomic, strong) NSMutableDictionary *moduleInvokeDict;    // <moduleClassName, moduleInstance>

@end

@interface NSObject (LinkRoute)

- (void)lr_doesNotRecognizeSelector:(SEL)aSelector;

@end

@implementation LinkRoute

#pragma mark - LifeCircle

+ (instancetype)shared{
    static LinkRoute *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LinkRoute alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _moduleDict = [NSMutableDictionary dictionary];
        _moduleInvokeDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public

+ (void)registerService:(Protocol *_Nonnull)serviceProtocol withModule:(Class<LinkRouteProtocol> _Nonnull)moduleClass{
    NSString *protocolStr = NSStringFromProtocol(serviceProtocol);
    NSString *moduleStr = NSStringFromClass(moduleClass);
    NSString *exReason = nil;
    if (protocolStr.length == 0) {
        exReason =  LRString(@"Needs a valid protocol for module %@", moduleStr);
    } else if (moduleStr.length == 0) {
        exReason =  LRString(@"Needs a valid module for protocol %@", protocolStr);
    } else if (![moduleClass conformsToProtocol:serviceProtocol]) {
        exReason =  LRString(@"Module %@ should confirm to protocol %@", moduleStr, protocolStr);
    } else {
        [self hackUnrecognizedSelecotorExceptionForModule:moduleClass];
        [ModuleDict setObject:moduleClass forKey:protocolStr];
        if (LinkRoute.debug && [LinkRoute.aTester respondsToSelector:@selector(shouldStartTest)] && [LinkRoute.aTester shouldStartTest]) {
            if ([LinkRoute.aTester respondsToSelector:@selector(interceptTestService:withModule:)]) {
                [LinkRoute.aTester interceptTestService:serviceProtocol withModule:moduleClass];
            }
        }
    }
    if (exReason.length && LinkRoute.debug)  {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:protocolStr forKey:LRExceptionProtocol];
        [userInfo setObject:NSStringFromClass(moduleClass) forKey:LRExceptionModule];
        [userInfo setObject:exReason forKey:LRExceptionReason];
        NSException *exception = [[NSException alloc] initWithName:LRExceptionName
                                                            reason:exReason
                                                          userInfo:userInfo];
        !LREnble ?: LRLog(exReason);
        @throw exception;
    }
}

+ (_Nullable id)createService:(Protocol *_Nonnull)serviceProtocol {
    NSString *protocolStr = NSStringFromProtocol(serviceProtocol);
    NSString *exReason = nil;
    NSException *exception = nil;
    if (protocolStr.length == 0) {
        exReason = LRString(@"Invalid service protocol");
    } else {
        Class class = ModuleDict[protocolStr];
        NSString *classStr = NSStringFromClass(class);
        if (!class) {
            exReason = LRString(@"Failed to find module by protocol %@", protocolStr);
        } else if (![class conformsToProtocol:@protocol(LinkRouteProtocol)]) {
            exReason = LRString(@"Found %@ by protocol %@, but the module doesn't confirm to protocol LinkRouteProtocol", classStr, protocolStr);
        } else {
            if (moduleSingleton(class)) {
                if (![class respondsToSelector:@selector(shared)]) {
                    exReason = LRString(@"Failed to find 'shared' in Module: %@", classStr);
                }else{
                    id instance = [class shared];
                    return instance;
                }
            }else{
                id instance = [[class alloc] init];
                return instance;
            }
        }
    }
    if (exReason) {
        NSExceptionName name = LRExceptionName;
        NSMutableDictionary *userInfo = nil;
        if (exception != nil) {
            userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
            name = exception.name;
        } else {
            userInfo = [NSMutableDictionary dictionary];
        }
        [userInfo setValue:NSStringFromProtocol(serviceProtocol) forKey:LRExceptionProtocol];
        [userInfo setValue:exReason forKey:LRExceptionReason];
        [userInfo setValue:@(LinkRouteLevelModuleNotFound) forKey:LRExceptionCode];
        NSException *ex = [[NSException alloc] initWithName:name
                                                            reason:exReason
                                                          userInfo:userInfo];
        LinkRouteExceptionHandle handler = [LinkRoute handle];
        !LREnble ?: LRLog(ex.reason);
        if (handler) {
            handler(ex);
        }else{
            if (LinkRoute.debug) {
                @throw ex;
            }
        }
    }
    return nil;
}

+ (void)unregisterService:(Protocol*_Nonnull)serviceProtocol {
    NSString *str = NSStringFromProtocol(serviceProtocol);
    if (str.length) {
        Class moduleClass = [ModuleDict objectForKey:str];
        if (moduleClass && !moduleSingleton(moduleClass)) {
            /// 避免非单例因注册销毁多次，钩子复原
            [self hackUnrecognizedSelecotorExceptionForModule:moduleClass];
            [ModuleDict removeObjectForKey:str];
        } else {
            NSString *error = LRString(@"Failed to unregister service, protocol（%@） is not registed", NSStringFromProtocol(serviceProtocol));
            !LREnble ?: LRLog(error);
        }
    } else {
        NSString *error = LRString(@"Failed to unregister service, protocol（%@） is empty", NSStringFromProtocol(serviceProtocol));
        !LREnble ?: LRLog(error);
    }
}

+ (NSArray<Class<LinkRouteProtocol>> *_Nonnull)allRegisteredModules {
    NSArray *modules = ModuleDict.allValues;
    NSArray *sortedModules = [modules sortedArrayUsingComparator:^NSComparisonResult(Class class1, Class class2) {
        NSUInteger priority1 = LinkRouteDefaultPriority;
        NSUInteger priority2 = LinkRouteDefaultPriority;
        if ([class1 respondsToSelector:@selector(modulePriority)]) {
            priority1 = [class1 modulePriority];
        }
        if ([class2 respondsToSelector:@selector(modulePriority)]) {
            priority2 = [class2 modulePriority];
        }
        if(priority1 == priority2) {
            return NSOrderedSame;
        } else if(priority1 < priority2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    return [sortedModules copy];
}

+ (void)setupAllModules {
    NSArray *modules = [self allRegisteredModules];
    for (Class<LinkRouteProtocol> moduleClass in modules) {
        if (moduleSingleton(moduleClass)) {
        
            if (![moduleClass respondsToSelector:@selector(shared)]) {
                NSAssert(NO, @"Failed to find Method in Module: shared");
                continue;
            }
            
            id module = [moduleClass shared];
        
            if (![module respondsToSelector:@selector(setupModule)]) {
                NSAssert(NO, @"Failed to find Method in Module: setupModule");
                continue;
            }
            
            BOOL async = true;
            if ([moduleClass respondsToSelector:@selector(async)]) {
                async = [moduleClass async];
            }
            
            if (!async) {
                [module setupModule];
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [module setupModule];
                });
            }
        }
    }
}

+ (BOOL)checkAllModulesWithSelector:(nonnull SEL)selector arguments:(nullable NSArray *)arguments {
    
    BOOL result = NO;
    NSArray *modules = [self allRegisteredModules];
    for (Class<LinkRouteProtocol> class in modules) {
        if (!moduleSingleton(class)) {
            continue;
        }
        if (![class respondsToSelector:@selector(shared)]) {
            continue;
        }
        id<LinkRouteProtocol> moduleItem = [class shared];
        if (![moduleItem respondsToSelector:selector]) {
            continue;
        }
        __block BOOL shouldInvoke = YES;
        if (![ModuleInvokeDict objectForKey:NSStringFromClass([moduleItem class])]) {
            // 如果 modules 里面有 moduleItem 的子类，不 invoke target
            [modules enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([NSStringFromClass([obj superclass]) isEqualToString:NSStringFromClass([moduleItem class])]) {
                    shouldInvoke = NO;
                    *stop = YES;
                }
            }];
        }
        if (shouldInvoke) {
            if (![ModuleInvokeDict objectForKey:NSStringFromClass([moduleItem class])]) { //cache it
                [ModuleInvokeDict setObject:moduleItem forKey:NSStringFromClass([moduleItem class])];
            }
            BOOL ret = NO;
            [self invokeTarget:moduleItem action:selector arguments:arguments returnValue:&ret];
            if (!result) {
                result = ret;
            }
        }
    }
    return result;
}

+ (BOOL)invokeTarget:(id)target action:(SEL)selector arguments:(NSArray *)arguments returnValue:(void *)result {
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = target;
    invocation.selector = selector;
    if (arguments.count && invocation.methodSignature.numberOfArguments - 2 != arguments.count) {
        return false;
    }
    
    for (NSInteger idx = 0; idx < arguments.count; idx++) {
        id paramater = [arguments objectAtIndex:idx];
        NSUInteger argIndex = idx + 2;
        char *argumentType = (char *)[sig getArgumentTypeAtIndex:argIndex];
        // 针对 `NSNumber` 的转发，即入参时请将基本数据转为`NSNumber`对象
        if ([paramater isKindOfClass: NSNumber.class]) {
            NSNumber *paramaterNumberObj = (NSNumber *)paramater;
            if (!strcmp(argumentType, @encode(char))) {
                char value = paramaterNumberObj.charValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(unsigned char))) {
                unsigned char value = paramaterNumberObj.unsignedCharValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(short))) {
                short value = paramaterNumberObj.shortValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(unsigned short))) {
                unsigned short value = paramaterNumberObj.unsignedShortValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(int))) {
                int value = paramaterNumberObj.intValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(unsigned int))) {
                unsigned int value = paramaterNumberObj.unsignedIntValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(long))) {
                long value = paramaterNumberObj.longValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(unsigned long))) {
                unsigned long value = paramaterNumberObj.unsignedLongValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(long long))) {
                long long value = paramaterNumberObj.longLongValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(unsigned long long))) {
                unsigned long long value = paramaterNumberObj.unsignedLongLongValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(float))) {
                float value = paramaterNumberObj.floatValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(double))) {
                double value = paramaterNumberObj.doubleValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(BOOL))) {
                BOOL value = paramaterNumberObj.boolValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(NSInteger))) {
                NSInteger value = paramaterNumberObj.integerValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (!strcmp(argumentType, @encode(NSUInteger))) {
                NSUInteger value = paramaterNumberObj.unsignedIntegerValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else{
                NSAssert(false, ([NSString stringWithFormat:@"[%@ %@]：unknown type at index %ld, please adapt and forward", NSStringFromClass([target class]), NSStringFromSelector(selector), idx]));
                int value = paramaterNumberObj.intValue;
                [invocation setArgument:&value atIndex:argIndex];
            }
        }
        // 针对 `NSValue` 的转发，即入参时请将结构体数据转为`NSValue`对象
        else if ([paramater isKindOfClass: NSValue.class]) {
            NSValue *paramaterValueObj = (NSValue *)paramater;
            if (strcmp(argumentType, @encode(CGPoint)) == 0) {
                CGPoint value = paramaterValueObj.CGPointValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(CGSize)) == 0) {
                CGSize value = paramaterValueObj.CGSizeValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(CGRect)) == 0) {
                CGRect value = paramaterValueObj.CGRectValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(CGVector)) == 0) {
                CGVector value = paramaterValueObj.CGVectorValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(CGAffineTransform)) == 0) {
                CGAffineTransform value = paramaterValueObj.CGAffineTransformValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(CATransform3D)) == 0) {
                CATransform3D value = paramaterValueObj.CATransform3DValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(NSRange)) == 0) {
                NSRange value = paramaterValueObj.rangeValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(UIOffset)) == 0) {
                UIOffset value = paramaterValueObj.UIOffsetValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else if (strcmp(argumentType, @encode(UIEdgeInsets)) == 0) {
                UIEdgeInsets value = paramaterValueObj.UIEdgeInsetsValue;
                [invocation setArgument:&value atIndex:argIndex];
            } else {
                NSAssert(false, ([NSString stringWithFormat:@"[%@ %@]：unknown type at index %ld, please adapt and forward", NSStringFromClass([target class]), NSStringFromSelector(selector), idx]));
                [invocation setArgument:&paramaterValueObj atIndex:argIndex];
            }
        }
        // 统一转发`NSObject`对象
        else if ([paramater isKindOfClass: NSObject.class]) {
            // 针对 `nil` 的转发，即入参时通过 `LRSafe(x)` 包装，解包为nil
            if ([paramater isKindOfClass: NSNull.class]) {
                id value = nil;
                [invocation setArgument:&value atIndex:argIndex];
            }
            // 针对 `block`的转发，即入参时通过 `LinkRouteWrapBlock(x)` 包装，需要解包出来
            else if ([paramater isKindOfClass:LinkRouteWrapBlock.class]) {
                LinkRouteWrapBlock *wrapBlock = (LinkRouteWrapBlock *)paramater;
                void *p = wrapBlock.aBlock;
                [invocation setArgument:&p atIndex:argIndex];
            }
            // 普适转发
            else {
                [invocation setArgument:&paramater atIndex:argIndex];
            }
        }
        // 警告其他未知类型
        else {
            NSAssert(false, ([NSString stringWithFormat:@"[%@ %@]：unknown type at index %ld, please adapt and forward", NSStringFromClass([target class]), NSStringFromSelector(selector), idx]));
            [invocation setArgument:&paramater atIndex:argIndex];
        }
    }
    
    // invoke
    [invocation invoke];
    
    // 判断是否有返回值
    NSString *methodReturnType = [NSString stringWithUTF8String:sig.methodReturnType];
    if (result && ![methodReturnType isEqualToString:@"v"]) {
        if ([methodReturnType isEqualToString:@"@"]) { //if it's kind of NSObject
            CFTypeRef cfResult = nil;
            [invocation getReturnValue:&cfResult]; //this operation won't retain the result
            if (cfResult) {
                CFRetain(cfResult); //we need to retain it manually
                *(void**)result = (__bridge_retained void *)((__bridge_transfer id)cfResult);
            }
        } else {
            [invocation getReturnValue:result];
        }
    }
    return false;
}

#pragma mark - FOUNDATION_STATIC_INLINE

/// 是否是单例模块
FOUNDATION_STATIC_INLINE BOOL moduleSingleton(Class class){
    BOOL singleton = NO;
    if ([class respondsToSelector:@selector(singleton)]) {
        singleton = [class singleton];
    }
    return singleton;
}

#pragma mark - 交换实现

+ (void)hackUnrecognizedSelecotorExceptionForModule:(Class)class {
    SEL originSEL = @selector(doesNotRecognizeSelector:);
    SEL newSEL = @selector(lr_doesNotRecognizeSelector:);
    [self swizzleOrginSEL:originSEL withNewSEL:newSEL inClass:class];
}

+ (void)swizzleOrginSEL:(SEL)originSEL withNewSEL:(SEL)newSEL inClass:(Class)class {
    Method origMethod = class_getInstanceMethod(class, originSEL);
    Method overrideMethod = class_getInstanceMethod(class, newSEL);
    if (!origMethod || !overrideMethod) {
        return;
    }
    if (class_addMethod(class, originSEL, method_getImplementation(overrideMethod),
                        method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(class, newSEL, method_getImplementation(origMethod),
                            method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

#pragma mark - 组件异常检查

static BOOL LREnble = NO;

+ (void)setEnbleLog:(BOOL)enble {
    LREnble = enble;
}

+ (BOOL)enbleLog {
    return LREnble;
}


static id<LinkRouteTestProtocol> _aTester;

+ (void)registerTester:(id<LinkRouteTestProtocol>)aTester {
    _aTester = aTester;
}

+ (id <LinkRouteTestProtocol> _Nullable)aTester {
    if (_aTester) {
        return _aTester;
    }
    return [LinkRouteTester shared];
}

+ (BOOL)debug {
    BOOL ret = false;
#ifdef DEBUG
    ret = true;
#endif
    return ret;
}

@end

@implementation NSObject (LinkRoute)

- (void)lr_doesNotRecognizeSelector:(SEL)aSelector {
    @try {
        [self lr_doesNotRecognizeSelector:aSelector];
    } @catch (NSException *ex) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:ex.reason ?: @"" forKey:LRExceptionReason];
        [userInfo setValue:NSStringFromClass(self.class) forKey:LRExceptionModule];
        [userInfo setValue:@(LinkRouteLevelApiNotFound) forKey:LRExceptionCode];
        NSException *exception = [[NSException alloc] initWithName:LRExceptionName
                                                            reason:ex.reason
                                                          userInfo:userInfo];
        LinkRouteExceptionHandle handler = [LinkRoute handle];
        if (handler) {
            handler(exception);
        }else{
            if (LinkRoute.debug) {
                @throw exception;
            }
        }
    }
}

@end
