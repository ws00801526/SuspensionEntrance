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

+ (instancetype)entranceWithItem:(id<SEItem>)item {
    EntranceViewController *controller = [[EntranceViewController alloc] initWithNibName:nil bundle:nil];
    controller.entranceTitle = item.entranceTitle;
    controller.entranceIconUrl = item.entranceIconUrl;
    controller.entranceUserInfo = item.entranceUserInfo;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor purpleColor];
    
    if (self.entranceTitle.length <= 0) {
        NSArray *titles = @[
                            @"我是测试标题一",
                            @"我是测试标题二, 但是我的标题很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长",
                            @"百度的测试界面",
                            @"优酷测试界面",
                            @"Google一下,世界更精彩",
                            ];
        
        self.entranceTitle = [titles objectAtIndex:arc4random() % 5];
    }
}

- (void)dealloc {
    
#if DEBUG
    NSLog(@"%@ is %@ing", self, NSStringFromSelector(_cmd));
    NSLog(@"self.gestures :%@", self.view.gestureRecognizers);
#endif
}

@end
