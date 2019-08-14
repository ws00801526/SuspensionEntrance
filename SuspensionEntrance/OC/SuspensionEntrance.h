//  SuspensionEntrance.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SuspensionEntrance

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SEItem <NSObject>

@required @property (copy  , nonatomic) NSString *entranceTitle;
@optional @property (copy  , nonatomic, nullable) NSURL *entranceIconUrl;
@optional @property (copy  , nonatomic, nullable) NSDictionary *entranceUserInfo;

@optional
/**
 To archive & unarchive items

 @warning item won't be archived if the real class dont implement this method
 @param item  the item to be archived
 @return the real Class instance
 */
+ (instancetype)entranceWithItem:(id<SEItem>)item;

@end

@interface SuspensionEntrance : NSObject

@property (assign, nonatomic) NSUInteger maxCount;
/// The path to be archived of items. Default is ~/Documents/entrance.items.
@property (copy  , nonatomic) NSString *archivedPath;
/// Should vibrate when the floating area is highlighted. Default is YES.
@property (assign, nonatomic, getter=isVibratable) BOOL vibratable;

@property (weak, nonatomic, nullable) UIWindow *window;
@property (strong, nonatomic, readonly) NSArray<id<SEItem>> *items;

+ (instancetype)shared;

@end


@interface SuspensionEntrance (NavigationControllerDelegate) <UINavigationControllerDelegate>
@end

NS_ASSUME_NONNULL_END
