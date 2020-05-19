//
//  PresentNavigationController.h
//  SuspensionEntrance
//
//  Created by XMFraker on 2020/5/18.
//  Copyright © 2020 Fraker.XM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SuspensionEntrance.h"

NS_ASSUME_NONNULL_BEGIN
// !!! : take care of the memory usage.
@interface PresentNavigationController : UINavigationController <SEItem>
@property (copy  , nonatomic) NSString *entranceTitle;
@property (copy  , nonatomic, nullable) NSURL *entranceIconUrl;
@property (copy  , nonatomic, nullable) NSDictionary *entranceUserInfo;
@end

NS_ASSUME_NONNULL_END
