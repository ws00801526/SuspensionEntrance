//  SEFloatingView.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingView

#import "SEFloatingBall.h"

static const CGFloat kSEFloatingBallRadius = 30.f;
static const CGFloat kSEScreenWidth() { return UIScreen.mainScreen.bounds.size.width; }
static const CGFloat kSEScreenHeight() { return UIScreen.mainScreen.bounds.size.height; }

@interface SEFloatingBall ()
@property (strong, nonatomic) CAShapeLayer *backgroundLayer;
@end

@implementation SEFloatingBall

- (instancetype)initWithEffect:(UIVisualEffect *)effect {
    
    self = [super initWithEffect:effect];
    if (self) {
        [self setupUI];
        [self setupGestures];
    }
    return self;
}

#pragma mark - Override

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.contentView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0f];
    self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.contentView.backgroundColor = [UIColor clearColor];
//    self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.contentView.backgroundColor = [UIColor clearColor];
//    self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
}

#pragma mark - Private

- (void)setupUI {
    
    _backgroundLayer = [CAShapeLayer layer];
    _backgroundLayer.mask = [self maskLayerWithRectCorners:UIRectCornerAllCorners];
    [self.contentView.layer insertSublayer:_backgroundLayer atIndex:0];
    
    
    self.frame = CGRectMake(100, 100, kSEFloatingBallRadius * 2.f, kSEFloatingBallRadius * 2.f);
    self.layer.mask = [self maskLayerWithRectCorners:UIRectCornerAllCorners];
}

- (void)setupGestures {
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    longPress.allowableMovement = 5.f;
    [self addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
    [pan requireGestureRecognizerToFail:longPress];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
    [tap requireGestureRecognizerToFail:pan];
}

#pragma mark - Actions

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        // pan start, record some position
        self.layer.mask = [self maskLayerWithRectCorners:UIRectCornerAllCorners];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        // pan changed, update self.position
        CGFloat const halfWidth = kSEFloatingBallRadius / 2.f;
        CGPoint transition = [pan translationInView:pan.view];
        CGFloat transitionX = MAX(halfWidth, MIN(self.center.x + transition.x, kSEScreenWidth() - halfWidth));
        CGFloat transitionY = MAX(halfWidth, MIN(self.center.y + transition.y, kSEScreenHeight() - halfWidth));
        self.center = CGPointMake(transitionX, transitionY);
        [pan setTranslation:CGPointZero inView:pan.view];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateChanged) {
        [self showMoveBorderAnimation];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    
    SEL selector = NULL;
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
            selector = @selector(floatingBall:pressDidBegan:);
            break;
        case UIGestureRecognizerStateChanged:
            selector = @selector(floatingBall:pressDidChanged:);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            selector = @selector(floatingBall:pressDidEnded:);
            break;
        default: break;
    }
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Weverything"
        [self.delegate performSelector:selector withObject:self withObject:longPress];
#pragma clang diagnostic pop
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingBallDidClicked:)]) {
        [self.delegate floatingBallDidClicked:self];
    }
}

#pragma mark - Animations

- (void)showMoveBorderAnimation {
    
    CGFloat minX = 0.f;
    CGFloat maxX = kSEScreenWidth() - self.bounds.size.height;
    CGFloat minY = 0.f;
    if (@available(iOS 11.0, *)) minY = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    CGFloat maxY = kSEScreenHeight() - self.bounds.size.height;
    if (@available(iOS 11.0, *)) maxY = kSEScreenHeight() - self.bounds.size.height - UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    BOOL isLeft = (self.center.x < kSEScreenWidth() / 2.0);
    CGPoint point = CGPointMake(isLeft ? minX : maxX, MIN(MAX(minY, self.frame.origin.y), maxY));
    [UIView animateWithDuration:0.15 animations:^{
        self.frame = CGRectMake(point.x, point.y, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished) {
        UIRectCorner corners = isLeft ? (UIRectCornerTopRight | UIRectCornerBottomRight) : (UIRectCornerTopLeft | UIRectCornerBottomLeft);
        self.layer.mask = [self maskLayerWithRectCorners:corners];
    }];
}

#pragma mark - Helpers

- (CAShapeLayer *)maskLayerWithRectCorners:(UIRectCorner)corners {
    CGSize size = CGSizeApplyAffineTransform(self.bounds.size, CGAffineTransformMakeScale(0.5f, 0.5f));
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:size];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.bounds;
    layer.path = path.CGPath;
    return layer;
}

#pragma mark - Getter

- (CGRect)floatingRect {
    return CGRectMake(15.f, 12.5f, 35.f, 35.f);
}

@end
