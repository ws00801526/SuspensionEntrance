//  SETransitionAnimator.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SETransitionAnimator

#import "SETransitionAnimator.h"

#ifndef SCREEN_WIDTH
    #define SCREEN_WIDTH UIScreen.mainScreen.bounds.size.width
#endif

#ifndef SCREEN_HEIGHT
    #define SCREEN_HEIGHT UIScreen.mainScreen.bounds.size.height
#endif

@interface SETransitionAnimator ()
@property (assign, nonatomic) CGRect floatingRect;
@property (strong, nonatomic) UIView *coverView;
@property (assign, nonatomic) CGFloat radius;
@property (strong, nonatomic) id<UIViewControllerContextTransitioning> transitionContext;
@end

@implementation SETransitionAnimator

#pragma mark - Life

- (instancetype)initWithStyle:(SETransitionAnimatorStyle)style floatingRect:(CGRect)rect {
    
    self = [super init];
    if (self) {
        _style = style;
        _radius = CGRectGetHeight(rect) / 2.f;
        _floatingRect = rect;
    }
    return self;
}

+ (instancetype)roundPushAnimatorWithRect:(CGRect)rect {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleRoundPush floatingRect:rect];
}

+ (instancetype)roundPopAnimatorWithRect:(CGRect)rect {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleRoundPop floatingRect:rect];
}

+ (instancetype)continuousPopAnimatorWithRect:(CGRect)rect {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleContinuousPop floatingRect:rect];
}

#pragma mark - Public

- (void)finishContinousAnimation {
    
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL const isPresented = fromVC.presentingViewController != nil;
    [fromVC.view addSubview:self.coverView];
    // 当前fromVC.view有偏移，需要重置
    CGFloat const currentOffset = isPresented ? fromVC.view.frame.origin.y : fromVC.view.frame.origin.x;
    fromVC.view.frame = (CGRect){ CGPointZero, fromVC.view.frame.size };
//    if (isPresented) fromVC.view.frame = (CGRect) { CGPointMake(0.f, fromVC.view.frame.origin.y), fromVC.view.frame.size };
//    else fromVC.view.frame = (CGRect) { CGPointMake(fromVC.view.frame.origin.x, 0.f), fromVC.view.frame.size };
    
    CGRect roundedRect = CGRectMake(currentOffset, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2);
    if (isPresented) roundedRect = CGRectMake(-self.radius, currentOffset, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2);
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:self.floatingRect cornerRadius:self.radius];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    maskLayer.path = endPath.CGPath;
    maskLayer.frame = fromVC.view.frame;
    fromVC.view.layer.mask = maskLayer;
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(startPath.CGPath);
    maskLayerAnimation.toValue = (__bridge id)(endPath.CGPath);
    maskLayerAnimation.duration = 0.2f;
    maskLayerAnimation.delegate = (id<CAAnimationDelegate>)self;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"xw_path"];
    
    CGFloat duration = (1 - (isPresented ? (currentOffset / SCREEN_HEIGHT) : (currentOffset / SCREEN_WIDTH))) * self.animationDuration;
    self.coverView.alpha = 0;
    [UIView animateWithDuration:duration animations:^{
        self.coverView.alpha = isPresented ? 0.f : 0.3;
        if (!isPresented) toVC.view.frame = (CGRect){ CGPointMake(0, toVC.view.frame.origin.y), toVC.view.frame.size };
        UITabBar *tabBar = toVC.tabBarController.tabBar;
        if (tabBar) tabBar.frame = (CGRect) { CGPointMake(0.f, toVC.view.bounds.size.height - tabBar.bounds.size.height), tabBar.bounds.size };
    } completion:^(BOOL finished) {
        [self.coverView removeFromSuperview];
    }];
}

- (void)cancelContinousAnimation {
    
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BOOL isPresented = fromVC.presentingViewController != nil;
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGFloat percent = isPresented ? fromVC.view.frame.origin.y / SCREEN_HEIGHT : fromVC.view.frame.origin.x / SCREEN_WIDTH;
    [UIView animateWithDuration:self.animationDuration * percent animations:^{
        if (isPresented) fromVC.view.frame = (CGRect){ CGPointMake(fromVC.view.frame.origin.x, 0.f) , fromVC.view.frame.size };
        else {
            fromVC.view.frame = (CGRect){ CGPointMake(0.f, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
            toVC.view.frame = (CGRect){ CGPointMake(-SCREEN_WIDTH / 3.f, toVC.view.frame.origin.y) , toVC.view.frame.size };
        }
    } completion:^(BOOL finished) {
        if (!isPresented) toVC.view.frame = (CGRect){ CGPointMake(0, toVC.view.frame.origin.y) , toVC.view.frame.size };
        [self.transitionContext completeTransition:!self.transitionContext.transitionWasCancelled];
    }];
}

- (void)updateContinousAnimationPercent:(CGFloat)percent {
    
    percent = MIN(1.f, MAX(0.f, percent));
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL const isPresented = fromVC.presentingViewController != nil;
    
    if (isPresented) {
        fromVC.view.frame = (CGRect){ CGPointMake(0.f, SCREEN_HEIGHT * percent) , fromVC.view.frame.size };
    } else {
        fromVC.view.frame = (CGRect){ CGPointMake(SCREEN_WIDTH * percent, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
        toVC.view.frame = (CGRect){ CGPointMake((SCREEN_WIDTH / -3.f) * (1 - percent), toVC.view.frame.origin.y) , toVC.view.frame.size };
    }
    
    self.coverView.alpha = (1 - percent) * 0.7f;
    
    UITabBar *tabBar = toVC.tabBarController.tabBar;
    if (tabBar == nil) return;
    CGFloat maxY =  tabBar.bounds.size.height * percent;
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) maxY += tabBar.safeAreaInsets.bottom;
#endif
    maxY = MIN(maxY, tabBar.bounds.size.height);
    tabBar.frame = (CGRect) { CGPointMake(0.f, toVC.view.bounds.size.height - maxY), tabBar.bounds.size };
}

- (void)finishContinousAnimationWithFastAnimating:(BOOL)fast {
    
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL const isPresented = fromVC.presentingViewController != nil;
    CGFloat duration = 0.2f;
    if (fast) duration = (1 - fromVC.view.frame.origin.x / SCREEN_WIDTH) * self.animationDuration;
    
    [UIView animateWithDuration:duration animations:^{
        if (isPresented) {
            fromVC.view.frame = (CGRect){ CGPointMake(fromVC.view.frame.origin.x, SCREEN_HEIGHT) , fromVC.view.frame.size };
        } else {
            fromVC.view.frame = (CGRect){ CGPointMake(SCREEN_WIDTH, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
            toVC.view.frame = (CGRect){ CGPointMake(0.f, toVC.view.frame.origin.y) , toVC.view.frame.size };
        }
        UITabBar *tabBar = toVC.tabBarController.tabBar;
        if (tabBar) {
            tabBar.frame = (CGRect) { CGPointMake(0.f, toVC.view.bounds.size.height - tabBar.bounds.size.height), tabBar.bounds.size };
        }
    } completion:^(BOOL finished) {
        [self.transitionContext completeTransition:!self.transitionContext.transitionWasCancelled];
    }];
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.animationDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

    self.transitionContext = transitionContext;
    switch (self.style) {
        case SETransitionAnimatorStyleRoundPop:
            [self startRoundPopAnimation:transitionContext];
            break;
        case SETransitionAnimatorStyleRoundPush:
            [self startRoundPushAnimation:transitionContext];
            break;
        case SETransitionAnimatorStyleContinuousPop:
            [self startContinousPopAnimation:transitionContext];
            break;
        case SETransitionAnimatorStyleUnknown: // fall through
        default: break;
    }
}

- (void)animationEnded:(BOOL)transitionCompleted {

    // animation ended
    
    [self.coverView removeFromSuperview];
//    [self.transitionContext completeTransition:transitionCompleted];
    self.transitionContext = nil;
}

#pragma mark - Animations

- (void)startRoundPushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:self.coverView];
    toVC.view.frame = CGRectMake(0.f, 0.f, SCREEN_WIDTH, SCREEN_HEIGHT);
    [containerView addSubview:toVC.view];
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:self.floatingRect cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-self.radius, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2) cornerRadius:self.radius];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = endPath.CGPath;
    toVC.view.layer.mask = maskLayer;
    
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(startPath.CGPath);
    maskLayerAnimation.toValue = (__bridge id)((endPath.CGPath));
    maskLayerAnimation.duration = self.animationDuration;
    maskLayerAnimation.delegate = (id<CAAnimationDelegate>)self;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"xw_path"];
    
    self.coverView.alpha = 0.0f;
    UITabBar *tabBar = fromVC.tabBarController.tabBar;
    tabBar.frame = (CGRect) { CGPointMake(0.f, fromVC.view.bounds.size.height - tabBar.bounds.size.height), tabBar.bounds.size };
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.coverView.alpha = 0.6f;
        tabBar.frame = (CGRect) { CGPointMake(fromVC.view.bounds.size.width, fromVC.view.bounds.size.height), tabBar.bounds.size };
    }];
}

- (void)startRoundPopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor whiteColor];
    [containerView insertSubview:toVC.view atIndex:0];

    [toVC.view addSubview:self.coverView];
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-self.radius, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2) cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:self.floatingRect cornerRadius:self.radius];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = endPath.CGPath;
    fromVC.view.layer.mask = maskLayer;

    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(startPath.CGPath);
    maskLayerAnimation.toValue = (__bridge id)(endPath.CGPath);
    maskLayerAnimation.duration = self.animationDuration;
    maskLayerAnimation.delegate = (id<CAAnimationDelegate>)self;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"xw_path"];
    
    self.coverView.alpha = 0.6f;
    
    UITabBar *tabBar = toVC.tabBarController.tabBar;
    CGPoint origin = CGPointMake(0.f, toVC.view.bounds.size.height - tabBar.bounds.size.height);
    tabBar.frame = (CGRect) { CGPointMake(0.f, toVC.view.bounds.size.height), tabBar.bounds.size };
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.coverView.alpha = 0.0f;
        tabBar.frame = (CGRect) { origin, tabBar.bounds.size };
    }];
}

- (void)startContinousPopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    BOOL const isPresented = fromVC.presentingViewController != nil;
    if (!isPresented) toVC.view.frame = CGRectMake(toView.bounds.size.width * -1.f / 3.f, 0, toView.bounds.size.width, toView.bounds.size.height);
    [containerView insertSubview:toVC.view atIndex:0];
    
    if (isPresented) {
        self.coverView.alpha = 0.7f;
        [toVC.view addSubview:self.coverView];
    }
       
    UITabBar *tabBar = toVC.tabBarController.tabBar;
    if (tabBar == nil) return;
    tabBar.frame = (CGRect) { CGPointMake(0.f, toView.bounds.size.height), tabBar.bounds.size };
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self.transitionContext completeTransition:!self.transitionContext.transitionWasCancelled];
}

#pragma mark - Getter

- (UIView *)coverView {
    if (!_coverView) _coverView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    _coverView.backgroundColor = [UIColor blackColor];
    return _coverView;
}

- (NSTimeInterval)animationDuration { return 0.3f; }

@end

#undef SCREEN_WIDTH
#undef SCREEN_HEIGHT
