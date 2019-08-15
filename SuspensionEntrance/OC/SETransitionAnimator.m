//  SETransitionAnimator.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SETransitionAnimator

#import "SETransitionAnimator.h"

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

- (void)finishContinousPopAnimation {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height;
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [fromVC.view addSubview:self.coverView];
    //当前fromVC.view有偏移，需要重置
    CGFloat const currentX = fromVC.view.frame.origin.x;
    fromVC.view.frame = (CGRect) { CGPointMake(0, fromVC.view.frame.origin.y), fromVC.view.frame.size };

    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(currentX, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2) cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:self.floatingRect cornerRadius:self.radius];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = endPath.CGPath;
    fromVC.view.layer.mask = maskLayer;
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(startPath.CGPath);
    maskLayerAnimation.toValue = (__bridge id)(endPath.CGPath);
    maskLayerAnimation.duration = 0.2f;
    maskLayerAnimation.delegate = (id<CAAnimationDelegate>)self;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"xw_path"];
    
    CGFloat duration = (1 - currentX / SCREEN_WIDTH) * self.animationDuration;
    self.coverView.alpha = 0;
    [UIView animateWithDuration:duration animations:^{
        self.coverView.alpha = 0.3;
        toVC.view.frame = (CGRect){ CGPointMake(0, toVC.view.frame.origin.y), toVC.view.frame.size };
    } completion:^(BOOL finished) {
        [self.coverView removeFromSuperview];
    }];
}

- (void)cancelContinousPopAnimation {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGFloat percent = fromVC.view.frame.origin.x / SCREEN_WIDTH;
    [UIView animateWithDuration:self.animationDuration * percent animations:^{
        fromVC.view.frame = (CGRect){ CGPointMake(0.f, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
        toVC.view.frame = (CGRect){ CGPointMake(-SCREEN_WIDTH / 3.f, toVC.view.frame.origin.y) , toVC.view.frame.size };
    } completion:^(BOOL finished) {
        toVC.view.frame = (CGRect){ CGPointMake(0, toVC.view.frame.origin.y) , toVC.view.frame.size };
        [self.transitionContext completeTransition:!self.transitionContext.transitionWasCancelled];
    }];
}

- (void)updateContinousPopAnimationPercent:(CGFloat)percent {
    
    percent = MIN(1.f, MAX(0.f, percent));
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    fromVC.view.frame = (CGRect){ CGPointMake(SCREEN_WIDTH * percent, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
    toVC.view.frame = (CGRect){ CGPointMake((SCREEN_WIDTH / -3.f) * (1 - percent), toVC.view.frame.origin.y) , toVC.view.frame.size };
}

- (void)finishContinousPopAnimationWithFastAnimating:(BOOL)fast {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGFloat duration = 0.2f;
    if (fast) duration = (1 - fromVC.view.frame.origin.x / SCREEN_WIDTH) * self.animationDuration;
    
    [UIView animateWithDuration:duration animations:^{
        fromVC.view.frame = (CGRect){ CGPointMake(SCREEN_WIDTH, fromVC.view.frame.origin.y) , fromVC.view.frame.size };
        toVC.view.frame = (CGRect){ CGPointMake(0.f, toVC.view.frame.origin.y) , toVC.view.frame.size };
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
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height;
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:self.coverView];
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
    
    self.coverView.alpha = 0;
    [UIView animateWithDuration:self.animationDuration animations:^{ self.coverView.alpha = 0.8; }];
}

- (void)startRoundPopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height;
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
    
    self.coverView.alpha = 1.0f;
    [UIView animateWithDuration:self.animationDuration animations:^{ self.coverView.alpha = 0.f; }];
}

- (void)startContinousPopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    toVC.view.frame = CGRectMake(toView.bounds.size.width * -1.f / 3.f, 0, toView.bounds.size.width, toView.bounds.size.height);
    [containerView insertSubview:toVC.view atIndex:0];
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

- (NSTimeInterval)animationDuration { return 0.2f; }

@end
