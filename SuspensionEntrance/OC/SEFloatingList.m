//  SEFloatingList.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/13
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingList

#import "SEFloatingList.h"
#import "SuspensionEntrance.h"

static CGFloat const kSEFloatingListItemHeight = 56.0f;

@interface SEFloatingListItem ()

@property (weak, nonatomic) id<SEItem> item;
@property (weak, nonatomic) UIImageView *iconView;
@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) UIButton *deleteButton;
@property (assign, nonatomic, getter=isEditable) BOOL editable;
@property (assign, nonatomic) UIRectCorner corners;

@property (strong, nonatomic) CAShapeLayer *backgroundLayer;

@end

@interface SEFloatingList ()
@property (weak, nonatomic) SEFloatingListItem *tempItem;
@property (strong, nonatomic) NSMutableArray<SEFloatingListItem *> *visibleItems;
@end

@implementation SEFloatingListItem
@synthesize selected = _selected;
@synthesize highlighted = _highlighted;

- (instancetype)initWithItem:(id<SEItem>)item {
    
    CGFloat const padding = 10.f;
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGRect const frame = CGRectMake(0, 0, SCREEN_WIDTH * 2.f / 3.f, kSEFloatingListItemHeight);
    if (self = [super initWithFrame:frame]) {
        
        _item = item;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        iconView.center = CGPointMake(padding + 35.f / 2.f, kSEFloatingListItemHeight / 2.f);
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:iconView.bounds cornerRadius:17.5f].CGPath;
        iconView.layer.mask = maskLayer;
        [self addSubview:_iconView = iconView];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.f, 10.5, frame.size.width - 55.f - padding - 50.f, 35.0)];
        titleLabel.numberOfLines = 2;
        titleLabel.textColor = [UIColor colorWithRed:0.21 green:0.21 blue:0.21 alpha:1.f];
        if (@available(iOS 8.0, *)) titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        else titleLabel.font = [UIFont systemFontOfSize:14.0];
        titleLabel.text = item.entranceTitle ? : @" ";
        [self addSubview:_titleLabel = titleLabel];
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.frame = CGRectMake(frame.size.width - 60.f, 0.0f, 60.f, kSEFloatingListItemHeight);
//        [deleteButton setTitle:@"x" forState:UIControlStateNormal];
//        [deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [deleteButton setImage:[SuspensionEntrance shared].closePlaceholder ? : [UIImage imageNamed:@"web_entrance_close"] forState:UIControlStateNormal];
        [self addSubview:_deleteButton = deleteButton];

        self.layer.shadowColor = [UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.0].CGColor;
        self.layer.shadowOpacity = 1.f;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 7.5f;
        
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.fillColor = [UIColor whiteColor].CGColor;
        _backgroundLayer.frame = self.bounds;
        [self.layer insertSublayer:self.backgroundLayer atIndex:0];
        
        [SuspensionEntrance shared].iconHandler(iconView, item);
    }
    return self;
}

- (void)setCorners:(UIRectCorner)corners {
    
    _corners = corners;
    if (corners == UIRectEdgeNone) {
        self.layer.mask = nil;
        self.layer.shadowPath = nil;
        self.backgroundLayer.path = nil;
    } else {
        CGSize size = CGSizeApplyAffineTransform(self.bounds.size, CGAffineTransformMakeScale(0.5f, 0.5f));
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:size];
        self.layer.shadowPath = path.CGPath;
        self.backgroundLayer.path = path.CGPath;
    }
}

- (void)setEditable:(BOOL)editable {
    self.deleteButton.hidden = !editable;
}

- (void)setSelected:(BOOL)selected {
    if (_selected == selected) return;
    _selected = selected;
    CGFloat scale = selected ? 1.1f : 1.f;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)setHighlighted:(BOOL)highlighted {
    
    if (_highlighted == highlighted) return;
    _highlighted = highlighted;
    UIColor *color = highlighted ? [UIColor colorWithWhite:0.75 alpha:1.f] : [UIColor whiteColor];
    self.backgroundLayer.fillColor = color.CGColor;
}

#pragma mark - Getter

- (BOOL)isSelected { return _selected; }
- (BOOL)isHighlighted { return _highlighted; }
- (BOOL)isEditable { return !self.deleteButton.isHidden; }

@end

@implementation SEFloatingList

#pragma mark - Life

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:(CGRect){ CGPointZero, UIScreen.mainScreen.bounds.size }];
    if (self) {
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.frame = self.bounds;
        [self addSubview:effectView];
    }
    return self;
}

#pragma mark - Override

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [super touchesBegan:touches withEvent:event];
    CGPoint point = [[touches anyObject] locationInView:self];
    for (SEFloatingListItem *subView in self.listItems) {
        if (CGRectContainsPoint(subView.frame, point)) {
            self.tempItem = subView;
            self.tempItem.highlighted = YES;
            break;
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesEnded:touches withEvent:event];
    BOOL animated = YES;
    if (self.tempItem.highlighted) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(floatingList:didSelectItem:)]) {
            animated = NO;
            [self.delegate floatingList:self didSelectItem:self.tempItem.item];
        }
    }
    [self dismissWithAnimated:animated];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
 
    [super touchesMoved:touches withEvent:event];
    CGPoint point = [[touches anyObject] locationInView:self];
    if (self.tempItem) self.tempItem.highlighted = CGRectContainsPoint(self.tempItem.frame, point);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.tempItem = nil;
}

#pragma mark - Public

- (void)reloadData {
    
    if (self.delegate == nil) return;
    
    [self.listItems makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSUInteger count = [self.delegate numberOfItemsInFloatingList:self];
    for (int i = 0; i < count; i ++) {
        id<SEItem> item = [self.delegate floatingList:self itemAtIndex:i];
        SEFloatingListItem *listItem = [[SEFloatingListItem alloc] initWithItem:item];
        [listItem.deleteButton addTarget:self action:@selector(handleDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:listItem];
    }
}

- (void)showAtRect:(CGRect)rect animated:(BOOL)animated {

    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safeAreaInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom;
    
    NSArray<SEFloatingListItem *> *visibleListItems = [self.visibleItems copy];
    
    CGFloat const padding = 15.f;
    CGFloat const itemHeight = (padding + kSEFloatingListItemHeight);
    CGFloat height = visibleListItems.count * itemHeight;
    BOOL inLeft = rect.origin.x <= (SCREEN_WIDTH / 2.f);
    BOOL inBottom = (rect.origin.y + height < SCREEN_HEIGHT);
    BOOL isEnough = inBottom ? ( CGRectGetMaxY(rect) + height + safeAreaInsets.bottom < SCREEN_HEIGHT ) : (rect.origin.y > (height + safeAreaInsets.top));
    
    CGFloat x = inLeft ? 0.f : (SCREEN_WIDTH / 3.f);
    CGFloat y = inBottom ? (rect.origin.y + rect.size.height + padding) : (rect.origin.y - itemHeight);
    if (!isEnough) { y = inBottom ? SCREEN_HEIGHT + safeAreaInsets.top - kSEFloatingListItemHeight - 5.f : safeAreaInsets.top; }
    
    if (!isEnough) visibleListItems = [[[visibleListItems reverseObjectEnumerator] allObjects] mutableCopy];
    
    NSUInteger idx = 0;
    for (SEFloatingListItem *itemView in self.listItems) {

        itemView.alpha = .0f;
        itemView.selected = NO;
        itemView.highlighted = NO;
        itemView.frame = (CGRect) { CGPointMake(inLeft ? -itemView.frame.size.width : SCREEN_WIDTH, y), itemView.frame.size };
        itemView.corners = inLeft ? (UIRectCornerTopRight | UIRectCornerBottomRight) : (UIRectCornerTopLeft | UIRectCornerBottomLeft);
        
        if (![visibleListItems containsObject:itemView]) continue;
        
        [UIView animateWithDuration:0.15 delay:idx * 0.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            itemView.alpha = 1.0f;
            itemView.frame = (CGRect){ CGPointMake(x, y), itemView.frame.size };
        } completion:NULL];
        
        idx += 1;
        if (((inBottom && isEnough) || (!inBottom && !isEnough))) { y += itemHeight; }
        else { y-= itemHeight; }
    }
    
    self.alpha = 0.3f;
    [UIView animateWithDuration:0.25 animations:^ { self.alpha = 1.f; }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingListWillShow:)])
        [self.delegate floatingListWillShow:self];
}

- (void)dismissWithAnimated:(BOOL)animated {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;

    NSArray<SEFloatingListItem *> *visibleItems = self.visibleItems;
    for (SEFloatingListItem *itemView in visibleItems) {
        NSUInteger const idx = [visibleItems indexOfObject:itemView];
        BOOL inLeft = (itemView.frame.origin.x <= 0.f);
        CGFloat const x = ((inLeft ? itemView.frame.size.width : SCREEN_WIDTH) + 30.f) * (inLeft ? -1.f : 1.f);
        [UIView animateWithDuration:animated ? .15f : CGFLOAT_MIN delay:idx * 0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            itemView.frame = (CGRect){ CGPointMake(x, itemView.frame.origin.y), itemView.frame.size };
        } completion:NULL];
    }

    [UIView animateWithDuration:animated ? .25f : CGFLOAT_MIN animations:^ { self.alpha = 0.f; } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingListWillHide:)])
        [self.delegate floatingListWillHide:self];
}

#pragma mark - Private

- (NSArray<SEFloatingListItem *> *)visibleItems {
    
    NSMutableArray<SEFloatingListItem *> *listItems = [self.listItems mutableCopy];
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingList:isItemVisible:)]) {
        for (SEFloatingListItem *listItem in self.listItems) {
            if (![self.delegate floatingList:self isItemVisible:listItem.item]) { [listItems removeObject:listItem]; }
        }
    }
    return [listItems copy];
}

#pragma mark - Actions

- (void)handleDeleteAction:(UIButton *)button {
    
    SEFloatingListItem *listItem = (SEFloatingListItem *)button.superview;
    if (!listItem || ![listItem isKindOfClass:[SEFloatingListItem class]]) return;
    if (!listItem.item) return;
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(floatingList:willDeleteItem:)]) return;
    
    if (![self.delegate floatingList:self willDeleteItem:listItem.item]) return;
    // TODO: success delete list item, need reset position of other list items
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    BOOL inLeft = (listItem.frame.origin.x <= 0.f);
    CGFloat const x = ((inLeft ? listItem.frame.size.width : SCREEN_WIDTH) + 30.f) * (inLeft ? -1.f : 1.f);
    
    
    __block CGRect currentRect = listItem.frame;
    [UIView animateWithDuration:0.15f animations:^{
        listItem.frame = (CGRect){ CGPointMake(x, listItem.frame.origin.y), listItem.frame.size};
    } completion:^(BOOL finished) {
        [listItem removeFromSuperview];
    }];

    if (self.visibleItems.count <= 1) {
        [self dismissWithAnimated:YES];
        return;
    }
    
    NSUInteger const currendIdx = [self.visibleItems indexOfObject:listItem];
    for (SEFloatingListItem *tempItem in self.visibleItems) {
        NSUInteger const idx = [self.visibleItems indexOfObject:tempItem];
        if (idx <= currendIdx) { continue; }
        CGRect const tempRect = tempItem.frame;
        [UIView animateWithDuration:0.15f animations:^{
            tempItem.frame = currentRect;
        }];
        currentRect = tempRect;
    }
}

#pragma mark - Setter

//- (void)setDelegate:(id<SEFloatingListDelegate>)delegate {
//    _delegate = delegate;
//    [self reloadData];
//}

- (void)setEditable:(BOOL)editable {
    _editable = editable;
    for (SEFloatingListItem *itemView in self.listItems) { itemView.editable = editable; }
}

#pragma mark - Getter

- (NSArray<SEFloatingListItem *> *)listItems {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  obj, NSDictionary *bindings) {
        return [obj isKindOfClass:[SEFloatingListItem class]];
    }];
    return (NSArray<SEFloatingListItem *> *)[self.subviews filteredArrayUsingPredicate:predicate];
}

- (CGRect)floatingRect {

    for (SEFloatingListItem *listItem in self.listItems) {
        if (listItem.isSelected) return listItem.frame;
        if (listItem.isHighlighted) return listItem.frame;
    }
    return CGRectZero;
}

@end
