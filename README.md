# SuspensionEntrance	
仿微信新版的悬浮窗入口功能



#### 1. 使用方式

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

