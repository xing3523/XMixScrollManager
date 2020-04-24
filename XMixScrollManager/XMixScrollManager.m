//
//  XMixScrollManager.m
//  XMixScrollManager
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import "XMixScrollManager.h"
#import <objc/runtime.h>

#pragma mark- ----------------其他类的声明定义
///给UIScrollView增加的属性类
@interface XScrollViewProperty : NSObject
///是否为主视图
@property (nonatomic) BOOL isMain;
///是否可滑动
@property (nonatomic) BOOL canScroll;
///是否需要显示滑动条
@property (nonatomic) BOOL needShowsVerticalScrollIndicator;
///视图索引标记
@property (nonatomic) NSInteger index;
///观察者和手势标记
@property (nonatomic) BOOL markScroll;
///绑定的scrollView
@property (nonatomic, weak) UIScrollView *scrollView;
///管理类 此处用于传递当前touch位置
@property (nonatomic, weak) XMixScrollManager *scrollManager;
@end

@interface UIScrollView (XMixScrollManager)<UIGestureRecognizerDelegate>
///属性类
@property (nonatomic, weak, readonly) XScrollViewProperty *p;
@end

@protocol XDynamicSimulateDelegate <NSObject>
@optional
///模拟过程将要移动的y距离
- (void)willMoveY:(CGFloat)movey;
@end

@interface XDynamicSimulate : NSObject
@property (nonatomic, weak) id<XDynamicSimulateDelegate> delegate;
///滑动阻力
@property (nonatomic) CGFloat resistance;
- (void)simulateWithVelocityY:(CGFloat)velocityY;
- (void)stop;
@end

#pragma mark-----------------

static NSString *const XKeyPath = @"contentOffset";
CGFloat const XMixScrollUndefinedValue = -999;

#define CREATE_LAZYLOAD_XMutableDic(_name) \
- (NSMutableDictionary *)_name \
{ \
    if (!_##_name) { \
        _##_name = [NSMutableDictionary new]; \
    } \
    return _##_name; \
}

@interface XMixScrollManager ()<XDynamicSimulateDelegate>
///主视图
@property (nonatomic, weak) UIScrollView *mainScrollView;
///是否已获取到contentSuperScrollView
@property (nonatomic) BOOL hasGetContentSuper;
///内容视图的横向scrollView父视图
@property (nonatomic, weak) UIScrollView *contentSuperScrollView;
///联动的内容视图
@property (nonatomic, strong) NSMutableArray *contentScrollViews;
///是否touch在主视图里 内容视图之外
@property (nonatomic) BOOL isTouchMain;
///动态模拟
@property (nonatomic, strong) XDynamicSimulate *dynamicSimulate;
///当前模拟中的contentScrollView index
@property (nonatomic) NSInteger currentSimulateIndex;
///当前展示的contentScrollView index
@property (nonatomic) NSInteger currentIndex;
///一般用不着  动态模拟判断时 不判断坐标点
@property (nonatomic) BOOL useAll;

//散装属性相关
@property (nonatomic, strong) NSMutableDictionary *indicatorTypeDic;
@property (nonatomic, strong) NSMutableDictionary *pullTypeDic;
@property (nonatomic, strong) NSMutableDictionary *scrollsToMainTopDic;
@property (nonatomic, strong) NSMutableDictionary *enableDynamicDic;
@end

@implementation XMixScrollManager

+ (instancetype)managerWithMainScrollView:(UIScrollView *)mainScrollView contentScrollViews:(NSArray<UIScrollView *> *)contentScrollViews
{
    XMixScrollManager *manager = [[XMixScrollManager alloc] initWithMainScrollView:mainScrollView contentScrollViews:contentScrollViews];
    manager.mixScrollPullType = XMixScrollPullTypeMain;
    manager.contentScrollDistance = XMixScrollUndefinedValue;
    manager.showIndicatorType = XShowIndicatorTypeChange;
    manager.scrollsToMainTop = YES;
    manager.enableDynamicSimulate = NO;
    manager.dynamicResistance = 2;
    return manager;
}

- (instancetype)initWithMainScrollView:(UIScrollView *)mainScrollView contentScrollViews:(NSArray<UIScrollView *> *)contentScrollViews
{
    if (self = [super init]) {
        self.mainScrollView = mainScrollView;
        if (!contentScrollViews) {
            contentScrollViews = @[];
        }
        self.contentScrollViews = [contentScrollViews mutableCopy];
        self.mainScrollView.p.isMain = YES;
        self.mainScrollView.p.canScroll = YES;
        self.mainScrollView.p.markScroll = YES;
        self.mainScrollView.p.scrollManager = self;
        [contentScrollViews enumerateObjectsUsingBlock:^(UIScrollView *_Nonnull contentScrollView, NSUInteger idx, BOOL *_Nonnull stop) {
            contentScrollView.p.canScroll = NO;
            contentScrollView.p.markScroll = YES;
            contentScrollView.p.index = idx;
            contentScrollView.p.scrollManager = self;
            [contentScrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        }];
        [mainScrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)addContentScrollView:(UIScrollView *)contentScrollView withIndex:(NSInteger)index
{
    contentScrollView.p.canScroll = !self.mainScrollView.p.canScroll;
    contentScrollView.p.markScroll = YES;
    contentScrollView.p.index = index;
    contentScrollView.p.scrollManager = self;
    [contentScrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    contentScrollView.p.needShowsVerticalScrollIndicator = self.showIndicatorType != XShowIndicatorTypeNone;
    if (!_contentSuperScrollView) {
        self.hasGetContentSuper = NO;
    }
    [self.contentScrollViews addObject:contentScrollView];
    [self checkScrollsToTop];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:XKeyPath]) {
        UIScrollView *scrollView = object;
        if (!scrollView.p.markScroll) {
            //横向父scrollView滑动处理
            NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
            if (scrollView.p.index != index) {
                scrollView.p.index = index;
                self.currentIndex = index;
                [self checkScrollsToTop];
                [self checkCustomConfig];
            }
            return;
        }
        if (self.contentScrollDistance == XMixScrollUndefinedValue) {
            return;
        }
        if (scrollView.p.isMain) {
            if (!scrollView.p.canScroll) {
                //特殊情况手动归位时
                if (scrollView.contentOffset.y == 0 && self.contentScrollDistance != 0) {
                    [self changeMainScrollStatus:YES];
                    return;
                }
                //content scroll滑动时 固定main scroll
                if (scrollView.contentOffset.y != self.contentScrollDistance) {
                    //点击状态栏触发scrollsToTop事件
                    if (!scrollView.isDragging) {
                        [self changeMainScrollStatus:YES];
                        return;
                    }
                    scrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
                }
                return;
            }
            if (self.enableDynamicSimulate && self.isTouchMain && self.contentScrollDistance != XMixScrollUndefinedValue) {
                if (scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded || scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
                    CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:scrollView];
                    if (velocity.y < 0 && self.contentScrollViews.count > self.currentIndex) {
                        self.currentSimulateIndex = self.currentIndex;
                        [self.dynamicSimulate simulateWithVelocityY:velocity.y];
                    }
                }
            }
            //超出范围content scroll 接手
            if ((scrollView.contentOffset.y > self.contentScrollDistance || self.contentScrollDistance == 0) && self.contentScrollDistance != XMixScrollUndefinedValue) {
                [self changeMainScrollStatus:NO];
                scrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
            }
            //是否允许下拉判断
            if (scrollView.contentOffset.y < 0) {
                if (self.mixScrollPullType == XMixScrollPullTypeNone || self.mixScrollPullType == XMixScrollPullTypeSub) {
                    scrollView.contentOffset = CGPointZero;
                }
            }
        } else {
            [self checkContentSuperScrollView];
            if (!scrollView.p.canScroll) {
                //main scroll滑动时 固定content scroll
                if (scrollView.contentOffset.y > 0) {
                    if (!scrollView.isDragging) {
                        self.mainScrollView.scrollsToTop = YES;
                        return;
                    }
                    scrollView.contentOffset = CGPointZero;
                } else if (scrollView.contentOffset.y < 0) {
                    if (self.mainScrollView.contentOffset.y > 0) {
                        scrollView.contentOffset = CGPointZero;
                    } else {
                        //是否允许下拉判断
                        if ((self.mixScrollPullType == XMixScrollPullTypeNone || self.mixScrollPullType == XMixScrollPullTypeMain)) {
                            scrollView.contentOffset = CGPointZero;
                        }
                    }
                }
                return;
            }
            //超出范围main scroll 接手
            if (scrollView.contentOffset.y < 0) {
                scrollView.contentOffset = CGPointZero;
                [self changeMainScrollStatus:YES];
            } else if (scrollView.contentOffset.y == 0) {
                if (_contentSuperScrollView && _contentSuperScrollView.p.index != scrollView.p.index) {
//                    NSLog(@"非当前contentScrollView无需处理");
                } else {
                    [self changeMainScrollStatus:YES];
                }
            } else {
                if (!self.scrollsToMainTop) {
                    if (_contentSuperScrollView && _contentSuperScrollView.p.index == scrollView.p.index) {
                        self.mainScrollView.scrollsToTop = NO;
                        scrollView.scrollsToTop = YES;
                    }
                }
            }
        }
    }
}

///获取子scrollView的父scrollView
- (void)checkContentSuperScrollView
{
    if (self.hasGetContentSuper) {
        return;
    }
    self.hasGetContentSuper = YES;
    UIScrollView *scrollView = (UIScrollView *)[self.contentScrollViews.firstObject superview];
    while (![scrollView isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)scrollView.superview;
        if (!scrollView) {
            return;
        }
    }
    _contentSuperScrollView = scrollView;
    [_contentSuperScrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
}

///校准scrollsToTop
- (void)checkScrollsToTop
{
    if (self.scrollsToMainTop || !_contentSuperScrollView) {
        self.mainScrollView.scrollsToTop = YES;
        return;
    }
    NSInteger index = _contentSuperScrollView.p.index;
    if (self.contentScrollViews.count > index) {
        UIScrollView *contentScrollView = self.contentScrollViews[index];
        self.mainScrollView.scrollsToTop = contentScrollView.contentOffset.y == 0;
        contentScrollView.scrollsToTop = !self.mainScrollView.scrollsToTop;
        contentScrollView.p.canScroll = !self.mainScrollView.p.canScroll;
    } else {
        self.mainScrollView.scrollsToTop = YES;
    }
}

///切换散装属性更新进度条状态
- (void)checkCustomConfig
{
    if (!self.enableCustomConfig) {
        return;
    }
    XShowIndicatorType indicatorType = self.showIndicatorType;
    NSNumber *indicatorValue = _indicatorTypeDic[@(self.currentIndex)];
    if (indicatorValue) {
        indicatorType = [indicatorValue intValue];
    }
    self.mainScrollView.p.needShowsVerticalScrollIndicator = indicatorType == XShowIndicatorTypeChange;
    if (self.mainScrollView.p.canScroll) {
        self.mainScrollView.showsVerticalScrollIndicator = self.mainScrollView.p.needShowsVerticalScrollIndicator;
    }
}

- (void)changeMainScrollStatus:(BOOL)mainCanScroll
{
    if (self.mainScrollView.p.canScroll == mainCanScroll) {
        return;
    }
    self.mainScrollView.scrollsToTop = YES;
    self.mainScrollView.p.canScroll = mainCanScroll;
    for (UIScrollView *contentScrollView in self.contentScrollViews) {
        contentScrollView.p.canScroll = !mainCanScroll;
        if (mainCanScroll) {
            contentScrollView.contentOffset = CGPointZero;
        }
        if (!self.scrollsToMainTop) {
            contentScrollView.scrollsToTop = !mainCanScroll;
        }
    }
}

#pragma mark- XDynamicSimulateDelegate

- (void)willMoveY:(CGFloat)movey
{
    [self handleWithMoveY:-movey];
}

- (void)handleWithMoveY:(CGFloat)movey
{
    CGFloat distancey = self.contentScrollDistance - self.mainScrollView.contentOffset.y;
    NSInteger d = distancey - movey;
    if (d > 0 && distancey > 0) {
    } else {
        UIScrollView *contentScrollView = self.contentScrollViews[self.currentSimulateIndex];
        CGPoint subContentOffset = contentScrollView.contentOffset;
        CGFloat max = contentScrollView.contentSize.height - contentScrollView.frame.size.height;
        if (contentScrollView.contentOffset.y == max) {
            return;
        }
        subContentOffset.y += -d;
        if (subContentOffset.y > max) {
            subContentOffset.y = max;
        }
        contentScrollView.contentOffset = subContentOffset;
        self.mainScrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
    }
}

#pragma mark- set get

- (void)setFixHorizontalSuperScrollView:(UIScrollView *)fixHorizontalSuperScrollView
{
    if (_contentSuperScrollView) {
        [_contentSuperScrollView removeObserver:self forKeyPath:XKeyPath];
    }
    _contentSuperScrollView = fixHorizontalSuperScrollView;
    [_contentSuperScrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    self.hasGetContentSuper = YES;
}

- (void)setDynamicResistance:(CGFloat)dynamicResistance
{
    _dynamicResistance = dynamicResistance;
    _dynamicSimulate.resistance = self.dynamicResistance;
}

- (XDynamicSimulate *)dynamicSimulate
{
    if (!_dynamicSimulate) {
        _dynamicSimulate = [XDynamicSimulate new];
        _dynamicSimulate.delegate = self;
        _dynamicSimulate.resistance = self.dynamicResistance;
    }
    return _dynamicSimulate;
}

- (void)setShowIndicatorType:(XShowIndicatorType)showIndicatorType
{
    _showIndicatorType = showIndicatorType;
    self.mainScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType == XShowIndicatorTypeChange;
    self.mainScrollView.showsVerticalScrollIndicator = self.mainScrollView.p.needShowsVerticalScrollIndicator;
    for (UIScrollView *contentScrollView in self.contentScrollViews) {
        contentScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType != XShowIndicatorTypeNone;
    }
}

#pragma mark- 散装属性相关

- (void)setShowIndicatorType:(XShowIndicatorType)showIndicatorType forScrollView:(UIScrollView *)contentScrollView
{
    if (![self.contentScrollViews containsObject:contentScrollView]) {
        return;
    }
    contentScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType != XShowIndicatorTypeNone;
    [self.indicatorTypeDic setObject:@(showIndicatorType) forKey:@(contentScrollView.p.index)];
}

- (void)setMixScrollPullType:(XMixScrollPullType)mixScrollPullType forScrollView:(UIScrollView *)contentScrollView
{
    if (![self.contentScrollViews containsObject:contentScrollView]) {
        return;
    }
    [self.pullTypeDic setObject:@(mixScrollPullType) forKey:@(contentScrollView.p.index)];
}

- (void)setScrollsToMainTop:(BOOL)scrollsToMainTop forScrollView:(UIScrollView *)contentScrollView
{
    if (![self.contentScrollViews containsObject:contentScrollView]) {
        return;
    }
    [self.scrollsToMainTopDic setObject:@(scrollsToMainTop) forKey:@(contentScrollView.p.index)];
}

- (void)setEnableDynamicSimulate:(BOOL)enableDynamicSimulate forScrollView:(UIScrollView *)contentScrollView
{
    if (![self.contentScrollViews containsObject:contentScrollView]) {
        return;
    }
    [self.enableDynamicDic setObject:@(enableDynamicSimulate) forKey:@(contentScrollView.p.index)];
}

- (XMixScrollPullType)mixScrollPullType
{
    if (!_enableCustomConfig) {
        return _mixScrollPullType;
    }
    NSNumber *number = _pullTypeDic[@(self.currentIndex)];
    return number ? [number intValue] : _mixScrollPullType;
}

- (BOOL)scrollsToMainTop
{
    if (!_enableCustomConfig) {
        return _scrollsToMainTop;
    }
    NSNumber *number = _scrollsToMainTopDic[@(self.currentIndex)];
    return number ? [number boolValue] : _scrollsToMainTop;
}

- (BOOL)enableDynamicSimulate
{
    if (!_enableCustomConfig) {
        return _enableDynamicSimulate;
    }
    NSNumber *number = _enableDynamicDic[@(self.currentIndex)];
    return number ? [number boolValue] : _enableDynamicSimulate;
}

- (void)setContentScrollDistance:(CGFloat)contentScrollDistance
{
    _contentScrollDistance = ceil(contentScrollDistance);
}

CREATE_LAZYLOAD_XMutableDic(indicatorTypeDic)
CREATE_LAZYLOAD_XMutableDic(pullTypeDic)
CREATE_LAZYLOAD_XMutableDic(scrollsToMainTopDic)
CREATE_LAZYLOAD_XMutableDic(enableDynamicDic)

#pragma mark- dealloc
- (void)dealloc
{
    [self removeObser];
//    NSLog(@"%s", __func__);
}

- (void)removeObser
{
    [_mainScrollView removeObserver:self forKeyPath:XKeyPath];
    [_contentSuperScrollView removeObserver:self forKeyPath:XKeyPath];
    for (UIScrollView *contentScrollView in _contentScrollViews) {
        [contentScrollView removeObserver:self forKeyPath:XKeyPath];
    }
}

@end

#pragma mark- ----------------其他类的实现

#pragma mark- UIScrollView category

@implementation UIScrollView (XMixScrollManager)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.p.markScroll) {
        //阻止横竖联动
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if ([scrollView isKindOfClass:[UIScrollView class]] && scrollView.p.markScroll) {
            return YES;
        }
    }
    //阻止其他意外联动
    return NO;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.p.scrollManager.enableDynamicSimulate) {
        [self.p.scrollManager.dynamicSimulate stop];
        if (self.p.isMain) {
            XMixScrollManager *scrollManager = self.p.scrollManager;
            if (scrollManager.useAll) {
                self.p.scrollManager.isTouchMain = point.y > 0;
            } else {
                scrollManager.isTouchMain = point.y < scrollManager.contentScrollDistance;
            }
        }
    }
    return [super pointInside:point withEvent:event];
}

- (XScrollViewProperty *)property
{
    XScrollViewProperty *property = objc_getAssociatedObject(self, _cmd);
    if (!property) {
        property = [XScrollViewProperty new];
        property.scrollView = self;
        objc_setAssociatedObject(self, _cmd, property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return property;
}

- (XScrollViewProperty *)p
{
    return self.property;
}

@end

@implementation XScrollViewProperty
- (void)setCanScroll:(BOOL)canScroll
{
    _canScroll = canScroll;
    if (self.needShowsVerticalScrollIndicator) {
        if (canScroll) {
            if (!self.scrollView.tracking && self.scrollManager.enableDynamicSimulate) {
                [self.scrollView flashScrollIndicators];
            }
        }
        self.scrollView.showsVerticalScrollIndicator = canScroll;
    } else {
        self.scrollView.showsVerticalScrollIndicator = NO;
    }
}

@end

#pragma mark- 惯性模拟相关
/*f(x, d, c) = (x * d * c) / (d + c * x)
 where,
 x – distance from the edge
 c – constant (UIScrollView uses 0.55)
 d – dimension, either width or height*/
static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension)
{
    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface XDynamicItem : NSObject<UIDynamicItem>
@property (nonatomic) CGPoint center;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@end

@interface XDynamicSimulate ()
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) XDynamicItem *dynamicItem;
@property (nonatomic, strong) UIView *view;
@end

@implementation XDynamicSimulate

- (instancetype)init
{
    if (self = [super init]) {
        [self initData];
    }
    return self;
}

- (void)initData
{
    self.resistance = 2;
    self.view = [UIView new];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.dynamicItem = [XDynamicItem new];
}

- (void)simulateWithVelocityY:(CGFloat)velocityY
{
    [self.animator removeAllBehaviors];
    self.dynamicItem.center = self.view.bounds.origin;
    UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
    [inertialBehavior addLinearVelocity:CGPointMake(0, velocityY) forItem:self.dynamicItem];
    inertialBehavior.resistance = self.resistance;
    __block float lastCenterY = 0;
    __weak typeof(self) weakSelf = self;
    inertialBehavior.action = ^{
        CGFloat currentY = weakSelf.dynamicItem.center.y - lastCenterY;
        [weakSelf willMoveY:currentY];
        lastCenterY = weakSelf.dynamicItem.center.y;
    };
    [self.animator addBehavior:inertialBehavior];
}

- (void)willMoveY:(CGFloat)movey
{
    const CGFloat height = [UIScreen mainScreen].bounds.size.height;
    if (self.delegate && [self.delegate respondsToSelector:@selector(willMoveY:)]) {
        [self.delegate willMoveY:rubberBandDistance(movey, height)];
    }
}

- (void)stop
{
    [self.animator removeAllBehaviors];
}

- (void)dealloc
{
//    NSLog(@"%s",__func__);
}

@end

@implementation XDynamicItem

- (instancetype)init {
    if (self = [super init]) {
        _bounds = CGRectMake(0, 0, 1, 1);
    }
    return self;
}

@end
