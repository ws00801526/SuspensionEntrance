//
//  PresentNavigationController.m
//  SuspensionEntrance
//
//  Created by XMFraker on 2020/5/18.
//  Copyright © 2020 Fraker.XM. All rights reserved.
//

#import "PresentNavigationController.h"
#import "NormalViewController.h"
#import "EntranceViewController.h"

@interface PresentNavigationController ()

@end

@implementation PresentNavigationController
@dynamic entranceTitle;
@dynamic entranceIconUrl;
@dynamic entranceUserInfo;

+ (instancetype)entranceWithItem:(id<SEItem>)item {
    
    EntranceViewController *normalController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"EntranceViewController"];
    PresentNavigationController *controller = [[PresentNavigationController alloc] initWithRootViewController:normalController];
    controller.entranceTitle = item.entranceTitle;
    controller.entranceIconUrl = item.entranceIconUrl;
    controller.entranceUserInfo = item.entranceUserInfo;
    return controller;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        // !!!: use full screen on iOS13+. otherwise the default present style will cause the gesture recognized failed.
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.transitioningDelegate = [SuspensionEntrance shared];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Setter

- (void)setEntranceTitle:(NSString *)entranceTitle {
    // maybe using visible-title
//    UIViewController *controller = self.visibleViewController ? : self.viewControllers.firstObject;
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) ((id<SEItem>)controller).entranceTitle = entranceTitle;
}

- (void)setEntranceIconUrl:(NSURL *)entranceIconUrl {
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) ((id<SEItem>)controller).entranceIconUrl = entranceIconUrl;
}

- (void)setEntranceUserInfo:(NSDictionary *)entranceUserInfo {
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) ((id<SEItem>)controller).entranceUserInfo = entranceUserInfo;
}

#pragma mark - Getter

- (NSURL *)entranceIconUrl {
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) return ((id<SEItem>)controller).entranceIconUrl;
    return nil;
}

- (NSString *)entranceTitle {
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) return ((id<SEItem>)controller).entranceTitle;
    return nil;
}

- (NSDictionary *)entranceUserInfo {
    UIViewController *controller = self.viewControllers.firstObject;
    if ([controller conformsToProtocol:@protocol(SEItem)]) return ((id<SEItem>)controller).entranceUserInfo;
    return nil;
}

@end
