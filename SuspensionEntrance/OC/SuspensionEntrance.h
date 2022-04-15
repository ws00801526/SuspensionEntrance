//  SuspensionEntrance.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SuspensionEntrance

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol SEItem <NSObject>

@required
/// the title of entrance
@property (copy  , nonatomic) NSString *entranceTitle;

@optional
/// the icon url of entrance
@property (copy  , nonatomic, nullable) NSURL *entranceIconUrl;
/// the userInfo of entrance
@property (copy  , nonatomic, nullable) NSDictionary *entranceUserInfo;

/**
 To archive & unarchive items

 @warning item won't be archived if the real class dont implement this method
 @param item  the item to be archived
 @return the real Class instance
 */
+ (instancetype)entranceWithItem:(id<SEItem>)item;

@end

typedef void(^SEItemIconHandler)(UIImageView *iconView, id<SEItem> item);

@interface SuspensionEntrance : NSObject

/// max items can be stored, should not over 5. Default is 5.
@property (assign, nonatomic) NSUInteger maxCount;
/// The path to be archived of items. Default is ~/Documents/entrance.items.
@property (copy  , nonatomic) NSString *archivedPath;
/// then handler to get correct icon of item.
@property (copy  , nonatomic) SEItemIconHandler iconHandler;
/// The image of close icon
@property (strong, nonatomic, nullable) UIImage *closePlaceholder;
/// Should vibrate when the floating area is highlighted. Default is YES.
@property (assign, nonatomic, getter=isVibratable) BOOL vibratable;
/// Is entrance available. Default is YES.
@property (assign, nonatomic, getter=isAvailable) BOOL available;
/// The window where UI to be placed
@property (weak, nonatomic, nullable) UIWindow *window;
/// The entrance items
@property (strong, nonatomic, readonly) NSArray<UIViewController<SEItem> *> *items;
/// The entrance class should not be appeared.
@property (strong, nonatomic, readonly) NSMutableSet<Class> *disabledClasses;
/// The entrance class should be ignored.
@property (strong, nonatomic, readonly) NSMutableSet<Class> *ignoredClasses;

+ (instancetype)shared;

/**
 Check item is the entrance item

 @param item the item to be checked
 @return YES or NO
 */
- (BOOL)isEntranceItem:(__kindof UIViewController *)item;


/**
 Set item to be an entrance item

 @discussion Will auto pop if set succeed & navigationController.viewControllers.lastObject == item
 @param item the item
 */
- (void)addEntranceItem:(__kindof UIViewController<SEItem> *)item;


/**
 Cancel the entrance item

 @param item the item
 */
- (void)cancelEntranceItem:(__kindof UIViewController<SEItem> *)item;

/**
 Remove all entrance items
 */
- (void)clearEntranceItems;

@end


@interface SuspensionEntrance (NavigationControllerDelegate) <UINavigationControllerDelegate>
@end

@interface SuspensionEntrance (TransitioningDelegate) <UIViewControllerTransitioningDelegate>

@end

NS_ASSUME_NONNULL_END
