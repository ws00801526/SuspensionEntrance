//  SuspensionEntrance.m
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SuspensionEntrance

#import "SuspensionEntrance.h"
#import "SETransitionAnimator.h"

#import "SEFloatingBall.h"
#import "SEFloatingArea.h"
#import "SEFloatingList.h"

@interface SuspensionEntrance () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) SEFloatingBall *floatingBall;
@property (strong, nonatomic) SEFloatingArea *floatingArea;
@property (strong, nonatomic) SEFloatingList *floatingList;

@property (weak, nonatomic) __kindof UIViewController<SEItem>* tempEntranceItem;

@property (strong, nonatomic) SETransitionAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactive;

@property (strong, nonatomic, readonly)  NSMutableSet<Class> *monitorClasses;
@property (strong, nonatomic, readonly)  NSMutableSet<NSString *> *panGestureKeys;
@property (strong, nonatomic, readwrite) NSMutableArray<id<SEItem>> *items;

@property (strong, nonatomic, readonly)  UINavigationController *navigationController;

@end

@interface UIViewController (SEPrivate)
@property (assign, nonatomic, readonly) BOOL se_isEntrance;
@property (assign, nonatomic, readonly) BOOL se_canBeEntrance;
@end

@implementation UIViewController (SEPrivate)

- (BOOL)se_canBeEntrance {
    if (![self conformsToProtocol:@protocol(SEItem)]) return NO;
    return [[SuspensionEntrance shared].monitorClasses containsObject:[self class]];
}

- (BOOL)se_isEntrance {
    if (!self.se_canBeEntrance) return NO;
    return [[SuspensionEntrance shared].items containsObject:(id<SEItem>)self];
}

@end

@implementation SuspensionEntrance

#pragma mark - Life

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _maxCount = 5;
        _vibratable = YES;
        
        _items = [NSMutableArray array];
        _monitorClasses = [NSMutableSet set];
        _panGestureKeys = [NSMutableSet set];

        _floatingBall = [[SEFloatingBall alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _floatingBall.delegate = (id<SEFloatingBallDelegate>)self;
        
        _floatingArea = [[SEFloatingArea alloc] initWithFrame:CGRectZero];
        
//        _floatingList = [[SEFloatingList alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _floatingList = [[SEFloatingList alloc] initWithFrame:CGRectZero];
        _floatingList.delegate = (id<SEFloatingListDelegate>)self;
    }
    return self;
}

#pragma mark - Public


#pragma mark - Private

- (BOOL)isEntranceViewController:(__kindof UIViewController *)viewController {
    if (!viewController) return NO;
    if (![viewController conformsToProtocol:@protocol(SEItem)]) { return NO; }
    
    for (id<SEItem> item in self.items) {
        if (item == viewController) return YES;
        if ([item.entranceUrl isEqual:[(id<SEItem>)viewController entranceUrl]]) return YES;
    }
    return NO;
}

- (UIPanGestureRecognizer *)panGestureOfController:(__kindof UINavigationController *)controller {
    for (NSString *key in self.panGestureKeys) {
        if ([controller valueForKey:key]) { return [controller valueForKey:key]; }
    }
    return nil;
}

#pragma mark - Actions

- (void)handleTransition:(UIScreenEdgePanGestureRecognizer *)pan {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height;
    UIViewController<SEItem> *tempItem = (UIViewController<SEItem> *)pan.view.nextResponder;
    
    switch (pan.state) {
            
        case UIGestureRecognizerStateBegan:
            self.interactive = [[UIPercentDrivenInteractiveTransition alloc] init];
            [tempItem.navigationController popViewControllerAnimated:YES];
            
            if (tempItem.se_isEntrance) [self.floatingArea removeFromSuperview];
            else if (!self.floatingArea.superview) [self.window addSubview:self.floatingArea];
            self.floatingArea.enabled = self.items.count < self.maxCount;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint tPoint = [pan translationInView:self.window];
            CGFloat x = MAX(SCREEN_WIDTH - tPoint.x + kSEFloatingAreaWidth / 2.f, SCREEN_WIDTH - kSEFloatingAreaWidth);
            CGFloat y = MAX(SCREEN_HEIGHT - tPoint.x + kSEFloatingAreaWidth / 2.f, SCREEN_HEIGHT - kSEFloatingAreaWidth);
            self.floatingArea.frame = (CGRect){ CGPointMake(x, y), self.floatingArea.bounds.size };
            
            CGPoint innerPoint = [pan locationInView:self.window];
            self.floatingArea.highlighted = kSEFloatAreaContainsPoint(innerPoint);
            
            [self.animator updateContinousPopAnimationPercent:tPoint.x / SCREEN_WIDTH];
            [self.interactive updateInteractiveTransition:tPoint.x / SCREEN_WIDTH];
        }
            break;
        case UIGestureRecognizerStateEnded:     // fall through
        case UIGestureRecognizerStateCancelled:
        {
            CGPoint point = [pan locationInView:self.window];
            CGPoint vPoint = [pan velocityInView:self.window];
            CGFloat vPointX = vPoint.x * [self.animator animationDuration];
            // 判断快速滑动是否超过屏幕1/2
            if (fmax(vPointX, point.x) >= SCREEN_WIDTH / 2.f) {
                if (self.floatingArea.superview && self.floatingArea.isHighlighted) {
                    if (self.floatingArea.isEnabled) {
                        // floating is available
                        NSLog(@"floating is available");
                        if (!self.floatingBall.superview) { [self.window addSubview:self.floatingBall]; }
                        if (![self.items containsObject:tempItem]) { [self->_items addObject:tempItem]; }
                        [self.animator finishContinousPopAnimation];
                        [self.interactive finishInteractiveTransition];
                        [self.floatingList reloadData];
                    } else {
                        // floating is full
                        NSLog(@"floating is full");
                        [self.animator cancelContinousPopAnimation];
                        [self.interactive cancelInteractiveTransition];
                    }
                } else if (tempItem.se_isEntrance) {
                    // just ended
                    NSLog(@"floating is entrance state");
                    [self.animator finishContinousPopAnimation];
                    [self.interactive finishInteractiveTransition];
                } else {
                    // just ended
                    NSLog(@"floating is normal state");
                    [self.animator finishContinousPopAnimationWithFastAnimating:YES];
                    [self.interactive finishInteractiveTransition];
                }
            } else {
                [self.animator cancelContinousPopAnimation];
                [self.interactive cancelInteractiveTransition];
            }
            [self.floatingArea removeFromSuperview];
            self.interactive = nil;
        }
            break;
        default: break;
    }
}

#pragma mark - SEFloatingBallDelegate

- (void)floatingBallDidClicked:(SEFloatingBall *)floatingBall {
    // will show floating list
    self.floatingList.editable = YES;
    if (!self.floatingList.superview) [self.window addSubview:self.floatingList];
    [self.floatingList showAtRect:floatingBall.frame animated:YES];
}

- (void)floatingBall:(SEFloatingBall *)floatingBall pressDidBegan:(UILongPressGestureRecognizer *)gesture {
    // will show floating list
    self.floatingList.editable = NO;
    if (!self.floatingList.superview) [self.window addSubview:self.floatingList];
    [self.floatingList showAtRect:floatingBall.frame animated:YES];
}

- (void)floatingBall:(SEFloatingBall *)floatingBall pressDidChanged:(UILongPressGestureRecognizer *)gesture {
    // will highlight the item in floating list
    CGPoint point = [gesture locationInView:gesture.view];
    point = [self.floatingList convertPoint:point fromView:gesture.view];
    for (SEFloatingListItem *listItem in self.floatingList.listItems) {
        listItem.highlighted = CGRectContainsPoint(listItem.frame, point);
    }
}

- (void)floatingBall:(SEFloatingBall *)floatingBall pressDidEnded:(UILongPressGestureRecognizer *)gesture {
    // will end, check floating list is selected
    for (SEFloatingListItem *listItem in self.floatingList.listItems) {
        if (listItem.isHighlighted) {
            if ([self.items containsObject:listItem.item])
                [self.navigationController pushViewController:(UIViewController *)listItem.item animated:YES];
            break;
        }
    }
    [self.floatingList dismissWithAnimated:YES];
}

#pragma mark - SEFloatingListDelegate

- (NSUInteger)numberOfItemsInFloatingList:(SEFloatingList *)list {
    return self.items.count;
}

- (id<SEItem>)floatingList:(SEFloatingList *)list itemAtIndex:(NSUInteger)index {
    return [self.items objectAtIndex:index];
}

- (void)floatingList:(SEFloatingList *)list didSelectItem:(id<SEItem>)item {
    if ([self.items containsObject:item]) [self.navigationController pushViewController:(UIViewController *)item animated:YES];
}

- (BOOL)floatingList:(SEFloatingList *)list willDeleteItem:(id<SEItem>)item {
    if (![self.items containsObject:item]) return NO;
    [self->_items removeObject:item];
    return YES;
}

- (void)floatingListWillShow:(SEFloatingList *)list {
    [UIView animateWithDuration:0.25 animations:^{ self.floatingBall.alpha = .0f; }];
}

- (void)floatingListWillHide:(SEFloatingList *)list {
    [UIView animateWithDuration:0.25 animations:^{ self.floatingBall.alpha = 1.0f; }];
}

#pragma mark - Getter

- (UIWindow *)window { return _window ? : [UIApplication sharedApplication].keyWindow; }

- (UINavigationController *)navigationController {
    
    __kindof UIViewController *controller = self.window.rootViewController;
    if ([controller isKindOfClass:[UITabBarController class]]) { controller = [(UITabBarController *)controller selectedViewController]; }
    while (controller.presentedViewController) { controller = controller.presentedViewController; }

    if ([controller isKindOfClass:[UINavigationController class]]) return controller;
    if (controller.navigationController) return controller.navigationController;
    
    while (controller.presentingViewController) {
        controller = controller.presentingViewController;
        if ([controller isKindOfClass:[UINavigationController class]] || controller.navigationController) break;
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) return controller;
    if (controller.navigationController) return controller.navigationController;
    
    return nil;
}

#pragma mark - Class

+ (instancetype)shared {
    static SuspensionEntrance *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone { return [SuspensionEntrance shared]; }

+ (void)registerMonitorClass:(Class)clazz {
    if (!clazz) return;
    [[SuspensionEntrance shared].monitorClasses addObject:clazz];
}

+ (void)registerPanGestureKey:(NSString *)key {
    if (key.length <= 0) return;
    [[SuspensionEntrance shared].panGestureKeys addObject:key];
}

@end

@implementation SuspensionEntrance (NavigationControllerDelegate)

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    NSLog(@"did show controller :%@", viewController);
    
    self.animator = nil;
    self.interactive = nil;
    
    if (navigationController.viewControllers.count <= 1) return;
    
    if (![viewController se_canBeEntrance]) return;
    
    UIScreenEdgePanGestureRecognizer *pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTransition:)];
    pan.edges = UIRectEdgeLeft;
    pan.delegate = self;
    [viewController.view addGestureRecognizer:pan];
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {

    return self.interactive;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    CGPoint const center = self.floatingBall.center;
    CGFloat const radius = self.floatingBall.bounds.size.height / 2.f;
    NSLog(@"will decide animation controller for operation :%@ -- %@", fromVC, toVC);
    if (operation == UINavigationControllerOperationPop) {
        
        if (self.interactive) {
            self.animator = [SETransitionAnimator continuousPopAnimatorWithCenter:center radius:radius];
        } else {
//            if (isFromVCEntrance) {
            if (fromVC.se_isEntrance) {
                self.animator = [SETransitionAnimator roundPopAnimatorWithCenter:center radius:radius];
            } else {
                self.animator = nil;
            }
        }
    } else if (operation == UINavigationControllerOperationPush) {
        
        if (toVC.se_isEntrance && fromVC.se_isEntrance) {
            // need update animation
            self.animator = [SETransitionAnimator replaceAnimatorWithCenter:center radius:radius];
        } else if (toVC.se_isEntrance && !fromVC.se_isEntrance) {
            // need round animation
            self.animator = [SETransitionAnimator roundPushAnimatorWithCenter:center radius:radius];
        }
    }
    return self.animator;
}

@end
