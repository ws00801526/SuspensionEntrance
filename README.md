# SuspensionEntrance	

仿微信新版的悬浮窗入口功能

![Aug-23-2019 21-34-09.gif](https://github.com/ws00801526/SuspensionEntrance/blob/master/Aug-23-2019%2021-34-09.gif)



#### 1. 使用方式

```ruby
pod SuspensionExtrance ~> 0.1.0 // 使用podfile方式引入
```



```objective-c

@implementation BaseNavigationController
- (void)viewDidLoad {
    [super viewDidLoad];
    // 在自定义的navigationController中 设置代理, 如果已经使用了代理,
    self.delegate = [SuspensionEntrance shared];
    // 关闭系统返回手势
    self.interactivePopGestureRecognizer.enabled = NO;
}
@end

// 对于可以作为入口界面的Controller,实现SEItem协议
@interface EntranceViewController : UIViewController <SEItem>
@property (copy  , nonatomic) NSString *entranceTitle;
@property (copy  , nonatomic, nullable) NSURL *entranceIconUrl;
@property (copy  , nonatomic, nullable) NSDictionary *entranceUserInfo;
@end

// 并实现下列构造方法, !!! 如果不实现则无法进行序列化存储
+ (instancetype)entranceWithItem:(id<SEItem>)item {
    EntranceViewController *controller = [[EntranceViewController alloc] initWithNibName:nil bundle:nil];
    controller.entranceTitle = item.entranceTitle;
    controller.entranceIconUrl = item.entranceIconUrl;
    controller.entranceUserInfo = item.entranceUserInfo;
    return controller;
}

```



###### 一般情况下, 我们自己项目内都会使用自定义返回手势, 并且已经设置了代理, 那可以采用下列的方式进行对接

```objective-c
// 在对应的代理方法里面调用 
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[SuspensionEntrance shared] navigationController:navigationController willShowViewController:viewController animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[SuspensionEntrance shared] navigationController:navigationController didShowViewController:viewController animated:animated];
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return [[SuspensionEntrance shared] navigationController:navigationController interactionControllerForAnimationController:animationController];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return [[SuspensionEntrance shared] navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
}

// 然后同上面一步, 一样实现SEItem协议, 需要注意的事, 需要手动关闭自定义返回手势, 以避免手势冲突
// 以集成了 forkingdog/FDFullscreenPopGesture(https://github.com/forkingdog/FDFullscreenPopGesture) 为例, 添加下列方法
- (void)fd_interactivePopDisabled { return YES; }
```



#### 2. 重点

##### 2.1 实现自定义的`UINavigationController`的`push & pop`动画效果

为了实现自定义的`push & pop`动画, 我们需要借助于苹果在iOS7开始提供的API: `UIViewControllerAnimatedTransitioning`可以实现具体效果

###### 2.1.1 自定义动画效果: `UIViewControllerAnimatedTransitioning`

```objective-c
// 实现协议方法, 用于创建自定义的push & pop手势
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    // the duration for animation
}

// 在这里我们将此次使用到的动画效果大致分为三种
// 1. 从圆球----push----->到具体的viewController
// 2. 从viewController  --pop--> 圆球效果
// 3. 交互式滑动, 并根据滑动距离更新界面UI,最后 ---pop---> 圆球效果
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // 自定义自己的动画效果, 利用CoreAnimations or [UIView animateWithDuration:0.25 animations:NULL] 都可以
}
```



###### 2.1.2 实现交互式动画: `UIViewControllerInteractiveTransitioning`

接下来我们就需要自定义返回的交互式手势了, 好在苹果为我们也准备好了`API`接口, 我们只需要借助他即可实现

```objective-c
// 1. 在对应的view上添加滑动手势, 这边我们直接借助于UIScreenEdgePanGestureRecognizer
{   
    UIScreenEdgePanGestureRecognizer *pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTransition:)];
    pan.edges = UIRectEdgeLeft;
    pan.delegate = self;
    [viewController.view addGestureRecognizer:pan];
}
// 2. 实现手势方法
- (void)handleTransition:(UIScreenEdgePanGestureRecognizer *)pan {
    // ...
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: 
            // 2.1 触发交互式返回, 创建UIPercentDrivenInteractiveTransition对象
            // 2.2 调用返回手势
            // 2.3 处理一些其他的初始化动作...
          	self.interactive = [[UIPercentDrivenInteractiveTransition alloc] init];
            [tempItem.navigationController popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged:
            // 2.4 更新交互式动画进度, 注意因为我们的使用的是自定义动画, 并没有一个完整的动画过程, 
            // 所以我们需要自己更新动画过程, 如果直接使用的系统自带返回, 那么我们只需要更新interactive即可
            [self.animator updateContinousPopAnimationPercent:tPoint.x / SCREEN_WIDTH];
            [self.interactive updateInteractiveTransition:tPoint.x / SCREEN_WIDTH];
            // 2.5 处理其他一些判断条件(例如是否拖动到浮窗检测区域)...
            break;
        case UIGestureRecognizerStateEnded:     // fall through
        case UIGestureRecognizerStateCancelled:
            // 2.6 判断动画完成情况, 是否具体完成 or 取消
            // 2.7 处理一些完成后动作(例如是否添加浮窗等)...
			break;
    }
}
```

至此我们大致完成了一个简单的交互式自定义返回效果, 具体代码可以查看 `SuspensionEntrance`和`SETransitionAnimator`.

##### 2.2 浮球实现

接下来我们就需要对应的浮球效果,从微信分析可以看出,浮球主要包含了下面几个具体控件

###### 2.2.1 浮球 -- `SEFloatingBall`

主入口, 包含了点击、拖拽、长按等手势, 并提供了items的icon展示功能

* 点击 -- 此处检点的利用`touchBegan`方法,来处理
* 拖拽、长按

```objective-c
- (void)setupGestures {
    
    // 添加长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    longPress.allowableMovement = 5.f;
        // 关闭delays touches began功能, 因为我们在touchesBegan实现了点击方法, 并且动态高亮了点击背景, 所以我们需要实时呈现, 如果手势检测成功, 则会进入touchesCancelled
    longPress.delaysTouchesBegan = NO;
    [self addGestureRecognizer:longPress];
    
    // 添加拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    // 原因同上
    pan.delaysTouchesBegan = NO;
    [self addGestureRecognizer:pan];
    // 注意此处优先检测长按手势, 检测失败后才开始检测拖拽
    [pan requireGestureRecognizerToFail:longPress];
}
```

	* items 的icon展示 -- 此处用了比较暴力的直接计算....

###### 2.2.2 浮球检测窗 -- `SEFloatingArea`

主要用于检测浮球是否拖动到该区域, 用于判断是否需要将当前窗口作为浮窗入口. 这里并没有特别复杂的需要处理, 详细可以查看代码.

###### 2.2.3 浮球入口列表 -- `SEFloatingList`

主要用于展示已经标记为浮窗入口的列表项. 这里采用了代理模式,比较复杂的有下列几项

* 需要注意的是,不是所有的item项目都会被展示 -- 已经打开的item会被隐藏入口,防止2次push进入

* 计算展示位置,以及item的排列方式

    

    ```objective-c
    - (void)showAtRect:(CGRect)rect animated:(BOOL)animated {
    
        UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) safeAreaInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
        
        CGFloat const SCREEN_WIDTH = UIScreen.mainScreen.bounds.size.width;
        CGFloat const SCREEN_HEIGHT = UIScreen.mainScreen.bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom;
        
        // 获取可以被展示的item项
        NSArray<SEFloatingListItem *> *visibleListItems = [self.visibleItems copy];
        
        // 计算排列方式 
        // inLeft: 是否在左侧   list主要显示位置
        // inBottom: 是否在底部 item在rect底部 or 顶部
        // isEnough: 是否有足够空间排列, 如果没有足够控件, 则采用自下而上(底部) or 自上而下的方式(顶部), 保证控件布局
        CGFloat const padding = 15.f;
        CGFloat const itemHeight = (padding + kSEFloatingListItemHeight);
        CGFloat height = visibleListItems.count * itemHeight;
        BOOL inLeft = rect.origin.x <= (SCREEN_WIDTH / 2.f);
        BOOL inBottom = (rect.origin.y + height < SCREEN_HEIGHT);
        BOOL isEnough = inBottom ? ( CGRectGetMaxY(rect) + height + safeAreaInsets.bottom < SCREEN_HEIGHT ) : (rect.origin.y > (height + safeAreaInsets.top));
        
        // 计算起始点位置
        CGFloat x = inLeft ? 0.f : (SCREEN_WIDTH / 3.f);
        CGFloat y = inBottom ? (rect.origin.y + rect.size.height + padding) : (rect.origin.y - itemHeight);
        if (!isEnough) { y = inBottom ? SCREEN_HEIGHT + safeAreaInsets.top - kSEFloatingListItemHeight - 5.f : safeAreaInsets.top; }
        
        // 如果控件不足, 我们布局采用逆序布局, 方便计算y轴起始点
        if (!isEnough) visibleListItems = [[[visibleListItems reverseObjectEnumerator] allObjects] mutableCopy];
        
        // 最后进行对应的布局, 并添加动画
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
    ```



##### 2.3 其他

*  items的序列化存储 -- 利用了`NSKeyedArchiver\NSKeyedUnarchiver`将items的JSON数据写入本地文件

*  利用协议`SEItem`方式, 可以自定义任意的入口 -- 但是不建议针对内存消耗巨大的界面添加快捷入口, 内部并没有添加`UIApplicationDidReceiveMemoryWarningNotification`处理 -- (后期可能会考虑添加通知处理方法, 内存不足时回收快捷入口)
*  利用序列化方法,生成的快捷入口, 创建后并不会消耗大量内存, 因为`viewController`并没有调用`viewDidLoad`方法
