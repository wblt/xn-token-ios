//
//  AppDelegate.m
//  Coin
//
//  Created by  tianlei on 2017/10/31.
//  Copyright © 2017年  tianlei. All rights reserved.
//

#import "AppDelegate.h"

#import "TLUIHeader.h"

#import "TLTabBarController.h"
#import "TLUser.h"
#import "TLNetworking.h"

#import "UITabBar+Badge.h"

#import "AppConfig.h"
#import "IMALoginParam.h"
#import "WXApi.h"
#import "TLWXManager.h"
#import "TLAlipayManager.h"
#import "ChatManager.h"
#import "ChatViewController.h"
#import <IQKeyboardManager.h>
#import "RichChatViewController.h"
#import "OrderDetailVC.h"
#import "WaitingOrderVC.h"
#import "ZMChineseConvert.h"

@interface AppDelegate ()

@property (nonatomic, strong) FBKVOController *chatKVOCtrl;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    //服务器环境
    [AppConfig config].runEnv = RunEnvDev;
    
    //配置微信
    [self configWeChat];
    
    //配置键盘
    [self configIQKeyboard];
    
    //配置根控制器
    [self configRootViewController];
    
    //初始化
    [self configIM];

    //重新登录
    if([TLUser user].isLogin) {
        
        [[TLUser user] updateUserInfo];
        [[TLUser user] changLoginTime];
        [[ChatManager sharedManager] loginIM];
        
    };
    
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginOut) name:kUserLoginOutNotification object:nil];
    //消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogin) name:kIMLoginNotification object:nil];
    
    return YES;
    
}

- (void)configIM {
    
    //配置
    [[ChatManager sharedManager] initChat];
//    [[ChatManager sharedManager] loginIM];
    
    //这里监听主要是为了，tabbar上的消息提示
    self.chatKVOCtrl = [FBKVOController controllerWithObserver:self];
    [self.chatKVOCtrl observe:[IMAPlatform sharedInstance].conversationMgr
                        keyPath:@"unReadMessageCount"
                        options:NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change) {
                             
                              NSInteger count =  [IMAPlatform sharedInstance].conversationMgr.unReadMessageCount;
                              
                              int location = 1;
                              if (count > 0) {
                                  
                                  [[self rootTabBarController].tabBar showBadgeOnItemIndex:location];

                              } else {
                                  
                                  [[self rootTabBarController].tabBar hideBadgeOnItemIndex:location];

                              }
                             
                          }];
    
}

#pragma mark- 退出登录
- (void)loginOut {
    
    //user 退出
    [[TLUser user] loginOut];
    
    //im 退出
    [[IMAPlatform sharedInstance] logout:^{
        
    } fail:^(int code, NSString *msg) {
        
    }];
    //
    UITabBarController *tabbarContrl = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    tabbarContrl.selectedIndex = 0;
    [tabbarContrl.tabBar hideBadgeOnItemIndex:1];
//  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
}

#pragma mark - 用户登录
- (void)userLogin {
    
    //获取消息总量
    NSInteger unReadMsgCount = [IMAPlatform sharedInstance].conversationMgr.unReadMessageCount;
    
    UITabBarController *tabBarController = [self rootTabBarController];

    if (unReadMsgCount > 0) {
        
        [tabBarController.tabBar showBadgeOnItemIndex:1];
        
    } else {
        
        [tabBarController.tabBar hideBadgeOnItemIndex:1];
        
    }
    
}

- (UITabBarController *)rootTabBarController {
    
    UITabBarController *tabBarController = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    return tabBarController;
    
}


- (void)configWeChat {
    
    [[TLWXManager manager] registerApp];
}

- (void)configIQKeyboard {
    
    [[IQKeyboardManager sharedManager].disabledToolbarClasses addObject:[OrderDetailVC class]];
    
    [[IQKeyboardManager sharedManager].disabledToolbarClasses addObject:[WaitingOrderVC class]];

    [[IQKeyboardManager sharedManager].disabledToolbarClasses addObject:[RichChatViewController class]];

}

- (void)configRootViewController {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    TLTabBarController *tabBarCtrl = [[TLTabBarController alloc] init];
    self.window.rootViewController = tabBarCtrl;
    
}

- (void)pushToChatViewControllerWith:(IMAUser *)user {
    
    TLTabBarController *tab = (TLTabBarController *)self.window.rootViewController;
    [tab pushToChatViewControllerWith:user];
    
}

+ (id)sharedAppDelegate {
    
    return [UIApplication  sharedApplication ].delegate;
    
}


#pragma mark - 微信和芝麻认证回调
// iOS9 NS_AVAILABLE_IOS
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    if ([url.host isEqualToString:@"certi.back"]) {
        
        //查询是否认证成功
        TLNetworking *http = [TLNetworking new];
        http.showView = [UIApplication sharedApplication].keyWindow;
        http.code = @"805196";
        http.parameters[@"bizNo"] = [TLUser user].tempBizNo;
        http.parameters[@"userId"] = [TLUser user].userId;

        [http postWithSuccess:^(id responseObject) {
            
            NSString *str = [NSString stringWithFormat:@"%@", responseObject[@"data"][@"isSuccess"]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RealNameAuthResult" object:str];
            
        } failure:^(NSError *error) {
            
            
        }];
        
        return YES;
    }
    
    if ([url.host isEqualToString:@"safepay"]) {
        
        [TLAlipayManager hadleCallBackWithUrl:url];
        return YES;
        
    } else {
        
        return [WXApi handleOpenURL:url delegate:[TLWXManager manager]];
    }
}

// iOS9 NS_DEPRECATED_IOS
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([url.host isEqualToString:@"certi.back"]) {
        
        //查询是否认证成功
        TLNetworking *http = [TLNetworking new];
        http.showView = [UIApplication sharedApplication].keyWindow;
        http.code = @"805196";
        http.parameters[@"bizNo"] = [TLUser user].tempBizNo;
        http.parameters[@"userId"] = [TLUser user].userId;

        [http postWithSuccess:^(id responseObject) {
            
            NSString *str = [NSString stringWithFormat:@"%@", responseObject[@"data"][@"isSuccess"]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RealNameAuthResult" object:str];
            
        } failure:^(NSError *error) {
            
            
        }];
        
        return YES;
    }
    
    if ([url.host isEqualToString:@"safepay"]) {
        
        [TLAlipayManager hadleCallBackWithUrl:url];
        return YES;
        
    } else {
        
        return [WXApi handleOpenURL:url delegate:[TLWXManager manager]];
    }
}

@end
