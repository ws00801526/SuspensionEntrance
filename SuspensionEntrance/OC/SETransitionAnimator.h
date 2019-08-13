//  SETransitionAnimator.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SETransitionAnimator

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SETransitionAnimatorStyle) {
    SETransitionAnimatorStyleUnknown = 0,
    SETransitionAnimatorStyleRoundPush,
    SETransitionAnimatorStyleRoundPop,
    SETransitionAnimatorStyleContinuousPop
};

NS_ASSUME_NONNULL_BEGIN

@interface SETransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (assign, nonatomic, readonly) NSTimeInterval animationDuration;
@property (assign, nonatomic, readonly) CGFloat radius;
@property (assign, nonatomic, readonly) CGPoint center;
@property (assign, nonatomic, readonly) SETransitionAnimatorStyle style;
@property (strong, nonatomic, readonly) UIPercentDrivenInteractiveTransition *interactive;

- (instancetype)initWithStyle:(SETransitionAnimatorStyle)style
                       center:(CGPoint)center
                       radius:(CGFloat)radius;

+ (instancetype)roundPopAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius;
+ (instancetype)roundPushAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius;
+ (instancetype)replaceAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius;
+ (instancetype)continuousPopAnimatorWithCenter:(CGPoint)center radius:(CGFloat)radius;

- (void)finishContinousPopAnimation;
- (void)cancelContinousPopAnimation;
- (void)updateContinousPopAnimationPercent:(CGFloat)precent;
- (void)finishContinousPopAnimationWithFastAnimating:(BOOL)fast;

@end

NS_ASSUME_NONNULL_END
