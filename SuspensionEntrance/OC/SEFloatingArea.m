//  SEFloatingArea.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingArea

#import "SEFloatingArea.h"
#import "SuspensionEntrance.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

const CGFloat kSEFloatingAreaWidth = 180.f;

BOOL kSEFloatAreaContainsPoint(CGPoint point) {
    CGRect bounds = UIScreen.mainScreen.bounds;
    CGPoint center = CGPointMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds));
    double dx = fabs(point.x - center.x);
    double dy = fabs(point.y - center.y);
    double distance = hypot(dx, dy);
    return  distance < kSEFloatingAreaWidth;
}

@interface SEFloatingArea ()
@property (assign, nonatomic) CGFloat multiple;
@property (copy  , nonatomic) NSString *title;
@property (assign, nonatomic) CGFloat outerRadius;
@property (assign, nonatomic) CGFloat innerRadius;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) CAShapeLayer *outerLayer;
@property (strong, nonatomic) CAShapeLayer *innerLayer;

@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSString *> *stateTitles;

@end

@implementation SEFloatingArea
@synthesize enabled = _enabled;
@synthesize highlighted = _highlighted;
#pragma mark - Life

- (instancetype)initWithFrame:(CGRect)frame {
    
    CGRect rect = CGRectMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, kSEFloatingAreaWidth, kSEFloatingAreaWidth);
    self = [super initWithFrame:rect];
    if (self) {
        
        _multiple = 0.875f;
        _outerRadius = 28.f;
        _innerRadius = 18.f;
        
        _enabled = YES;
        _highlighted = NO;
        
        _stateTitles = [@{
                          @(SEFloatingAreaStateDefault) : @"浮窗",
                          @(SEFloatingAreaStateDisabled) : @"浮窗已满"
                        } mutableCopy];
        
        [self setupUI];
        [self setupMaskLayer];
    }
    return self;
}

#pragma mark - Override

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        // reset highlighted & frame
        self.highlighted = NO;
        self.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, kSEFloatingAreaWidth, kSEFloatingAreaWidth);
    }
}

#pragma mark - Public

- (void)setTitle:(NSString *)title forState:(SEFloatingAreaState)state {
    if (title.length <= 0) return;
    [self.stateTitles setObject:title forKey:@(state)];
}

- (NSString *)titleForState:(SEFloatingAreaState)state {
    NSString *title = [self.stateTitles objectForKey:@(state)];
    if (title.length <= 0) title = [self.stateTitles objectForKey:@(SEFloatingAreaStateDefault)];
    return title;
}

#pragma mark - Private

- (void)setupUI {
    
    self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.backgroundColor = [UIColor blackColor];
    
    CGPoint center = CGPointMake(self.bounds.size.width - 10.f - self.outerRadius, self.bounds.size.height - self.outerRadius * 2.f - 10.f);

    self.outerLayer = [CAShapeLayer layer];
    self.outerLayer.borderColor = [UIColor whiteColor].CGColor;
    self.outerLayer.borderWidth = 3.f;
    self.outerLayer.cornerRadius = self.outerRadius;
    self.outerLayer.masksToBounds = YES;
    self.outerLayer.fillColor = [UIColor clearColor].CGColor;
    self.outerLayer.frame = CGRectMake(0.f, 0.f, self.outerRadius * 2.f, self.outerRadius * 2.f);
    self.outerLayer.position = center;
    [self.contentView.layer addSublayer:self.outerLayer];
    
    CGFloat const multiple = self.isHighlighted ? 1.f : self.multiple;
    self.outerLayer.affineTransform = CGAffineTransformMakeScale(multiple, multiple);

    self.innerLayer = [CAShapeLayer layer];
    self.innerLayer.borderColor = [UIColor whiteColor].CGColor;
    self.innerLayer.borderWidth = 3.f;
    self.innerLayer.frame = CGRectMake(0.f, 0.f, self.innerRadius * 2.f, self.innerRadius * 2.f);
    self.innerLayer.position = center;
    self.innerLayer.cornerRadius = self.innerRadius;
    self.innerLayer.masksToBounds = YES;
    self.innerLayer.fillColor = [UIColor clearColor].CGColor;
    [self.contentView.layer addSublayer:self.innerLayer];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.outerRadius * 2.f, 15.f)];
    textLabel.text = self.title;
    textLabel.textColor = [UIColor whiteColor];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 1;
    textLabel.font = [UIFont systemFontOfSize:12.f];
    textLabel.center = CGPointMake(center.x, center.y + self.outerRadius + 15.f);
    [self.contentView addSubview:self.titleLabel = textLabel];
}

- (void)setupMaskLayer {
    CGFloat const multiple = self.isHighlighted ? 1.f : self.multiple;
    
    CGFloat const x = (1 - multiple) * self.bounds.size.width;
    CGFloat const y = (1 - multiple) * self.bounds.size.height;
    CGFloat const width = self.bounds.size.width * multiple;
    CGFloat const height = self.bounds.size.height * multiple;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(self.bounds.size.width, y)];
    [maskPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
    [maskPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    CGPoint controlPoint1 = CGPointMake(x, y + height * 0.75);
    CGPoint controlPoint2 = CGPointMake(x + width * 0.25, y);
    [maskPath addCurveToPoint:CGPointMake(self.bounds.size.width, y) controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (void)vibrateIfNeeded {

    if (![SuspensionEntrance shared].isVibratable) return;
    
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *impactLight = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [impactLight impactOccurred];
    } else if (@available(iOS 9, *)) {
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, NULL);
    } else {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

#pragma mark - Setter

- (void)setHighlighted:(BOOL)highlighted {
    
    if (_highlighted == highlighted) return;
    _highlighted = highlighted;
   
    if (highlighted) [self vibrateIfNeeded];
    
    // update outer layer transform
    CGFloat scale = 1.f * (highlighted ? 1.f : self.multiple);
    self.outerLayer.affineTransform = CGAffineTransformMakeScale(scale, scale);
    
    // update mask
    [self setupMaskLayer];
}

- (void)setEnabled:(BOOL)enabled {
    
    _enabled = enabled;
    UIColor * const color = enabled ? [UIColor whiteColor] : [UIColor lightGrayColor];
    self.titleLabel.text = [self titleForState:enabled ? SEFloatingAreaStateDefault : SEFloatingAreaStateDisabled];
    self.titleLabel.textColor = color;
    self.innerLayer.borderColor = self.outerLayer.borderColor = color.CGColor;
    self.effect = enabled ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark] : nil;
    self.backgroundColor = enabled ? [UIColor clearColor] : [UIColor colorWithWhite:0.875f alpha:1.f];
}

#pragma mark - Getter

- (BOOL)isEnabled { return _enabled; }
- (BOOL)isHighlighted { return _highlighted; }

@end
