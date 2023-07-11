//
//  XMixScrollManager.h
//  XMixScrollManager
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import <UIKit/UIKit.h>

///未定义值
UIKIT_EXTERN CGFloat const XMixScrollUndefinedValue;

///下拉选项
typedef NS_ENUM (NSUInteger, XMixScrollPullType) {
    ///均不可下拉
    XMixScrollPullTypeNone,
    ///Main Scroll可下拉
    XMixScrollPullTypeMain,
    ///content Scroll可下拉
    XMixScrollPullTypeSub,
    ///均可下拉
    XMixScrollPullTypeAll
};

///滑动条选项
typedef NS_ENUM (NSUInteger, XShowIndicatorType) {
    ///隐藏不显示
    XShowIndicatorTypeNone,
    ///只显示子视图
    XShowIndicatorTypeSub,
    ///切换显示
    XShowIndicatorTypeChange
};

NS_ASSUME_NONNULL_BEGIN
@interface XMixScrollManager : NSObject

#pragma mark- 初始化
/// 唯一初始化方法
/// @param mainScrollView 外层ScrollView
/// @param contentScrollViews 附属ScrollView数组 可稍后添加
+ (instancetype)managerWithMainScrollView:(UIScrollView *)mainScrollView contentScrollViews:(NSArray<UIScrollView *> *_Nullable)contentScrollViews;

/// 添加子scrollView 初始化未获得可手动再添加
/// @param contentScrollView 子scrollView
/// @param index 页面位置索引
- (void)addContentScrollView:(UIScrollView *)contentScrollView withIndex:(NSInteger)index;

#pragma mark- 必设属性
///contentScrollView 可移动的距离 一般为在mainScrollView里的相对坐标Y 默认 XMixScrollUndefinedValue 即时生效  赋值有效值之前动态模拟不会生效
@property (nonatomic) CGFloat contentScrollDistance;

#pragma mark- 可选属性 作用于所有contentScrollView
///各contentScrollView的共同横向superScrollView
///内部是寻找第一个contentScrollView的父视图里的第一个UIScrollView
///与实际不符时可 以此修正
///主要用于scrollsToTop及散装属性
@property (nonatomic, weak) UIScrollView *fixHorizontalSuperScrollView;

///滑动条显示 默认切换显示
@property (nonatomic) XShowIndicatorType showIndicatorType;
///默认main可下拉
@property (nonatomic) XMixScrollPullType mixScrollPullType;
///点击状态栏回顶部时  是否直接回到mainScrollView顶部 默认Yes
@property (nonatomic) BOOL scrollsToMainTop;

///是否开启动态模拟 默认 NO  在main范围内content范围外 上拉没有过度滑动效果 YES则添加模拟效果
@property (nonatomic) BOOL enableDynamicSimulate;
///动态模拟过度滑动效果 阻力参数 默认 2
@property (nonatomic) CGFloat dynamicResistance;
///hook手势方法shouldRecognizeSimultaneouslyWithGestureRecognizer后，是否需要透传抛出处理，默认NO
@property (class, nonatomic) BOOL gestureThrow;

#pragma mark- 散装属性设置 可分别定制contentScrollView的一些属性

///开启散装属性 默认NO
@property (nonatomic) BOOL enableCustomConfig;

- (void)setShowIndicatorType:(XShowIndicatorType)showIndicatorType forScrollView:(UIScrollView *)contentScrollView;
- (void)setMixScrollPullType:(XMixScrollPullType)mixScrollPullType forScrollView:(UIScrollView *)contentScrollView;
- (void)setScrollsToMainTop:(BOOL)scrollsToMainTop forScrollView:(UIScrollView *)contentScrollView;
- (void)setEnableDynamicSimulate:(BOOL)enableDynamicSimulate forScrollView:(UIScrollView *)contentScrollView;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
NS_ASSUME_NONNULL_END
