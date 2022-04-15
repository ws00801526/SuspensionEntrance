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

#import <objc/runtime.h>


static NSString *const kSEItemClassKey = @"class";
static NSString *const kSEItemTitleKey = @"title";
static NSString *const kSEItemIconUrlKey = @"iconUrl";
static NSString *const kSEItemUserInfoKey = @"userInfo";

@interface SuspensionEntrance () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) SEFloatingBall *floatingBall;
@property (strong, nonatomic) SEFloatingArea *floatingArea;
@property (strong, nonatomic) SEFloatingList *floatingList;

@property (strong, nonatomic) SETransitionAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactive;

@property (strong, nonatomic, readwrite) NSMutableSet<Class> *ignoredClasses;
@property (strong, nonatomic, readwrite) NSMutableSet<Class> *disabledClasses;
@property (strong, nonatomic, readwrite) NSMutableArray<UIViewController<SEItem> *> *items;
@property (strong, nonatomic, readonly)  NSArray<UIViewController<SEItem> *> *unusedItems;
@property (strong, nonatomic, readonly)  UINavigationController *navigationController;

- (void)handleKeyboardWillShow:(NSNotification *)note;
- (void)handleKeyboardWillHide:(NSNotification *)note;
@end

@interface UIViewController (SEPrivate)
@property (assign, nonatomic, readonly) BOOL se_isUsed;
@property (assign, nonatomic, readonly) BOOL se_isEntrance;
@property (assign, nonatomic, readonly) BOOL se_canBeEntrance;
@end

@implementation UIViewController (SEPrivate)

- (BOOL)se_isUsed {
    if (!self.se_isEntrance) return false;
    NSInteger index = [[self.navigationController viewControllers] indexOfObject:self];
    if (index == NSNotFound) return false;
    // !!!: first index should'd be entrance. fix bug while set viewControllers contains the removed controller on iOS14.
    return self.presentingViewController || index != 0;
}

- (BOOL)se_canBeEntrance {
    return [[self class] conformsToProtocol:@protocol(SEItem)];
}

- (BOOL)se_isEntrance {
    if (!self.se_canBeEntrance) return NO;
    return [[SuspensionEntrance shared].items containsObject:(UIViewController<SEItem> *)self];
}

@end

@interface NSDictionary (SEPrivate) <SEItem>
@end

@implementation NSDictionary (SEPrivate)
@dynamic entranceTitle;
@dynamic entranceIconUrl;
@dynamic entranceUserInfo;

- (Class)entranceClass {
    
    NSString *clazz = [self objectForKey:kSEItemClassKey];
    if (clazz.length <= 0) return NULL;
    return NSClassFromString(clazz);
}

- (NSString *)entranceTitle { return [self objectForKey:kSEItemTitleKey]; }
- (NSURL *)entranceIconUrl  { return [self objectForKey:kSEItemIconUrlKey]; }
- (NSDictionary *)entranceUserInfo { return [self objectForKey:kSEItemUserInfoKey]; }

@end

#import <objc/runtime.h>
static NSString *const kSEItemIconTask;

@implementation UIImageView (SEPrivate)

- (void)se_setImageWithItem:(id<SEItem>)item {
    
    NSURLSessionDataTask *task = objc_getAssociatedObject(self, &kSEItemIconTask);
    if (task && [task.originalRequest.URL isEqual:item.entranceIconUrl]) { return; }
    if (task) [task cancel];

    __weak typeof(self) wSelf = self;
    self.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.f];
    task = [[NSURLSession sharedSession] dataTaskWithURL:item.entranceIconUrl completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) return;
        UIImage *image = [UIImage imageWithData:data scale:2.f];
        if (!image) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(wSelf) self = wSelf;
            self.image = image;
            self.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.f];
        });
    }];
    [task resume];
    objc_setAssociatedObject(self, &kSEItemIconTask, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (Private)

- (void)se_viewWillAppear:(BOOL)animated {
    
    [self se_viewWillAppear:animated];
    
    SuspensionEntrance *entrance = [SuspensionEntrance shared];
    if (!entrance.isAvailable || entrance.interactive) return;
    if ([entrance.ignoredClasses containsObject:[self class]]) return;
    if ([NSStringFromClass([self class]) containsString:@"JXSegmentedView"]) return;
    
    UITabBarController *vc = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([vc isKindOfClass:[UITabBarController class]]) {
        vc = [vc selectedViewController];
        if ([vc isKindOfClass:[UINavigationController class]]) vc = [(UINavigationController *)vc visibleViewController];
        if (vc == self) return;
    }
    
    BOOL visible = entrance.isAvailable && entrance.floatingBall.superview && (entrance.unusedItems.count >= 1);
    if (self.presentingViewController != nil || self.navigationController == nil) visible = NO;
    if ([entrance.disabledClasses containsObject:[self class]]) visible = NO;
    if (visible) {
        if (entrance.floatingBall.alpha < 1.f) [UIView animateWithDuration:0.25f animations:^{ entrance.floatingBall.alpha = 1.f; }];
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) [entrance.floatingBall.superview bringSubviewToFront:entrance.floatingBall];
#endif
    } else { entrance.floatingBall.alpha = .0f; }
}

@end

@implementation SuspensionEntrance
@synthesize window = _window;

#pragma mark - Life

+ (void)initialize {
    if (self == [SuspensionEntrance class]) {
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(se_viewWillAppear:);
        Method originalMethod = class_getInstanceMethod([UIViewController class], originalSelector);
        Method swizzledMethod = class_getInstanceMethod([UIViewController class], swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _maxCount = 5;
        _vibratable = YES;
        _available = YES;
        
        _items = [NSMutableArray array];
        _ignoredClasses = [NSMutableSet set];
        _disabledClasses = [NSMutableSet set];
        _archivedPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"entrance.items"];

        _floatingBall = [[SEFloatingBall alloc] initWithFrame:CGRectZero];
        _floatingBall.delegate = (id<SEFloatingBallDelegate>)self;
        
        _floatingArea = [[SEFloatingArea alloc] initWithFrame:CGRectZero];
        
        _floatingList = [[SEFloatingList alloc] initWithFrame:CGRectZero];
        _floatingList.delegate = (id<SEFloatingListDelegate>)self;
        
        _iconHandler = ^(UIImageView *iconView, id<SEItem> item) {
            [iconView se_setImageWithItem:item];
        };
        
        // register keyboard notification to hide floating ball
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }

    // need to get in next main loop, otherwise self.window may be nil
    dispatch_async(dispatch_get_main_queue(), ^ { [self unarchiveEntranceItems]; });
    return self;
}

#pragma mark - Public

- (BOOL)isEntranceItem:(__kindof UIViewController *)item {
    
    if (![item conformsToProtocol:@protocol(SEItem)]) return NO;
    return [self.items containsObject:(UIViewController<SEItem> *)item];
}

- (void)addEntranceItem:(__kindof UIViewController<SEItem> *)item {
    
    if ([self isEntranceItem:item]) return;
    if (self->_items.count >= self.maxCount) {
        [self showItemsFullAlert];
        return;
    }
    [self->_items addObject:item];
    [self.floatingBall reloadIconViews:self.items];
    [self.floatingList reloadData];
    [self archiveEntranceItems];
    // !!! Fixed: add first entrance item, the floating ball doesnot has superview
    if (self.floatingBall.superview == nil) { [self.window addSubview:self.floatingBall]; self.floatingBall.alpha = 1.f; }
    if (self.navigationController.viewControllers.lastObject == item)
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelEntranceItem:(__kindof UIViewController<SEItem> *)item {
    
    if (![self isEntranceItem:item]) return;
    [self->_items removeObject:item];
    [self.floatingBall reloadIconViews:self.items];
    [self.floatingList reloadData];
    [self archiveEntranceItems];
}

- (void)clearEntranceItems {
    [self->_items removeAllObjects];
    [self.floatingBall reloadIconViews:self.items];
    [self.floatingList reloadData];
    [self.floatingBall removeFromSuperview];
    [[NSFileManager defaultManager] removeItemAtPath:self.archivedPath error:nil];
}

#pragma mark - Private

- (void)pushEntranceItem:(UIViewController<SEItem> *)item {

    if (![self.items containsObject:item]) return;
    if ([item isKindOfClass:[UINavigationController class]]) {
        [self.navigationController presentViewController:item animated:YES completion:NULL];
    } else {
        NSMutableArray<UIViewController *> *viewControllers = [self.navigationController.viewControllers mutableCopy];
        if ([viewControllers containsObject:item]) {
            [self.navigationController popToViewController:item animated:YES];
        } else {
            if (viewControllers.lastObject.se_isEntrance) { [viewControllers removeLastObject]; }
            [viewControllers addObject:item];
            [self.navigationController setViewControllers:[viewControllers copy] animated:YES];
        }
    }
}

- (CGRect)floatingRectOfOperation:(UINavigationControllerOperation)operation {
    CGRect rect = CGRectZero;
    switch (operation) {
        case UINavigationControllerOperationPush:
            rect = [self.window convertRect:self.floatingList.floatingRect fromView:self.floatingList];
            break;
        case UINavigationControllerOperationPop:
            rect = [self.window convertRect:self.floatingBall.floatingRect fromView:self.floatingBall];
            break;
        default: break;
    }
    if (CGRectIsEmpty(rect)) rect = self.floatingBall.frame;
    return rect;
}

- (void)showItemsFullAlert {
    
    NSString *message = [NSString stringWithFormat:@"最多设置%d个浮窗", (int)self.maxCount];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) wSelf = self;
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(wSelf) self = wSelf;
        [self handleKeyboardWillHide:nil];
    }];
    [alert addAction:confirm];
    [self.navigationController.visibleViewController showDetailViewController:alert sender:nil];
}

- (void)archiveEntranceItems {
    
    NSMutableArray *infos = [NSMutableArray array];
    for (UIViewController<SEItem> *item in self.items) {
        [infos addObject:@{
                           kSEItemClassKey : NSStringFromClass(item.class),
                           kSEItemTitleKey : item.entranceTitle ? : @"",
                           kSEItemIconUrlKey : item.entranceIconUrl ? : [NSURL URLWithString:@""],
                           kSEItemUserInfoKey : item.entranceUserInfo ? : @{}
                           }];
    }
    
#if DEBUG
    BOOL succ = [NSKeyedArchiver archiveRootObject:infos toFile:self.archivedPath];
    if (!succ) { NSLog(@"archive entrance items failed :%@", self.archivedPath); }
#else
    [NSKeyedArchiver archiveRootObject:infos toFile:self.archivedPath];
#endif
}

- (void)unarchiveEntranceItems {
    
    NSArray<NSDictionary *> *infos = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archivedPath];
    if (infos.count <= 0) return;
    
    for (NSDictionary *info in infos) {

        if (info.entranceClass == NULL) continue;
        if (info.entranceTitle.length <= 0) continue;
        if (![info.entranceClass respondsToSelector:@selector(entranceWithItem:)]) continue;
        
        UIViewController<SEItem> *item = [info.entranceClass entranceWithItem:info];
        if (!item || ![item isKindOfClass:[UIViewController class]]) continue;
        
        [self->_items addObject:item];
    }
    
    [self.floatingList reloadData];
    [self.floatingBall reloadIconViews:self.items];
    if (self.items.count <= 0 || !self.isAvailable) { [self.floatingBall removeFromSuperview]; }
    else if (!self.floatingBall.superview) { self.floatingBall.alpha = 1.f; [self.window addSubview:self.floatingBall]; }
    else { self.floatingBall.alpha = 1.f; [self.window bringSubviewToFront:self.floatingBall]; }
}

- (void)handleKeyboardWillShow:(NSNotification *)note {
    
    BOOL visible = self.floatingBall.superview && self.floatingBall.alpha >= 1.f;
    if (!visible) return;
    [UIView animateWithDuration:.25f animations:^ { self.floatingBall.alpha = .0f; }];
}

- (void)handleKeyboardWillHide:(NSNotification *)note {
    
    BOOL visible = self.floatingBall.superview && self.unusedItems.count >= 1;
    if (!visible || self.floatingBall.alpha >= 1.f) return;
    [UIView animateWithDuration:.25f animations:^ { self.floatingBall.alpha = 1.0f; }];
}

#pragma mark - Actions

- (void)handleTransition:(UIScreenEdgePanGestureRecognizer *)pan {
    
    CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
    CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height;
    UIViewController<SEItem> *tempItem = (UIViewController<SEItem> *)pan.view.nextResponder;
    BOOL isPresented = tempItem.presentingViewController != nil;
    switch (pan.state) {
            
        case UIGestureRecognizerStateBegan:
            self.interactive = [[UIPercentDrivenInteractiveTransition alloc] init];
            if (isPresented) [tempItem dismissViewControllerAnimated:YES completion:NULL];
            else [tempItem.navigationController popViewControllerAnimated:YES];
            if (tempItem.se_isEntrance) [self.floatingArea removeFromSuperview];
            else if (!self.floatingArea.superview && self.isAvailable) [self.window addSubview:self.floatingArea];
            self.floatingArea.enabled = self.items.count < self.maxCount;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint tPoint = [pan translationInView:self.window];
            if (self.floatingArea.superview) {
                CGFloat x = MAX(SCREEN_WIDTH - tPoint.x - kSEFloatingAreaWidth / 4.f, SCREEN_WIDTH - kSEFloatingAreaWidth);
                CGFloat y = MAX(SCREEN_HEIGHT - tPoint.x - kSEFloatingAreaWidth / 4.f, SCREEN_HEIGHT - kSEFloatingAreaWidth);
                self.floatingArea.frame = (CGRect){ CGPointMake(x, y), self.floatingArea.bounds.size };
                
                CGPoint innerPoint = [pan locationInView:self.window];
                self.floatingArea.highlighted = kSEFloatAreaContainsPoint(innerPoint);
            }
            
            [self.animator updateContinousAnimationPercent:tPoint.x / SCREEN_WIDTH];
            [self.interactive updateInteractiveTransition:tPoint.x / SCREEN_WIDTH];
            
            if (self.floatingBall.alpha < 1.f && self.unusedItems.count >= 1) self.floatingBall.alpha = tPoint.x / SCREEN_WIDTH;
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
                        if (!self.floatingBall.superview && self.isAvailable) { [self.window addSubview:self.floatingBall]; }
                        if (![self.items containsObject:tempItem]) { [self->_items addObject:tempItem]; }
                        [self archiveEntranceItems];
                        [self.animator finishContinousAnimation];
                        [self.interactive finishInteractiveTransition];
                        [self.floatingList reloadData];
                        [self.floatingBall reloadIconViews:self.items];
                    } else {
                        // floating is full
                        [self.animator cancelContinousAnimation];
                        [self.interactive cancelInteractiveTransition];
                        [self showItemsFullAlert];
                    }
                } else if (tempItem.se_isEntrance) {
                    // just ended
                    [self.animator finishContinousAnimation];
                    [self.interactive finishInteractiveTransition];
                } else {
                    // just ended
                    [self.animator finishContinousAnimationWithFastAnimating:YES];
                    [self.interactive finishInteractiveTransition];
                }
            } else {
                [self.animator cancelContinousAnimation];
                [self.interactive cancelInteractiveTransition];
            }
            self.interactive = nil;
            [self.floatingArea removeFromSuperview];
            [UIView animateWithDuration:.25 animations:^{ self.floatingBall.alpha = (self.unusedItems.count >= 1) ? 1.f : .0f; }];
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
        listItem.selected = CGRectContainsPoint(listItem.frame, point);
    }
}

- (void)floatingBall:(SEFloatingBall *)floatingBall pressDidEnded:(UILongPressGestureRecognizer *)gesture {
    // will end, check floating list is selected
    for (SEFloatingListItem *listItem in self.floatingList.listItems) {
        if (listItem.isSelected) {
            [self pushEntranceItem:(UIViewController<SEItem> *)listItem.item];
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
    [self pushEntranceItem:(UIViewController<SEItem> *)item];
}

- (BOOL)floatingList:(SEFloatingList *)list willDeleteItem:(id<SEItem>)item {
    if (![self.items containsObject:(UIViewController<SEItem> *)item]) return NO;
    [self->_items removeObject:(UIViewController<SEItem> *)item];
    [self archiveEntranceItems];
    return YES;
}

- (BOOL)floatingList:(SEFloatingList *)list isItemVisible:(id<SEItem>)item {
    return !((UIViewController<SEItem> *)item).se_isUsed;
}

- (void)floatingListWillShow:(SEFloatingList *)list {
    [UIView animateWithDuration:0.25 animations:^{ self.floatingBall.alpha = .0f; }];
}

- (void)floatingListWillHide:(SEFloatingList *)list {
    
    NSArray<UIViewController<SEItem> *> *unusedItems = self.unusedItems;
//    [self.floatingBall reloadIconViews:unusedItems];

    CGFloat alpha = unusedItems.count >= 1 ? 1.f : self.floatingBall.alpha;
    [UIView animateWithDuration:0.25 animations:^{ self.floatingBall.alpha = alpha; }];
}

#pragma mark - Setter

- (void)setMaxCount:(NSUInteger)maxCount {
    _maxCount = MAX(1, MIN(5, maxCount));
}

- (void)setWindow:(UIWindow *)window {
    if (_window == window) return;
    _window = window;
    if (self.floatingBall.superview) [self.floatingBall removeFromSuperview];
    if (self.isAvailable && self.items.count) { [window addSubview:self.floatingBall]; }
}

- (void)setAvailable:(BOOL)available {
    
    _available = available;
    if (!available) {
        [self.floatingBall removeFromSuperview];
    } else {
        if (self.floatingBall.superview) [self.floatingBall.superview bringSubviewToFront:self.floatingBall];
        else if (self.items.count >= 1) [self.window addSubview:self.floatingBall];
    }
}

- (void)setArchivedPath:(NSString *)archivedPath {
    
    if ([_archivedPath isEqualToString:archivedPath]) return;
    _archivedPath = archivedPath;
    [self->_items removeAllObjects];
    [self.floatingBall removeFromSuperview];
    [self unarchiveEntranceItems];
}

#pragma mark - Getter

- (UIWindow *)window { return _window ? : [UIApplication sharedApplication].keyWindow; }

- (UINavigationController *)navigationController {
    
    __kindof UIViewController *controller = self.window.rootViewController;
    if ([controller isKindOfClass:[UITabBarController class]]) { controller = [(UITabBarController *)controller selectedViewController]; }
    while (controller.presentedViewController) { controller = controller.presentedViewController; }

    if ([controller isKindOfClass:[UINavigationController class]]) return controller;
    if (controller.navigationController) return controller.navigationController;
    return nil;
}

- (NSArray<UIViewController<SEItem> *> *)unusedItems {
    return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.se_isUsed = NO"]];
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

@end

@implementation SuspensionEntrance (NavigationControllerDelegate)

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    self.animator = nil;
    self.interactive = nil;
    [self.floatingBall reloadIconViews:self.unusedItems];
    
    if (![viewController se_canBeEntrance]) return;
    if (navigationController.viewControllers.count <= 1) return;
    
    NSArray<UIGestureRecognizer *> *gestures = [viewController.view.gestureRecognizers copy];
    for (UIGestureRecognizer *gesture in gestures) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]] && gesture.delegate == self) {
            // may be this gesture is add before, remove it
            [viewController.view removeGestureRecognizer:gesture];
        }
    }
    
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
    
    if (operation == UINavigationControllerOperationPop) {
        if (self.interactive) {
            CGRect const floatingRect = [self floatingRectOfOperation:operation];
            self.animator = [SETransitionAnimator continuousPopAnimatorWithRect:floatingRect];
        } else if (fromVC.se_isEntrance) {
            CGRect const floatingRect = [self floatingRectOfOperation:operation];
            self.animator = [SETransitionAnimator roundPopAnimatorWithRect:floatingRect];
        } else {
            self.animator = nil;
        }
    } else if (operation == UINavigationControllerOperationPush) {
        if ((toVC.se_isEntrance && fromVC.se_isEntrance) || (toVC.se_isEntrance && !fromVC.se_isEntrance)) {
            CGRect const floatingRect = [self floatingRectOfOperation:operation];
            self.animator = [SETransitionAnimator roundPushAnimatorWithRect:floatingRect];
        } else {
            self.animator = nil;
        }
//        [self.floatingBall reloadIconViews:self.unusedItems];
    }
    return self.animator;
}

@end

@implementation SuspensionEntrance (TransitioningDelegate)

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    if (self.interactive) {
        CGRect const floatingRect = [self floatingRectOfOperation:UINavigationControllerOperationPop];
        self.animator = [SETransitionAnimator continuousPopAnimatorWithRect:floatingRect];
    } else if (dismissed.se_isEntrance) {
        CGRect const floatingRect = [self floatingRectOfOperation:UINavigationControllerOperationPop];
        self.animator = [SETransitionAnimator roundPopAnimatorWithRect:floatingRect];
    } else {
        self.animator = nil;
    }
    return self.animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)toVC presentingController:(UIViewController *)fromVC sourceController:(UIViewController *)source {
    
    if ((toVC.se_isEntrance && fromVC.se_isEntrance) || (toVC.se_isEntrance && !fromVC.se_isEntrance)) {
        CGRect const floatingRect = [self floatingRectOfOperation:UINavigationControllerOperationPush];
        self.animator = [SETransitionAnimator roundPushAnimatorWithRect:floatingRect];
    } else {
        self.animator = nil;
    }
    
//    NSArray<UIViewController<SEItem> *> *unusedItems = self.unusedItems;
//    [self.floatingBall reloadIconViews:unusedItems];
    
    NSArray<UIGestureRecognizer *> *gestures = [toVC.view.gestureRecognizers copy];
    for (UIGestureRecognizer *gesture in gestures) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]] && gesture.delegate == self) {
            // may be this gesture is add before, remove it
            [toVC.view removeGestureRecognizer:gesture];
        }
    }
    
    UIScreenEdgePanGestureRecognizer *pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTransition:)];
    pan.edges = UIRectEdgeLeft;
    pan.delegate = self;
    [toVC.view addGestureRecognizer:pan];

    return self.animator;
}

//- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator;

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.interactive;
}

@end
