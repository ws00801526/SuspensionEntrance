//  EntranceViewController.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      EntranceViewController

#import "EntranceViewController.h"
#import "NormalViewController.h"

#import <WebKit/WebKit.h>

@interface EntranceViewController ()
@property (strong, nonatomic) WKWebView *webView;
@end

@implementation EntranceViewController
@dynamic view;

+ (instancetype)entranceWithItem:(id<SEItem>)item {
    EntranceViewController *controller = [[EntranceViewController alloc] initWithNibName:nil bundle:nil];
    controller.entranceTitle = item.entranceTitle;
    controller.entranceIconUrl = item.entranceIconUrl;
    controller.entranceUserInfo = item.entranceUserInfo;
    return controller;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    NSURL *url = [NSURL URLWithString:[self.entranceUserInfo objectForKey:@"url"]];
    if (url) [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(pushNormalController)];
    self.navigationItem.rightBarButtonItem = next;
}

- (void)pushNormalController {
    
    UIStoryboard *storyboard = self.storyboard;
    if (!storyboard) storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NormalViewController *controller = (NormalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"NormalViewController"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)dealloc {
    
#if DEBUG
    NSLog(@"%@ is %@ing", self, NSStringFromSelector(_cmd));
    NSLog(@"self.gestures :%@", self.view.gestureRecognizers);
#endif
}


@end
