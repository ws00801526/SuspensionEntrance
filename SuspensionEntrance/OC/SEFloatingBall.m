//  SEFloatingView.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingView

#import "SEFloatingBall.h"
#import "SuspensionEntrance.h"

static NSString * const kSEFloatingBallFrameKey = @"com.fraker.xm.se.ball.frame";

static const CGFloat kSEFloatingBallRadius() {
    // XR,Plus = 70.f others = 60.f
    return UIScreen.mainScreen.scale == 3 ? 35.f : 30.f;
}

static const CGFloat kSEFloatingBallPadding() {
    // XR,Plus = 9.f others = 6.f
    return UIScreen.mainScreen.scale * 3.f;
}

static const CGFloat kSEScreenWidth() { return UIScreen.mainScreen.bounds.size.width; }
static const CGFloat kSEScreenHeight() { return UIScreen.mainScreen.bounds.size.height; }

@interface SEFloatingBallItem : UIImageView
@end

@implementation SEFloatingBallItem

#pragma mark - Life

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeCenter;
    }
    return self;
}

+ (Class)layerClass { return [CAShapeLayer class]; }

#pragma mark - Override

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.transform = CGAffineTransformMakeScale(0.3, 0.3);
        [UIView animateWithDuration:0.25 animations:^{ self.transform = CGAffineTransformMakeScale(1.f, 1.f); }];
    }
}

#pragma mark - Private

- (void)updateMaskWithAngle:(CGFloat)angle isRound:(BOOL)isRound {
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = [self maskPathWithRound:isRound].CGPath;
    maskLayer.transform = CATransform3DRotate(CATransform3DIdentity, angle, 0, 0, 1);
    self.layer.mask = maskLayer;
}

- (UIBezierPath *)maskPathWithRound:(BOOL)isRound {
    
    CGFloat radius = CGRectGetHeight(self.bounds) / 2.f;
    if (isRound) return [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius];
    
    CGFloat startAngle = 45.f / 180.f * M_PI;
    CGFloat endAngle = 315.f / 180.f * M_PI;
    
    CGPoint centerA = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
    CGFloat value = ceil((sqrt(pow(radius, 2) / 2)));
    CGPoint centerB = CGPointMake(centerA.x + value, centerA.y + value);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:centerA radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [path addQuadCurveToPoint:centerB controlPoint:centerA];
    [path closePath];
    return path;
}

@end

@interface SEFloatingBallEffectView : UIView
@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) CAShapeLayer *blackLayer;
@property (weak, nonatomic) CAShapeLayer *whiteLayer;
@property (assign, nonatomic, getter=isHighlighted) BOOL highlighted;
@end
@implementation SEFloatingBallEffectView
@dynamic image;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.frame = self.bounds;
        effectView.alpha = 0.875f;
        [self addSubview:effectView];

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView = imageView];

        {   // add white border
            CAShapeLayer *borderLayer = [CAShapeLayer layer];
            borderLayer.frame = self.bounds;
            borderLayer.lineWidth = 2.f;
            borderLayer.fillColor = [UIColor clearColor].CGColor;
            borderLayer.strokeColor = [UIColor whiteColor].CGColor;
            [self.layer addSublayer:_whiteLayer = borderLayer];
        }

        {   // add black border later
            CAShapeLayer *borderLayer = [CAShapeLayer layer];
            borderLayer.frame = self.bounds;
            borderLayer.lineWidth = 0.5f;
            borderLayer.fillColor = [UIColor clearColor].CGColor;
            borderLayer.strokeColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
            [self.layer addSublayer:_blackLayer = borderLayer];
        }
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    self.imageView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
//    self.imageView.image = image;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted == highlighted) return;
    _highlighted = highlighted;
    self.imageView.backgroundColor = [UIColor colorWithWhite:highlighted ? 0.8f : 1.f alpha:0.5f];
}

- (UIImage *)image { return self.imageView.image; }

- (UIBezierPath *)updateMaskCorners:(UIRectCorner)corners {
    
    CGRect rect = self.bounds;
    CGSize size = CGSizeApplyAffineTransform(rect.size, CGAffineTransformMakeScale(0.5f, 0.5f));
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:size];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = rect;
    layer.path = path.CGPath;
    layer.fillColor = [UIColor blackColor].CGColor;
    self.layer.mask = layer;
    
    self.blackLayer.path = self.whiteLayer.path = path.CGPath;
    
    return path;
}

@end

@interface SEFloatingBall ()

@property (assign, nonatomic, getter=isHighlighted) BOOL highlighted;
@property (strong, nonatomic) CAShapeLayer *blackLayer;
@property (strong, nonatomic) CAShapeLayer *whiteLayer;
@property (strong, nonatomic) SEFloatingBallEffectView *effectView;
@property (strong, nonatomic) NSMutableArray<SEFloatingBallItem *> *iconViews;

@property (assign, nonatomic, readonly) CGFloat radius;


@end

@implementation SEFloatingBall

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        _radius = kSEFloatingBallRadius();
        _iconViews = [NSMutableArray array];
        
        [self setupUI];
        [self setupGestures];
    }
    return self;
}

#pragma mark - Override

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.layer.shadowOpacity = 1.f;
    self.effectView.highlighted = YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.layer.shadowOpacity = 0.5f;
    self.effectView.highlighted = NO;
    
    CGPoint point = [[touches anyObject] locationInView:self];
    point = [self.superview convertPoint:point fromView:self];
    if (!CGRectContainsPoint(self.frame, point)) return;
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(floatingBallDidClicked:)]) return;
    [self.delegate floatingBallDidClicked:self];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.layer.shadowOpacity = 0.5f;
}

#pragma mark - Public

- (void)reloadIconViews:(NSArray<id<SEItem>> *)items {
    
    if (self.iconViews.count < items.count) {
        for (NSUInteger i = self.iconViews.count; i < items.count; i ++) {
            SEFloatingBallItem *imageView = [[SEFloatingBallItem alloc] init];
            imageView.center = CGPointMake(CGRectGetMidX(self.floatingRect), CGRectGetMidY(self.floatingRect));
            [self addSubview:imageView];
            [self.iconViews addObject:imageView];
        }
    } else if (self.iconViews.count > items.count) {
        NSRange range = NSMakeRange(items.count, self.iconViews.count - items.count);
        NSArray<SEFloatingBallItem *> *items = [self.iconViews subarrayWithRange:range];
        [self.iconViews removeObjectsInRange:range];
        [items makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else { return; }
    
    if (self.iconViews.count <= 0) return;
    NSArray<NSDictionary *> *frames = [self.frames objectAtIndex:self.iconViews.count - 1];

    [self.iconViews enumerateObjectsUsingBlock:^(SEFloatingBallItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGRect origin = obj.frame;
        
        NSDictionary *info = [frames objectAtIndex:idx];
        obj.transform = CGAffineTransformIdentity;
        obj.frame = CGRectFromString([info objectForKey:@"frame"]);
        obj.center = CGPointFromString([info objectForKey:@"center"]);
        BOOL isRound = ![[info objectForKey:@"mask"] boolValue];
        CGFloat angle = [[info objectForKey:@"angle"] intValue] * M_PI / 180.f;
        [obj updateMaskWithAngle:angle isRound:isRound];
        obj.backgroundColor = [UIColor colorWithRed:(arc4random() % 255) / 255.f green:(arc4random() % 255) / 255.f blue:(arc4random() % 255) / 255.f alpha:1.f];

        CABasicAnimation *position = [CABasicAnimation animationWithKeyPath:@"position"];
        position.fromValue = @(CGPointMake(CGRectGetMidX(origin), CGRectGetMidY(origin)));
        position.toValue = @(CGPointMake(CGRectGetMidX(obj.frame), CGRectGetMidY(obj.frame)));
        position.duration = .25f;
        [obj.layer addAnimation:position forKey:@"position"];
        
        [SuspensionEntrance shared].iconHandler(obj, [items objectAtIndex:idx]);
    }];
}

- (NSArray<NSArray<NSDictionary *> *> *)frames {
    CGFloat const maxWidth = self.floatingRect.size.width;
    CGPoint const center = CGPointMake(CGRectGetMidX(self.floatingRect), CGRectGetMidY(self.floatingRect));
    return @[
             [self single],
             [self twoWithMaxWidth:maxWidth center:center],
             [self threeWithMaxWidth:maxWidth center:center],
             [self fourWithMaxWidth:maxWidth center:center],
             [self fiveWithMaxWidth:maxWidth center:center]
             ];
}

- (NSArray<NSDictionary *> *)single {
    return @[
             @{
                 @"frame" : NSStringFromCGRect(CGRectInset(self.bounds, 7.5f, 7.5f)),
                 @"center" : NSStringFromCGPoint(CGPointMake(CGRectGetMidX(self.floatingRect), CGRectGetMidY(self.floatingRect)))
                 }
             ];
}

- (NSArray<NSDictionary *> *)twoWithMaxWidth:(CGFloat const)maxWidth center:(CGPoint)center {
    
    CGFloat const width = (maxWidth + 4.f) / 2.f;
    CGRect const frame = CGRectMake(0, 0, width, width);
    return @[
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x - width / 2.f + 2.f, center.y)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES
                 },
             @{
                 @"frame" : NSStringFromCGRect(frame),
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x + width / 2.f - 2.f, center.y)),
                }
             ];
}

- (NSArray<NSDictionary *> *)threeWithMaxWidth:(CGFloat const)maxWidth center:(CGPoint)center {
    
    CGFloat const width = maxWidth / 2.f;
    CGRect const frame = CGRectMake(0, 0, width, width);
    return @[
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x - width / 2.f + 2.f, center.y + width / 3.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x + width / 2.f - 2.f, center.y + width / 3.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(240.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x, center.y - width / 3.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(120.f)
                 }
             ];
}

- (NSArray<NSDictionary *> *)fourWithMaxWidth:(CGFloat const)maxWidth center:(CGPoint)center {
    
    // the padding between each ball item
    CGFloat const half = 1.5f;
    CGFloat const width = (maxWidth - half * 4.f) / 2.f;
    CGRect const frame = CGRectMake(0, 0, width, width);
    return @[
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x - width/2.f - half, center.y)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(45.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x, center.y + width/2.f + half)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(315.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x + width/2.f + half, center.y)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(225.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x, center.y - width/2.f - half)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(135.f)
                 }
             ];
}

- (NSArray<NSDictionary *> *)fiveWithMaxWidth:(CGFloat const)maxWidth center:(CGPoint)center {
    
    CGFloat const half = 1.5f;
    CGFloat const width = (maxWidth - half * 4.f) / 2.f;
    CGFloat const distance = ceil(sqrt(pow(width / 2.f, 2) / 2.f) - half);
    CGRect const frame = CGRectMake(0, 0, width, width);
    return @[
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x - distance, center.y + distance)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(54.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x + width / 2.f + distance, center.y + width/2.f + distance)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(324.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x + width/2.f, center.y + half / 2.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(54.f + 180.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x, center.y - width/2.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(144.f)
                 },
             @{
                 @"center" : NSStringFromCGPoint(CGPointMake(center.x, center.y - width/2.f)),
                 @"frame" : NSStringFromCGRect(frame),
                 @"mask" : @YES,
                 @"angle" : @(144.f)
                 }
             ];
}


#pragma mark - Private

- (void)setupUI {

    NSString *rectValue = [[NSUserDefaults standardUserDefaults] stringForKey:kSEFloatingBallFrameKey];
    if (rectValue.length > 0) {
        self.frame = CGRectFromString(rectValue);
    } else {
        CGPoint origin = CGPointMake(kSEScreenWidth() - self.radius * 2.f, kSEScreenHeight() / 2.f - self.radius);
        self.frame = (CGRect){ origin, CGSizeMake(self.radius * 2.f, self.radius * 2.f) };
    }

    _effectView = [[SEFloatingBallEffectView alloc] initWithFrame:self.bounds];
    _effectView.contentMode = UIViewContentModeScaleAspectFill;
    [_effectView updateMaskCorners:self.corners];
    [self addSubview:_effectView];
    
    self.layer.shadowPath = [(CAShapeLayer *)_effectView.layer.mask path];
    self.layer.shadowColor = [UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.0].CGColor;
    self.layer.shadowOpacity = 0.5f;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 7.5f;
}

- (void)setupGestures {
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    longPress.allowableMovement = 5.f;
    longPress.delaysTouchesBegan = NO;
    [self addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.delaysTouchesBegan = NO;
    [self addGestureRecognizer:pan];
    [pan requireGestureRecognizerToFail:longPress];
}

#pragma mark - Actions

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        // pan start, record some position
        self.effectView.highlighted = YES;
        UIBezierPath *path = [self.effectView updateMaskCorners:UIRectCornerAllCorners];
        self.layer.shadowPath = path.CGPath;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        // pan changed, update self.position
        CGPoint transition = [pan translationInView:pan.view];
        CGFloat transitionX = MAX(self.radius, MIN(self.center.x + transition.x, kSEScreenWidth() - self.radius));
        CGFloat transitionY = MAX(self.radius, MIN(self.center.y + transition.y, kSEScreenHeight() - self.radius));
        self.center = CGPointMake(transitionX, transitionY);
        [pan setTranslation:CGPointZero inView:pan.view];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateChanged) {
        [self showMoveBorderAnimation];
        self.effectView.highlighted = NO;
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    
    SEL selector = NULL;
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
            self.effectView.highlighted = YES;
            selector = @selector(floatingBall:pressDidBegan:);
            break;
        case UIGestureRecognizerStateChanged:
            selector = @selector(floatingBall:pressDidChanged:);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            self.effectView.highlighted = NO;
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
        self.frame = (CGRect){ point, self.frame.size };
    } completion:^(BOOL finished) {
        UIBezierPath *path = [self.effectView updateMaskCorners:self.corners];
        self.layer.shadowPath = path.CGPath;
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGRect(self.frame) forKey:kSEFloatingBallFrameKey];
    }];
}

#pragma mark - Helpers

- (CAShapeLayer *)maskLayerWithRectCorners:(UIRectCorner)corners {
    
    CGRect rect = self.bounds;
    CGSize size = CGSizeApplyAffineTransform(rect.size, CGAffineTransformMakeScale(0.5f, 0.5f));
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:size];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = rect;
    layer.path = path.CGPath;
    layer.fillColor = [UIColor blackColor].CGColor;
    return layer;
}

#pragma mark - Setter

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.effectView.frame = self.bounds;
    [self.effectView updateMaskCorners:self.corners];
}

#pragma mark - Getter

- (BOOL)isAtLeft { return (self.center.x < kSEScreenWidth() / 2.0); }

- (UIRectCorner)corners {
    return self.isAtLeft ? (UIRectCornerBottomRight | UIRectCornerTopRight) : (UIRectCornerBottomLeft | UIRectCornerTopLeft);
}

- (CGRect)floatingRect { return CGRectInset(self.bounds, kSEFloatingBallPadding(), kSEFloatingBallPadding()); }

@end
