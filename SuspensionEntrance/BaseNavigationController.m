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
}

@end
