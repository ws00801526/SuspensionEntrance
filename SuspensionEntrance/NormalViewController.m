//  NormalViewController.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      NormalViewController

#import "NormalViewController.h"

@interface NormalViewController ()

@end

@implementation NormalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
}

- (void)dealloc {
    
#if DEBUG
    NSLog(@"%@ is %@ing", self, NSStringFromSelector(_cmd));
    NSLog(@"self.gestures :%@", self.view.gestureRecognizers);
#endif
}

@end
