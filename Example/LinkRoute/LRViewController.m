//
//  LRViewController.m
//  LinkRoute
//
//  Created by cocomanbar on 10/27/2022.
//  Copyright (c) 2022 cocomanbar. All rights reserved.
//

#import "LRViewController.h"
#import <LinkRoute/LinkRouteHeader.h>

#import "LRURLs.h"

#import "LRModule1.h"
#import "LRModule2.h"
#import "LRModule3.h"

// 相同的path晚注册会断言
static NSString *const kShopPage1 = @"mmp://shop/shop_list?key=123&value=abc&option=1";
static NSString *const kShopPage2 = @"mmp://shop/shop_list/shop_list333";

static NSString *const kShopPage3 = @"mmp://shop/shop_list/shop_list111";
static NSString *const kShopPage4 = @"mmp://shop/shop_list/shop_list222";
static NSString *const kShopPage5 = @"mmp://shop/shop_detail?key=123&value=abc&option=1";

static NSString *const kHomePage1 = @"mmp://home/mine_list?key=123&value=abc&option=1";

static NSString *const kNotFoundPage1 = @"mmp://error/detail?key=321&value=abc&option=1";

@interface LRViewController ()

@end

@implementation LRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"LinkRoute<麟鹿>";
    
    [self exc];
    
    [self testUrl];
    
//    [self testModule];
    
//    [self testLinkRoute];
}

- (void)exc {
    
    [LinkRoute setExceptionHandler:^(NSException * _Nullable exception) {
        NSLog(@"excexcexcexcexcexcexc ===>> %@", exception.debugDescription);
    }];
}

- (void)testUrl {
    
    [LinkRoute bindURL:kShopPage1 toHandler:^(NSDictionary * _Nullable routerParameters) {
        NSLog(@"\n%@==> %@", kShopPage1, routerParameters);
    }];
//    [LinkRoute bindURL:kShopPage2 toHandler:^(NSDictionary * _Nullable routerParameters) {
//        NSLog(@"\n%@==> %@", kShopPage2, routerParameters);
//    }];
    
    
    [LinkRoute bindURL:kShopPage3 toHandler:^(NSDictionary * _Nullable routerParameters) {
        NSLog(@"\n%@==> %@", kShopPage3, routerParameters);
    }];
    [LinkRoute bindURL:kShopPage4 toHandler:^(NSDictionary * _Nullable routerParameters) {
        NSLog(@"\n%@==> %@", kShopPage4, routerParameters);
    }];
    [LinkRoute bindURL:kShopPage5 toHandler:^(NSDictionary * _Nullable routerParameters) {
        NSLog(@"\n%@==> %@", kShopPage5, routerParameters);
    }];
    
    [LinkRoute bindURL:kHomePage1 toObjectHandler:^id _Nullable(NSDictionary * _Nullable routerParameters) {
        LRViewController *controller = [[LRViewController alloc] init];
        NSLog(@"\n%@==> %@", kHomePage1, routerParameters);
        return controller;
    }];
    
    [LinkRoute openURL:kShopPage1];
    
    // 未注册
    [LinkRoute openURL:kShopPage2];
    
//    [LinkRoute openURL:kShopPage3 completion:^(id  _Nonnull result) {
//        NSLog(@"???");
//    }];
    
//    [LinkRoute openURL:kShopPage1 withUserInfo:@{@"12":@"34"} completion:^(id  _Nonnull result) {
//        NSLog(@"??? %@", result);
//    }];
    
//    LRViewController *controller = [LinkRoute objectForURL:kHomePage1 withUserInfo:@{@"111":@"222"}];
//    NSLog(@"??? %@", controller);
    
    [LinkRoute debugAllRouters];
}


- (void)testModule {
    
    id<LRModule1Protocol> module1 = [LinkRoute createService:@protocol(LRModule1Protocol)];
    [module1 sayHello:@"小米"];
    
    
    id<LRModule2Protocol> module2 = [LinkRoute createService:@protocol(LRModule2Protocol)];

}


- (void)testLinkRoute {
    
    [LinkRouteTester startTest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
