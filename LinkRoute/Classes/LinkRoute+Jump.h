//
//  LinkRoute+Jump.h
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import <LinkRoute/LinkRoute.h>

NS_ASSUME_NONNULL_BEGIN

@interface LinkRoute (Jump)

+ (UIViewController *)currentViewController;

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (void)presentViewController:(UIViewController *)viewController animated: (BOOL)animated completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
