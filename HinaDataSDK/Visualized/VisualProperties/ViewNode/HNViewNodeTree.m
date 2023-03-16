//
// HNViewNodeTree.m
// HinaDataSDK
//
// Created by hina on 2022/1/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNViewNodeTree.h"
#import "UIView+HNVisualProperties.h"
#import "UIView+HNVisualizedViewPath.h"
#import "HNConstants+Private.h"
#import "HNVisualizedUtils.h"
#import "HNViewNodeFactory.h"
#import "HNCommonUtility.h"
#import "HNSwizzle.h"
#import "HNLog.h"

static void * const kHNRNManagerContext = (void*)&kHNRNManagerContext;
static NSString * const kHNRNManagerScreenPropertiesKeyPath = @"screenProperties";

@interface HNViewNodeTree()

/// 当前根节点
@property (nonatomic, strong) HNViewNode *rootNode;

/// 自定义属性采集队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@implementation HNViewNodeTree


- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _serialQueue = queue;
        [self initialization];
        [self setupListeners];
    }
    return self;
}

#pragma mark initialization
- (void)initialization {
    // 主线程异步开始遍历，防止视图未加载完成，存在元素遗漏
    dispatch_async(dispatch_get_main_queue(), ^{
        // 遍历 keyWindow，初始化构造节点树
        UIWindow *keyWindow = [HNVisualizedUtils currentValidKeyWindow];
        HNViewNode *keyWindowNode = [HNViewNodeFactory viewNodeWithView:keyWindow];

        // 为了支持多 window，此处构建虚拟根节点
        UIView *rootView = [[UIView alloc] initWithFrame:keyWindow.bounds];
        HNViewNode *rootNode = [[HNViewNode alloc] initWithView:rootView];

        // 构建关系
        keyWindowNode.nextNode = rootNode;
        [rootNode.subNodes addObject:keyWindowNode];
        self.rootNode = rootNode;
        
        // 遍历视图
        [self queryAllSubviewsWithView:keyWindow isRootView:YES];
    });
}

- (void)setupListeners {
    // hook UIView 用于遍历页面元素
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        /* 备注
         测试发现：xib 自定义 tableViewCell 嵌套代码添加 UICollectionView， UICollectionView 未执行 didMoveToWindow
         didMoveToSuperview 更准确，也符合业务逻辑（index 是根据 superview.subviews 序号计算）
         */
        NSError *error = nil;
        [UIView sa_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(hinadata_visualize_didMoveToSuperview) error:&error];
        if (error) {
            HNLogError(@"Failed to swizzle on UIView. Error details: %@", error);
        }
        
        // 测试发现部分场景下，UINavigationTransitionView 未执行 didMoveToSuperview，但是执行了 didMoveToWindow
        [UIView sa_swizzleMethod:@selector(didMoveToWindow) withMethod:@selector(hinadata_visualize_didMoveToWindow) error:NULL];
        
        // 测试发现 UIAlertController.view 即 _UIAlertControllerView 显示，未执行 didMoveToWindow 和 didMoveToSuperview，但是其父视图调用了 didAddSubview
        [UIView sa_swizzleMethod:@selector(didAddSubview:) withMethod:@selector(hinadata_visualize_didAddSubview:) error:NULL];
        
        // 兼容在业务中，动态修改了 keyWindow
        [UIWindow sa_swizzleMethod:@selector(becomeKeyWindow) withMethod:@selector(hinadata_visualize_becomeKeyWindow) error:NULL];
        
        // 针对 tab 元素，调用 setSelectedItem 切换页面后，更新子视图页面名称
        [UITabBar sa_swizzleMethod:@selector(setSelectedItem:) withMethod:@selector(hinadata_visualize_setSelectedItem:) error:NULL];

        // 兼容 RN 项目，tab 点击触发页面浏览事件，但是 tab 对应节点的 screenName 为更新，监听 screenProperties 设置，并更新 RN 节点的页面信息
        Class rnManagerClass = NSClassFromString(@"HNReactNativeManager");
        if (rnManagerClass) {
            SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
            if (rnManagerClass && [rnManagerClass respondsToSelector:sharedInstanceSEL]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id manager = [rnManagerClass performSelector:sharedInstanceSEL];
                [manager addObserver:self forKeyPath:kHNRNManagerScreenPropertiesKeyPath options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:kHNRNManagerContext];
#pragma clang diagnostic pop
            }
        }

        // bringSubviewToFront 和 sendSubviewToBack，不执行 didMoveTo 相关方法，但是会修改 index，从而改变路径
        [UIView sa_swizzleMethod:@selector(bringSubviewToFront:) withMethod:@selector(hinadata_visualize_bringSubviewToFront:) error:NULL];
        
        [UIView sa_swizzleMethod:@selector(sendSubviewToBack:) withMethod:@selector(hinadata_visualize_sendSubviewToBack:) error:NULL];
        
        // cell 被重用，需要重新计算 indexPath
        [UITableViewCell sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(hinadata_visualize_prepareForReuse) error:NULL];
        
        [UICollectionViewCell sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(hinadata_visualize_prepareForReuse) error:NULL];
        
        // HeaderFooterView 被重用，重新计算 index
        [UITableViewHeaderFooterView sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(hinadata_visualize_prepareForReuse) error:NULL];
    });
}

/// 初始遍历页面，构造节点树
- (void)queryAllSubviewsWithView:(UIView *)view isRootView:(BOOL)isRootView {
    @try {
        if (!isRootView) {
            [self addViewNodeWithView:view];
        }

        for (UIView *subView in view.subviews) {
            [self queryAllSubviewsWithView:subView isRootView:NO];
        }
    } @catch (NSException *exception) {
        HNLogWarn(@"%@", exception);
    }
}

#pragma mark build
/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view {

    // 异步执行，防止 cell 等未加载或部分元素无法获取页面名称
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // 视图显示
            if (view.superview) {
                [self addViewNodeWithView:view];
            } else {
                // 移除节点
                [self removeViewNodeWithView:view];
            }
        } @catch (NSException *exception) {
            HNLogWarn(@"%@", exception);
        }
    });
}

- (void)didMoveToWindowWithView:(UIView *)view {
    // 异步执行，防止 cell 等未加载或部分元素无法获取页面名称
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // 视图显示
            if (!view.window) {
                // 移除节点
                [self removeViewNodeWithView:view];
                return;
            }

            if (!view.superview) {
                return;
            }
            [self addViewNodeWithView:view];
        } @catch (NSException *exception) {
            HNLogWarn(@"%@", exception);
        }
    });
}

- (void)didAddSubview:(UIView *)subview {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!subview.superview) {
            return;
        }
        @try {
            [self addViewNodeWithView:subview];
        } @catch (NSException *exception) {
            HNLogWarn(@"%@", exception);
        }
    });
}

- (void)becomeKeyWindow:(UIWindow *)window {
    dispatch_async(dispatch_get_main_queue(), ^{
        /* 判断当前 window，是否已经被构建
         需要放在主队列异步，确保 rootNode 构建完成，防止判断不准
         */
        for (HNViewNode *node in self.rootNode.subNodes) {
            if (node.view == window) {
                return;
            }
        }
        
        // 构建链接关系
        HNViewNode *viewNode = [HNViewNodeFactory viewNodeWithView:window];
        viewNode.nextNode = self.rootNode;
        [self.rootNode.subNodes addObject:viewNode];
    });
}

// view 消失，移除节点
- (void)removeViewNodeWithView:(UIView *)view {
    if (view.superview || !view.hinadata_viewNode) {
        return;
    }

    [self updateBrotherViewNodeWithView:view isAddViewNode:NO];

    // 根据当前 view，删除节点
    view.hinadata_viewNode = nil;
}

/// 显示 view，构建 node 信息
- (void)addViewNodeWithView:(UIView *)view {
    // 节点已被构建，更新链接
    if (view.hinadata_viewNode) {
        HNViewNode *viewNode = view.hinadata_viewNode;
        // 过滤重复构建
        if (view.superview == viewNode.nextNode.view) {
            return;
        }
        [viewNode buildNodeRelation];
        return;
    }

    // 部分 view 当做整体处理，不必构建子视图
    if ([self isIgnoreBuildNodeWithView:view]) {
        return;
    }

    // 构造相关节点
    UIResponder *nextResponder = view.nextResponder;
    if (!nextResponder) {
        return;
    }

    HNViewNode *node = [HNViewNodeFactory viewNodeWithView:view];
    UIView *nextView = [nextResponder isKindOfClass:UIView.class] ? (UIView *)nextResponder : [view superview];
    if (!nextView) {
        return;
    }
    // 同级同类元素个数
    NSInteger brotherViewCount = 0;
    for (HNViewNode *subNode in nextView.hinadata_viewNode.subNodes) {
        if ([subNode.viewName isEqualToString:node.viewName]) {
            brotherViewCount++;
        }
    }

    // view 被插入到父视图，而不是直接 addSubView，后面同级同类元素，需要更新信息
    if (node.index < brotherViewCount - 1) {
        [self updateBrotherViewNodeWithView:view isAddViewNode:YES];
    }
}

- (BOOL)isIgnoreBuildNodeWithView:(UIView *)view {
    UIView *superView = view.superview;
    UIView *nextView = [view.nextResponder isKindOfClass:UIView.class] ? (UIView *)view.nextResponder : nil;

    if ([HNVisualizedUtils isIgnoreSubviewsWithView:superView] || [HNVisualizedUtils isIgnoreSubviewsWithView:nextView]) {
        return YES;
    }
    return NO;
}

/// 更新当前 view 兄弟元素索引
- (void)updateBrotherViewNodeWithView:(UIView *)view isAddViewNode:(BOOL)isAdd {
    HNViewNode *currentNode = view.hinadata_viewNode;

    // 移除节点，先从父节点的子节点数组中移除
    if (!isAdd) {
        [currentNode.nextNode.subNodes removeObject:currentNode];
    }
    // 更新兄弟节点 index
    [currentNode refreshBrotherNodeIndex];
}

#pragma mark refresh
- (void)refreshRNViewScreenNameWithViewController:(UIViewController *)viewController {
    /* 页面信息更新
     在 RN 框架中，部分弹出页面为原生的自定义 viewController，但是上面元素，仍然为 RN 元素，并且获取到元素所在页面名称为 Native 页面名称，即 viewController 类名
     但是自定义属性元素构建过程，是在 view 加载时，在触发 viewDidAppear 之前，此时尚未设置 isRootViewVisible = NO，导致此时获取到的页面名称，仍然为跳转前的 RN 页面名称，导致自定义属性匹配失败

     修复方案：
     针对 RN 的自定义 viewController，触发 viewDidAppear，更新当前页面的 RN 元素节点的页面名称，从而保证和扫码上传页面信息中的 RN 元素页面名称一致。
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        HNViewNode *viewNode = viewController.view.hinadata_viewNode;
        [viewNode refreshSubNodeScreenName];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != kHNRNManagerContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    if (![keyPath isEqualToString:kHNRNManagerScreenPropertiesKeyPath]) {
        return;
    }
    
    NSString *oldScreenName = nil;
    if ([change[NSKeyValueChangeOldKey] isKindOfClass:NSDictionary.class]) {
        oldScreenName = change[NSKeyValueChangeOldKey][kHNEventPropertyScreenName];
    }
    NSString *newScreenName = change[NSKeyValueChangeNewKey][kHNEventPropertyScreenName];
    if ([newScreenName isEqualToString:oldScreenName]) {
        return;
    }
    
    /* RN 元素自定义属性兼容逻辑
     原因说明：
     在 RN 项目中，点击按钮 button，进行页面跳转，从 A 跳转到 B，RN 插件触发的事件顺序是，trackViewClick: -> trackViewScreen:
     同时在 trackViewScreen 中，会将 HNReactNativeManager 单例中保存的页面名称 (visualizeProperties 接口返回) 更新为 B
     这时候，自定义属性正在子线程异步遍历页面节点，如果实时获取 RN 元素所在页面名称，这时候获取当前页面为 B
     但是添加自定义属性的时刻，属性元素所在页面，应该和按钮 button 相同，即自定义属性配置的页面未 A
     可能导致，因为属性元素页面名称匹配失败导致无法匹配属性元素，从而自定义属性无法采集
     
     修改方案：
     针对 RN 元素，触发 RN 页面浏览后，更新当前 RN 节点中，页面信息不一致的节点
     */
    
    __block HNViewNode *windowNode = nil;
    [HNCommonUtility performBlockOnMainThread:^{
        for (HNViewNode *node in self.rootNode.subNodes) {
            if ([node.view isKindOfClass:UIWindow.class] && [(UIWindow *)node.view isKeyWindow]) {
                windowNode = node;
                break;
            }
        }
    }];
    
    // 共用自定义属性查询队列，保证属性采集完成再更新页面名称
    dispatch_async(self.serialQueue, ^{
        // hinadata_clickableForRNView 等操作，需要主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshRNViewScreenName:newScreenName viewNode:windowNode];
        });
    });
}

// 刷新 RN 元素节点页面名称
- (void)refreshRNViewScreenName:(NSString *)screenName viewNode:(HNViewNode *)viewNode {
    if ([viewNode isKindOfClass:HNRNViewNode.class] && [viewNode.view hinadata_clickableForRNView] && ![screenName isEqualToString:viewNode.screenName]) {
        [viewNode refreshSubNodeScreenName];
        return;
    }
    for (HNViewNode *subNode in viewNode.subNodes) {
        [self refreshRNViewScreenName:screenName viewNode:subNode];
    }
}

#pragma mark queryView
- (UIView *)viewWithPropertyConfig:(HNVisualPropertiesPropertyConfig *)config {
    return [self viewWithPropertyConfig:config viewNode:self.rootNode];
}

- (UIView *)viewWithPropertyConfig:(HNVisualPropertiesPropertyConfig *)config viewNode:(HNViewNode *)node {
    if ([config isMatchVisualPropertiesWithViewIdentify:node]) {
        return node.view;
    }
    __block UIView *resultView = nil;
    [node.subNodes enumerateObjectsUsingBlock:^(HNViewNode *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        UIView *view = [self viewWithPropertyConfig:config viewNode:obj];
        if (view) {
            resultView = view;
            *stop = YES;
        }
    }];
    return resultView;
}

#pragma mark config
/// 自定义属性配置更新
/// @param configResponse 配置原始 json 数据
- (void)updateConfig:(NSDictionary *)configResponse {
    if (configResponse.count == 0) {
        return;
    }

    // 递归遍历，发送自定义属性配置
    [self sendWebViewConfig:configResponse viewNode:self.rootNode];
}

- (void)sendWebViewConfig:(NSDictionary *)configResponse viewNode:(HNViewNode *)node {
    if ([node isKindOfClass:HNWKWebViewNode.class]) {
        HNWKWebViewNode *webViewNode = (HNWKWebViewNode *)node;
        
        // getWindow 需要在主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            // 判断 WebView 是否显示
            if (!webViewNode.view.window || ![HNVisualizedUtils isVisibleForView:webViewNode.view]) {
                return;
            }
            [webViewNode callJSSendVisualConfig:configResponse];
        });
        return;
    }
    
    [node.subNodes enumerateObjectsUsingBlock:^(HNViewNode *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [self sendWebViewConfig:configResponse viewNode:obj];
    }];
}

@end
