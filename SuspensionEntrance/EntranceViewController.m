//  EntranceViewController.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      EntranceViewController

#import "EntranceViewController.h"

@interface EntranceViewController ()

@end

@implementation EntranceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor purpleColor];
}


- (void)dealloc {
    
#if DEBUG
    NSLog(@"%@ is %@ing", self, NSStringFromSelector(_cmd));
    NSLog(@"self.gestures :%@", self.view.gestureRecognizers);
#endif
}

#pragma mark - SEItem

- (NSURL *)entranceUrl { return [NSURL URLWithString:@"https://www.baidu.com"]; }
- (NSString *)entranceTitle { return @"测试界面大了点马良看到没萨克拉莫德凯撒了; 没打卡洛斯;俺们"; }

@end
