//
//  LinkRoute+Binding.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <LinkRoute/LinkRoute.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const lr_route_url;
extern NSString *const lr_route_completion;
extern NSString *const lr_route_userInfo;

/**
 *  routerParameters 里内置的几个参数会用到上面定义的 string
 */
typedef void (^LinkRouteHandler)(NSDictionary * _Nullable routerParameters);

/**
 *  需要返回一个 object，配合 objectForURL: 使用
 */
typedef id _Nullable (^LinkRouteObjectHandler)(NSDictionary * _Nullable routerParameters);

@interface LinkRoute (Binding)

/// 注册 URL 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作，比如push/modal
/// @param urlStr 带上 scheme，如 mmp://beauty/:id
/// @param handler 该 block 会传一个字典，包含了注册的 URL 中对应的变量。假如注册的 URL 为 mmp://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
+ (void)bindURL:(NSString * _Nonnull)urlStr toHandler:(nonnull LinkRouteHandler)handler;

/// 注册 URL 对应的 ObjectHandler，需要返回一个 object 给调用方
/// @param urlStr 带上 scheme，如 mmp://beauty/:id
/// @param handler 该 block 会传一个字典，包含了注册的 URL 中对应的变量。假如注册的 URL 为 mmp://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来，自带的 key 为 @"url" 和 @"completion" (如果有的话)
+ (void)bindURL:(NSString * _Nonnull)urlStr toObjectHandler:(nonnull LinkRouteObjectHandler)handler;

/// 取消注册某个 URL
/// @param urlStr urlStr description
+ (void)unbindURL:(NSString * _Nullable)urlStr;

/// 打开此 URL，会在已注册的 URL -> Handler 中寻找，如果找到，则执行 Handler
/// @param urlStr urlStr description
+ (void)openURL:(NSString * _Nullable)urlStr;

/// 打开此 URL，同时当操作完成时，执行额外的代码
/// @param urlStr 带 Scheme 的 URL，如 mmp://beauty/4
/// @param completion 处理完成后的 callback，完成的判定跟具体的业务相关
+ (void)openURL:(NSString * _Nullable)urlStr completion:(nullable void (^)(id result))completion;

/// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
/// @param urlStr 带 Scheme 的 URL，如 mmp://beauty/4
/// @param userInfo 附加参数
/// @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
+ (void)openURL:(NSString * _Nullable)urlStr withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable void (^)(id result))completion;

/// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
/// @param urlStr 带 Scheme 的 URL，如 mmp://beauty/4
/// @param exactly url是否全匹配，非全匹配默认有Feedback功能，请注意使用
/// @param userInfo 附加参数
/// @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
+ (void)openURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable void (^)(id result))completion;

/// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
/// @param urlStr 带 Scheme，如 mmp://beauty/3
+ (id)objectForURL:(NSString * _Nullable)urlStr;

/// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
/// @param urlStr 带 Scheme，如 mmp://beauty/3
/// @param userInfo 附加参数
+ (id)objectForURL:(NSString * _Nullable)urlStr withUserInfo:(NSDictionary * _Nullable)userInfo;

/// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
/// @param urlStr 带 Scheme，如 mmp://beauty/3
/// @param exactly url是否全匹配，非全匹配默认有Feedback功能，请注意使用
/// @param userInfo 附加参数
+ (id)objectForURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly withUserInfo:(NSDictionary * _Nullable)userInfo;

/// 是否可以打开URL
/// @param urlStr 带 Scheme，如 mmp://beauty/3
+ (BOOL)canOpenURL:(NSString * _Nullable)urlStr;
+ (BOOL)canOpenURL:(NSString * _Nullable)urlStr matchExactly:(BOOL)exactly;

/// 调用此方法来拼接 urlpattern 和 parameters
/// #define MMP_ROUTE_BEAUTY @"beauty/:id"
/// [LinkRoute generateURLWithPattern:MMP_ROUTE_BEAUTY, @[@13]];
///
/// @param pattern url pattern 比如 @"beauty/:id"
/// @param parameters 一个数组，数量要跟 pattern 里的变量一致
+ (nullable NSString *)generateURLWithPattern:(NSString * _Nullable)pattern parameters:(NSArray * _Nullable)parameters;

/// 打印缓存内的路由表
+ (void)debugAllRouters;

@end

NS_ASSUME_NONNULL_END
