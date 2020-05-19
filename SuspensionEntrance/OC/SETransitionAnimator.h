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
@property (assign, nonatomic, readonly) SETransitionAnimatorStyle style;

+ (instancetype)roundPushAnimatorWithRect:(CGRect)rect;
+ (instancetype)roundPopAnimatorWithRect:(CGRect)rect;
+ (instancetype)continuousPopAnimatorWithRect:(CGRect)rect;

- (void)finishContinousAnimation;
- (void)cancelContinousAnimation;
- (void)updateContinousAnimationPercent:(CGFloat)precent;
- (void)finishContinousAnimationWithFastAnimating:(BOOL)fast;

@end

NS_ASSUME_NONNULL_END
