//  AppDelegate.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      AppDelegate

#import "AppDelegate.h"
#import "SuspensionEntrance.h"
#import "SEFloatingBall.h"
#import "EntranceViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    dispatch_after(5.f, dispatch_get_main_queue(), ^{
//        
//        UIVisualEffect *effect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
//        SEFloatingBall *ballView = [[SEFloatingBall alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
//        [self.window insertSubview:ballView atIndex:100000];
//    });
    
    [SuspensionEntrance registerMonitorClass:[EntranceViewController class]];
    
    return YES;
}

@end
