//  BaseNavigationController.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      BaseNavigationController

#import "BaseNavigationController.h"

#import "SuspensionEntrance.h"

@interface BaseNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@end

@implementation BaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = [SuspensionEntrance shared];
    self.interactivePopGestureRecognizer.enabled = NO;
    self.interactivePopGestureRecognizer.delegate = self;
}

//#pragma mark - UINavigationControllerDelegate
//
//- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
//                                  animationControllerForOperation:(UINavigationControllerOperation)operation
//                                               fromViewController:(UIViewController *)fromVC
//                                                 toViewController:(UIViewController *)toVC {
//    return nil;
//}
//
//- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
//                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
//    return nil;
//}
//
//- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//    NSLog(@"did show controller :%@", viewController);
//}
//
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//    NSLog(@"will show controller :%@", viewController);
//}

@end
