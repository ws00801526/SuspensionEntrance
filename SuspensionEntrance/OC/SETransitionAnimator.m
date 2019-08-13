//  SETransitionAnimator.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SETransitionAnimator

#import "SETransitionAnimator.h"

@interface SETransitionAnimator ()
@property (strong, nonatomic) UIView *coverView;
@property (strong, nonatomic) id<UIViewControllerContextTransitioning> transitionContext;

@end

@implementation SETransitionAnimator

#pragma mark - Life

- (instancetype)initWithStyle:(SETransitionAnimatorStyle)style
                       center:(CGPoint)center
                       radius:(CGFloat)radius {
    self = [super init];
    if (self) {
        _style  = style;
        _radius = radius;
        _center = center;
    }
    return self;
}

+ (instancetype)roundPopAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleRoundPop center:center radius:radius];
}

+ (instancetype)roundPushAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleRoundPush center:center radius:radius];
}

+ (instancetype)continuousPopAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius {
    return [[SETransitionAnimator alloc] initWithStyle:SETransitionAnimatorStyleContinuousPop center:center radius:radius];
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
    fromVC.view.frame = CGRectMake(0, fromVC.view.frame.origin.y, fromVC.view.frame.size.width, fromVC.view.frame.size.height);
    CGFloat endFloatX = self.center.x - self.radius;
    CGRect floatRect = CGRectMake(endFloatX, self.center.y - self.radius, self.radius * 2, self.radius *2);
    
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(currentX, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2) cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:floatRect cornerRadius:self.radius];
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
    CGRect floatRect = CGRectMake(self.center.x - self.radius, self.center.y - self.radius, self.radius * 2, self.radius *2);
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:floatRect cornerRadius:self.radius];
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
    CGRect floatRect = CGRectMake(self.center.x - self.radius, self.center.y - self.radius, self.radius * 2, self.radius * 2);
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-self.radius, -self.radius, SCREEN_WIDTH + self.radius * 2, SCREEN_HEIGHT + self.radius * 2) cornerRadius:self.radius];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithRoundedRect:floatRect cornerRadius:self.radius];
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

- (void)startDefaultPushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    toView.frame = CGRectMake(toView.bounds.size.width, 0, toView.bounds.size.width, toView.bounds.size.height);
    [containerView addSubview:fromView];
    [containerView addSubview:toView];
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        fromView.frame = CGRectMake(- fromView.bounds.size.width / 3.f, 0.f, fromView.bounds.size.width, fromView.bounds.size.height);
        toView.frame = CGRectMake(0, 0, toView.bounds.size.width, toView.bounds.size.height);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

- (void)startDefaultPopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    toView.frame = CGRectMake(toView.bounds.size.width * -1.f / 3.f, 0, toView.bounds.size.width, toView.bounds.size.height);
    [containerView addSubview:toView];
    [containerView addSubview:fromView];

    [UIView animateWithDuration:self.animationDuration animations:^{
        fromView.frame = CGRectMake(fromView.bounds.size.width, 0.f, fromView.bounds.size.width, fromView.bounds.size.height);
        toView.frame = CGRectMake(0, 0, toView.bounds.size.width, toView.bounds.size.height);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
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
