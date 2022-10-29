//
//  LinkRoute+Jump.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import "LinkRoute+Jump.h"

@implementation LinkRoute (Jump)

+ (UIViewController *)currentViewController{
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (viewController) {
        if ([viewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController*)viewController;
            viewController = tab.selectedViewController;
        } else if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nvc = (UINavigationController*)viewController;
            viewController = nvc.topViewController;
        } else if (viewController.presentedViewController) {
            viewController = viewController.presentedViewController;
        } else if ([viewController isKindOfClass:[UISplitViewController class]] &&
                   ((UISplitViewController *)viewController).viewControllers.count > 0) {
            UISplitViewController *svc = (UISplitViewController *)viewController;
            viewController = svc.viewControllers.lastObject;
        } else  {
            return viewController;
        }
    }
    return viewController;
}

+ (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated{
    UIViewController *currentViewController = [self currentViewController];
    [currentViewController.navigationController pushViewController:viewController animated:animated];
}

+ (void)presentViewController:(UIViewController *)viewController
                     animated: (BOOL)animated
                   completion:(void (^)(void))completion{
    UIViewController *currentViewController = [self currentViewController];
    [currentViewController presentViewController:viewController animated:animated completion:completion];
}


@end
