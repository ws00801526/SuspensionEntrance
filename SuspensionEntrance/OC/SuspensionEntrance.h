//  SuspensionEntrance.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/8
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SuspensionEntrance

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SEItem <NSObject>

@property (copy  , nonatomic, readonly) NSURL *entranceUrl;
@property (copy  , nonatomic, nullable, readonly) NSString *entranceTitle;
@property (copy  , nonatomic, nullable, readonly) NSString *entranceIconUrl;

@end

@interface SuspensionEntrance : NSObject

@property (assign, nonatomic) NSUInteger maxCount;
@property (assign, nonatomic, getter=isVibratable) BOOL vibratable;

@property (weak, nonatomic, nullable) UIWindow *window;
@property (strong, nonatomic, readonly) NSArray<id<SEItem>> *items;

+ (instancetype)shared;
+ (void)registerMonitorClass:(Class)clazz;
+ (void)registerPanGestureKey:(NSString *)key;

@end


@interface SuspensionEntrance (NavigationControllerDelegate) <UINavigationControllerDelegate>
@end

NS_ASSUME_NONNULL_END
