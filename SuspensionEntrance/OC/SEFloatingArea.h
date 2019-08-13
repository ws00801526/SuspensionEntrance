//  SEFloatingArea.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/9
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingArea

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const CGFloat kSEFloatingAreaWidth;
FOUNDATION_EXPORT BOOL kSEFloatAreaContainsPoint(CGPoint point);

typedef NS_ENUM(NSUInteger, SEFloatingAreaState) {
    SEFloatingAreaStateDefault,
    SEFloatingAreaStateHighlight,
    SEFloatingAreaStateDisabled,
};

@interface SEFloatingArea : UIVisualEffectView

@property (assign, nonatomic, getter=isEnabled) BOOL enabled;
@property (assign, nonatomic, getter=isHighlighted) BOOL highlighted;

- (NSString *)titleForState:(SEFloatingAreaState)state;
- (void)setTitle:(NSString *)title forState:(SEFloatingAreaState)state;

@end

NS_ASSUME_NONNULL_END
