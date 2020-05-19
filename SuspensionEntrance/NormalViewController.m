//  NormalViewController.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      NormalViewController

#import "NormalViewController.h"
#import "EntranceViewController.h"
#import "BaseNavigationController.h"
#import "PresentNavigationController.h"

@interface SEImageView : UIImageView
@end
@implementation SEImageView
+ (Class)layerClass { return [CAShapeLayer class]; }
@end

@interface NormalViewController () <UITableViewDelegate, UITableViewDataSource>
@property (copy  , nonatomic) NSArray<NSDictionary *> *items;
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


#pragma mark - UITableViewDelegate & UITableViewSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    
    UILabel *titleLabel = [cell.contentView viewWithTag:99];
    UIImageView *imageView = [cell.contentView viewWithTag:100];
    
    NSDictionary *item = [self.items objectAtIndex:indexPath.row];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *iconUrl = [item objectForKey:@"iconUrl"];
        NSData *data = [NSData dataWithContentsOfURL:iconUrl];
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
        });
    });
    
    titleLabel.text = [item objectForKey:@"title"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Push" : @"Present";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

//    CGFloat const radius = 20.f;
//    
//    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.view.frame, 100.f, 100.f) cornerRadius:radius];
//    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(200.f, 200.f, 50.f, 50.f) cornerRadius:radius];
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.fillColor = [UIColor blackColor].CGColor;
//    maskLayer.path = endPath.CGPath;
//    maskLayer.frame = CGRectInset(self.view.frame, 100.f, 100.f);
//    self.view.layer.mask = maskLayer;
//    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
//    maskLayerAnimation.fromValue = (__bridge id)(startPath.CGPath);
//    maskLayerAnimation.toValue = (__bridge id)(endPath.CGPath);
//    maskLayerAnimation.duration = 2.f;
//    maskLayerAnimation.delegate = (id<CAAnimationDelegate>)self;
//    [maskLayer addAnimation:maskLayerAnimation forKey:@"xw_path"];
//    
//    return;
//    
    NSDictionary *item = [self.items objectAtIndex:indexPath.row];
    EntranceViewController *controller = (EntranceViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"EntranceViewController"];
    controller.entranceTitle = [item objectForKey:@"title"];
    controller.entranceIconUrl = [item objectForKey:@"iconUrl"];
    controller.entranceUserInfo = [item objectForKey:@"userInfo"];
    if (indexPath.section == 0) {
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        PresentNavigationController *nav = [[PresentNavigationController alloc] initWithRootViewController:controller];
        [self.navigationController presentViewController:nav animated:YES completion:NULL];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.view.layer.mask = nil;
}

#pragma mark - Getter

- (NSArray<NSDictionary *> *)items {
    
    return @[
             @{
                 @"title" : @"Google",
                 @"iconUrl" : [NSURL URLWithString:@"https://google.com/favicon.ico"],
                 @"userInfo" : @{
                         @"url" : @"https://www.google.com"
                         }
                 },
             @{
                 @"title" : @"百度一下，你就知道",
                 @"iconUrl" : [NSURL URLWithString:@"https://www.baidu.com/favicon.ico"],
                 @"userInfo" : @{
                         @"url" : @"https://www.baidu.com"
                         }
                 },
             @{
                 @"title" : @"哔哩哔哩 (゜-゜)つロ 干杯~-bilibili",
                 @"iconUrl" : [NSURL URLWithString:@"https://www.bilibili.com/favicon.ico"],
                 @"userInfo" : @{
                         @"url" : @"https://www.bilibili.com"
                         }
                 }
             ];
}


@end
