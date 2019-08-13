//  SEFloatingList.h
//  SuspensionEntrance
//
//  Created by  XMFraker on 2019/8/13
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      SEFloatingList

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SEItem;
@class SEFloatingList;
@protocol SEFloatingListDelegate <NSObject>

@required
- (NSUInteger)numberOfItemsInFloatingList:(SEFloatingList *)list;
- (id<SEItem>)floatingList:(SEFloatingList *)list itemAtIndex:(NSUInteger)index;
- (void)floatingListWillShow:(SEFloatingList *)list;
- (void)floatingListWillHide:(SEFloatingList *)list;

@optional
- (void)floatingList:(SEFloatingList *)list didSelectItem:(id<SEItem>)item;
- (BOOL)floatingList:(SEFloatingList *)list willDeleteItem:(id<SEItem>)item;

@end


@interface SEFloatingListItem : UIView

@property (assign, nonatomic, getter=isSelected) BOOL selected;
@property (assign, nonatomic, getter=isHighlighted) BOOL highlighted;
@property (weak,   nonatomic, readonly) id<SEItem> item;

@end

@interface SEFloatingList : UIView

@property (assign, nonatomic, readonly) CGRect floatingRect;
@property (assign, nonatomic, getter=isEditable) BOOL editable;
@property (weak  , nonatomic, nullable) id<SEFloatingListDelegate> delegate;
@property (copy  , nonatomic, readonly) NSArray<SEFloatingListItem *> *listItems;

- (void)reloadData;
- (void)dismissWithAnimated:(BOOL)animated;
- (void)showAtRect:(CGRect)rect animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
