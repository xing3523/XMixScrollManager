//
//  XMixScrollManager.m
//  XMixScrollManager
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import "XMixScrollManager.h"
#import <objc/runtime.h>

#pragma mark - Constants

static NSString *const XKeyPath = @"contentOffset";
CGFloat const XMixScrollUndefinedValue = -999;

#pragma mark - Forward Declarations

/// Passive gesture recognizer that observes touch events without consuming them.
/// Replaces the global pointInside:withEvent: category override — only affects managed scroll views.
@interface XPTouchObserverGesture : UIGestureRecognizer
@property (nonatomic, copy, nullable) void (^onTouchBegan)(CGPoint point);
@end

/// Property container attached to each managed UIScrollView via associated objects.
@interface XScrollViewProperty : NSObject
@property (nonatomic) BOOL isMain;
@property (nonatomic) BOOL canScroll;
@property (nonatomic) BOOL needShowsVerticalScrollIndicator;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL markScroll;
@property (nonatomic) BOOL hasObserver;
@property (nonatomic, weak) XMixScrollManager *scrollManager;
@property (nonatomic, strong, nullable) XPTouchObserverGesture *touchObserver;
@end

@interface UIScrollView (XMixScrollManager) <UIGestureRecognizerDelegate>
@property (nonatomic, strong, readonly) XScrollViewProperty *p;
- (void)resetContentOffset;
@end

@protocol XDynamicSimulateDelegate <NSObject>
@optional
- (void)willMoveY:(CGFloat)movey;
@end

@interface XDynamicSimulate : NSObject
@property (nonatomic, weak) id<XDynamicSimulateDelegate> delegate;
@property (nonatomic) CGFloat resistance;
- (void)simulateWithVelocityY:(CGFloat)velocityY dimension:(CGFloat)dimension;
- (void)stop;
@end

#pragma mark - XPTouchObserverGesture Implementation

@implementation XPTouchObserverGesture

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = touches.anyObject;
    if (touch && self.view) {
        CGPoint point = [touch locationInView:self.view];
        if (self.onTouchBegan) {
            self.onTouchBegan(point);
        }
    }
    // Fail immediately — we only observe, never recognize
    self.state = UIGestureRecognizerStateFailed;
}

@end

#pragma mark - XScrollViewProperty Implementation

@implementation XScrollViewProperty
@end

#pragma mark - UIScrollView Category Implementation

@implementation UIScrollView (XMixScrollManager)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.p.markScroll) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if ([scrollView isKindOfClass:[UIScrollView class]] && scrollView.p.markScroll) {
            return YES;
        }
    }
    return NO;
}

- (XScrollViewProperty *)p {
    XScrollViewProperty *property = objc_getAssociatedObject(self, _cmd);
    if (!property) {
        property = [XScrollViewProperty new];
        objc_setAssociatedObject(self, _cmd, property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return property;
}

- (void)resetContentOffset {
    self.contentOffset = CGPointZero;
}

@end

#pragma mark - Rubber Band Distance (Pure Function)

/* f(x, d, c) = (x * d * c) / (d + c * x)
 where,
 x – distance from the edge
 c – constant (UIScrollView uses 0.55)
 d – dimension, either width or height */
static CGFloat XRubberBandDistance(CGFloat offset, CGFloat dimension) {
    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    return offset < 0.0f ? -result : result;
}

#pragma mark - XDynamicSimulate

@interface XDynamicItem : NSObject <UIDynamicItem>
@property (nonatomic) CGPoint center;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@end

@interface XDynamicSimulate ()
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) XDynamicItem *dynamicItem;
@property (nonatomic, strong) UIView *view;
@property (nonatomic) CGFloat dimension;
@end

@implementation XDynamicSimulate

- (instancetype)init {
    if (self = [super init]) {
        self.resistance = 2;
        self.view = [UIView new];
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        self.dynamicItem = [XDynamicItem new];
    }
    return self;
}

- (void)simulateWithVelocityY:(CGFloat)velocityY dimension:(CGFloat)dimension {
    self.dimension = dimension;
    [self.animator removeAllBehaviors];
    self.dynamicItem.center = self.view.bounds.origin;
    UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
    [inertialBehavior addLinearVelocity:CGPointMake(0, velocityY) forItem:self.dynamicItem];
    inertialBehavior.resistance = self.resistance;
    __block CGFloat lastCenterY = 0;
    __weak typeof(self) weakSelf = self;
    inertialBehavior.action = ^{
        CGFloat currentY = weakSelf.dynamicItem.center.y - lastCenterY;
        if (fabs(currentY) > 0.1) {
            [weakSelf willMoveY:currentY];
        }
        lastCenterY = weakSelf.dynamicItem.center.y;
    };
    [self.animator addBehavior:inertialBehavior];
}

- (void)willMoveY:(CGFloat)movey {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willMoveY:)]) {
        [self.delegate willMoveY:XRubberBandDistance(movey, self.dimension)];
    }
}

- (void)stop {
    [self.animator removeAllBehaviors];
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

#pragma mark - Lazy Dictionary Macro

#define CREATE_LAZYLOAD_XMutableDic(_name) \
- (NSMutableDictionary *)_name \
{ \
    if (!_##_name) { \
        _##_name = [NSMutableDictionary new]; \
    } \
    return _##_name; \
}

#pragma mark - XMixScrollManager Private Interface

@interface XMixScrollManager () <XDynamicSimulateDelegate>
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic) BOOL hasGetContentSuper;
@property (nonatomic, strong) UIScrollView *contentSuperScrollView;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *contentScrollViews;
@property (nonatomic) BOOL isTouchMain;
@property (nonatomic, strong) XDynamicSimulate *dynamicSimulate;
@property (nonatomic) NSInteger currentSimulateIndex;
@property (nonatomic) NSInteger currentIndex;

// Custom config dictionaries
@property (nonatomic, strong) NSMutableDictionary *indicatorTypeDic;
@property (nonatomic, strong) NSMutableDictionary *pullTypeDic;
@property (nonatomic, strong) NSMutableDictionary *scrollsToMainTopDic;
@property (nonatomic, strong) NSMutableDictionary *enableDynamicDic;
@end

#pragma mark - XMixScrollManager Implementation

@implementation XMixScrollManager

#pragma mark - Initialization

+ (instancetype)managerWithMainScrollView:(UIScrollView *)mainScrollView contentScrollViews:(NSArray<UIScrollView *> *)contentScrollViews {
    XMixScrollManager *manager = [[XMixScrollManager alloc] initWithMainScrollView:mainScrollView contentScrollViews:contentScrollViews];
    manager.mixScrollPullType = XMixScrollPullTypeMain;
    manager.contentScrollDistance = XMixScrollUndefinedValue;
    manager.showIndicatorType = XShowIndicatorTypeChange;
    manager.scrollsToMainTop = YES;
    manager.enableDynamicSimulate = NO;
    manager.dynamicResistance = 2;
    manager.mainTopHeight = XMixScrollUndefinedValue;
    return manager;
}

- (instancetype)initWithMainScrollView:(UIScrollView *)mainScrollView contentScrollViews:(NSArray<UIScrollView *> *)contentScrollViews {
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
        [self addObserverForScrollView:mainScrollView];
        [self addTouchObserverToScrollView:mainScrollView isMain:YES];

        [contentScrollViews enumerateObjectsUsingBlock:^(UIScrollView *_Nonnull contentScrollView, NSUInteger idx, BOOL *_Nonnull stop) {
            contentScrollView.p.canScroll = NO;
            contentScrollView.p.markScroll = YES;
            contentScrollView.p.index = idx;
            contentScrollView.p.scrollManager = self;
            contentScrollView.p.needShowsVerticalScrollIndicator = self.showIndicatorType != XShowIndicatorTypeNone;
            [self addObserverForScrollView:contentScrollView];
            [self addTouchObserverToScrollView:contentScrollView isMain:NO];
        }];

        self.showIndicatorType = XShowIndicatorTypeChange;
    }
    return self;
}

- (void)dealloc {
    // Clean up main scroll view
    [self removeObserverFromScrollView:_mainScrollView];
    _mainScrollView.p.markScroll = NO;
    _mainScrollView.p.isMain = NO;
    [self removeTouchObserverFromScrollView:_mainScrollView];

    // Clean up content scroll views
    for (UIScrollView *scrollView in _contentScrollViews) {
        [self removeObserverFromScrollView:scrollView];
        scrollView.p.markScroll = NO;
        scrollView.p.scrollManager = nil;
        [self removeTouchObserverFromScrollView:scrollView];
    }

    // Clean up content super scroll view
    [self removeObserverFromScrollView:_contentSuperScrollView];

    [_dynamicSimulate stop];
}

#pragma mark - Add / Remove Content ScrollView

- (void)addContentScrollView:(UIScrollView *)contentScrollView withIndex:(NSInteger)index {
    contentScrollView.p.canScroll = !self.mainScrollView.p.canScroll;
    contentScrollView.p.markScroll = YES;
    contentScrollView.p.index = index;
    contentScrollView.p.scrollManager = self;
    contentScrollView.p.needShowsVerticalScrollIndicator = self.showIndicatorType != XShowIndicatorTypeNone;

    if (!_contentSuperScrollView) {
        self.hasGetContentSuper = NO;
    }

    [self addObserverForScrollView:contentScrollView];
    [self addTouchObserverToScrollView:contentScrollView isMain:NO];
    [self.contentScrollViews addObject:contentScrollView];
    [self checkScrollsToTop];
}

- (void)removeContentScrollView:(UIScrollView *)contentScrollView {
    [self removeObserverFromScrollView:contentScrollView];
    contentScrollView.p.markScroll = NO;
    contentScrollView.p.scrollManager = nil;
    [self removeTouchObserverFromScrollView:contentScrollView];
    [self.contentScrollViews removeObject:contentScrollView];
    [self checkScrollsToTop];
}

#pragma mark - KVO Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (![keyPath isEqualToString:XKeyPath]) return;

    if (![object isKindOfClass:[UIScrollView class]]) return;
    UIScrollView *scrollView = object;

    if (!scrollView.p.markScroll) {
        [self handleHorizontalScroll:scrollView];
        return;
    }

    if (self.contentScrollDistance == XMixScrollUndefinedValue) {
        return;
    }

    if (scrollView.p.isMain) {
        [self handleMainScroll:scrollView];
    } else {
        [self handleContentScroll:scrollView];
    }
}

#pragma mark - Scroll Handling

- (void)handleHorizontalScroll:(UIScrollView *)scrollView {
    if (scrollView.frame.size.width <= 0) return;
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    if (index < 0) return;
    if (scrollView.p.index != index) {
        scrollView.p.index = index;
        self.currentIndex = index;
        [self checkScrollsToTop];
        [self checkCustomConfig];
    }
}

- (void)handleMainScroll:(UIScrollView *)scrollView {
    if (!scrollView.p.canScroll) {
        [self handleMainScrollWhenCannotScroll:scrollView];
        return;
    }

    if (self.enableDynamicSimulate && self.isTouchMain) {
        [self handleDynamicSimulation:scrollView];
    }

    if (scrollView.contentOffset.y > self.contentScrollDistance || self.contentScrollDistance == 0) {
        [self handleMainScrollRange:scrollView];
    }

    if (scrollView.contentOffset.y < 0) {
        [self handleMainScrollPull:scrollView];
    }
}

- (void)handleMainScrollWhenCannotScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y == 0 && self.contentScrollDistance != 0) {
        [self changeMainScrollStatus:YES];
        return;
    }

    if (scrollView.contentOffset.y != self.contentScrollDistance) {
        if (!scrollView.isDragging) {
            [self changeMainScrollStatus:YES];
            return;
        }
        scrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
    }
}

- (void)handleDynamicSimulation:(UIScrollView *)scrollView {
    UIGestureRecognizerState state = scrollView.panGestureRecognizer.state;
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateChanged) {
        CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:scrollView];
        if (velocity.y < 0 && (NSInteger)self.contentScrollViews.count > self.currentIndex) {
            self.currentSimulateIndex = self.currentIndex;
            [self.dynamicSimulate simulateWithVelocityY:velocity.y dimension:[self screenHeightForView:scrollView]];
        }
    }
}

- (CGFloat)screenHeightForView:(UIView *)view {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = view.window.windowScene;
        if (windowScene) {
            return windowScene.screen.bounds.size.height;
        }
    }
    return [UIScreen mainScreen].bounds.size.height;
}

- (void)handleMainScrollRange:(UIScrollView *)scrollView {
    if (self.contentScrollViews.count == 0) {
        [self changeMainScrollStatus:YES];
        scrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
        return;
    }

    if (self.currentIndex >= (NSInteger)self.contentScrollViews.count) return;
    UIScrollView *contentScrollView = self.contentScrollViews[self.currentIndex];
    BOOL needMainScroll = contentScrollView.contentSize.height <= contentScrollView.frame.size.height;

    [self changeMainScrollStatus:needMainScroll];
    scrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
}

- (void)handleMainScrollPull:(UIScrollView *)scrollView {
    if (self.mixScrollPullType == XMixScrollPullTypeNone || self.mixScrollPullType == XMixScrollPullTypeSub) {
        scrollView.contentOffset = CGPointZero;
    }
}

- (void)handleContentScroll:(UIScrollView *)scrollView {
    [self checkContentSuperScrollView];

    if (!scrollView.p.canScroll) {
        [self handleContentScrollWhenCannotScroll:scrollView];
        return;
    }

    [self handleContentScrollRange:scrollView];
    [self handleContentScrollToTop:scrollView];
}

- (void)handleContentScrollWhenCannotScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > 0) {
        if (!scrollView.isDragging) {
            self.mainScrollView.scrollsToTop = YES;
            return;
        }
        scrollView.contentOffset = CGPointZero;
    } else if (scrollView.contentOffset.y < 0) {
        if (self.mainScrollView.contentOffset.y > 0) {
            scrollView.contentOffset = CGPointZero;
        } else if (self.mixScrollPullType == XMixScrollPullTypeNone || self.mixScrollPullType == XMixScrollPullTypeMain) {
            scrollView.contentOffset = CGPointZero;
        }
    }
}

- (void)handleContentScrollRange:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointZero;
        [self changeMainScrollStatus:YES];
    } else if (scrollView.contentOffset.y == 0) {
        if (_contentSuperScrollView && _contentSuperScrollView.p.index != scrollView.p.index) {
            // Non-current contentScrollView, no processing needed
        } else {
            [self changeMainScrollStatus:YES];
        }
    }
}

- (void)handleContentScrollToTop:(UIScrollView *)scrollView {
    if (!self.scrollsToMainTop) {
        if (_contentSuperScrollView && _contentSuperScrollView.p.index == scrollView.p.index) {
            self.mainScrollView.scrollsToTop = NO;
            scrollView.scrollsToTop = YES;
        }
    }
}

#pragma mark - XDynamicSimulateDelegate

- (void)willMoveY:(CGFloat)movey {
    [self handleWithMoveY:-movey];
}

- (void)handleWithMoveY:(CGFloat)movey {
    if (self.contentScrollDistance == XMixScrollUndefinedValue) return;

    CGFloat distancey = self.contentScrollDistance - self.mainScrollView.contentOffset.y;
    CGFloat d = distancey - movey;

    if (d > 0 && distancey > 0) return;

    if ((NSInteger)self.contentScrollViews.count <= self.currentSimulateIndex) return;
    UIScrollView *contentScrollView = self.contentScrollViews[self.currentSimulateIndex];

    CGFloat maxOffset = MAX(0, contentScrollView.contentSize.height - contentScrollView.frame.size.height);
    if (contentScrollView.contentOffset.y >= maxOffset) return;

    CGPoint subContentOffset = contentScrollView.contentOffset;
    subContentOffset.y += -d;
    subContentOffset.y = MIN(subContentOffset.y, maxOffset);
    subContentOffset.y = MAX(0, subContentOffset.y);

    contentScrollView.contentOffset = subContentOffset;
    self.mainScrollView.contentOffset = CGPointMake(0, self.contentScrollDistance);
}

#pragma mark - Observation (Safe Add / Remove)

- (void)addObserverForScrollView:(UIScrollView *)scrollView {
    if (!scrollView || scrollView.p.hasObserver) return;
    [scrollView addObserver:self forKeyPath:XKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    scrollView.p.hasObserver = YES;
}

- (void)removeObserverFromScrollView:(UIScrollView *)scrollView {
    if (!scrollView || !scrollView.p.hasObserver) return;
    @try {
        [scrollView removeObserver:self forKeyPath:XKeyPath];
    } @catch (NSException *exception) {
        // Safety: prevent crash if observer was already removed
    }
    scrollView.p.hasObserver = NO;
}

#pragma mark - Touch Observer (Gesture-Based)

- (void)addTouchObserverToScrollView:(UIScrollView *)scrollView isMain:(BOOL)isMain {
    if (!scrollView || scrollView.p.touchObserver) return;

    XPTouchObserverGesture *observer = [XPTouchObserverGesture new];
    observer.cancelsTouchesInView = NO;
    observer.delaysTouchesBegan = NO;

    __weak typeof(self) weakSelf = self;
    observer.onTouchBegan = ^(CGPoint point) {
        XMixScrollManager *manager = weakSelf;
        if (!manager) return;
        if (manager.enableDynamicSimulate) {
            [manager.dynamicSimulate stop];
        }
        if (isMain) {
            if (manager.useAll) {
                manager.isTouchMain = point.y > 0;
            } else if (manager.mainTopHeight > 0 && manager.contentScrollDistance > 0) {
                manager.isTouchMain = point.y < manager.mainTopHeight;
            } else {
                manager.isTouchMain = point.y < manager.contentScrollDistance;
            }
        }
    };

    [scrollView addGestureRecognizer:observer];
    scrollView.p.touchObserver = observer;
}

- (void)removeTouchObserverFromScrollView:(UIScrollView *)scrollView {
    if (!scrollView) return;
    if (scrollView.p.touchObserver) {
        [scrollView removeGestureRecognizer:scrollView.p.touchObserver];
    }
    scrollView.p.touchObserver = nil;
}

#pragma mark - Scroll Status Management

- (void)checkScrollsToTop {
    if (self.scrollsToMainTop || !_contentSuperScrollView) {
        self.mainScrollView.scrollsToTop = YES;
        return;
    }
    NSInteger index = _contentSuperScrollView.p.index;
    if ((NSInteger)self.contentScrollViews.count > index) {
        UIScrollView *contentScrollView = self.contentScrollViews[index];
        self.mainScrollView.scrollsToTop = NO;
        contentScrollView.scrollsToTop = YES;
        contentScrollView.p.canScroll = !self.mainScrollView.p.canScroll;
    } else {
        self.mainScrollView.scrollsToTop = YES;
    }
}

- (void)checkCustomConfig {
    if (!self.enableCustomConfig) return;

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

- (void)changeMainScrollStatus:(BOOL)mainCanScroll {
    if (self.mainScrollView.p.canScroll == mainCanScroll) return;

    self.mainScrollView.p.canScroll = mainCanScroll;
    self.mainScrollView.scrollsToTop = YES;
    [self updateScrollIndicatorStateForScrollView:self.mainScrollView];

    for (UIScrollView *contentScrollView in self.contentScrollViews) {
        contentScrollView.p.canScroll = !mainCanScroll;
        [self updateScrollIndicatorStateForScrollView:contentScrollView];
        if (mainCanScroll) {
            contentScrollView.contentOffset = CGPointZero;
        }
        if (!self.scrollsToMainTop) {
            contentScrollView.scrollsToTop = !mainCanScroll;
        }
    }
}

- (void)updateScrollIndicatorStateForScrollView:(UIScrollView *)scrollView {
    XScrollViewProperty *p = scrollView.p;
    if (p.needShowsVerticalScrollIndicator) {
        scrollView.showsVerticalScrollIndicator = p.canScroll;
        if (p.canScroll && !scrollView.isTracking && self.enableDynamicSimulate) {
            [scrollView flashScrollIndicators];
        }
    } else {
        scrollView.showsVerticalScrollIndicator = NO;
    }
}

- (void)checkContentSuperScrollView {
    if (self.hasGetContentSuper) return;
    self.hasGetContentSuper = YES;
    if (self.contentScrollViews.count == 0) return;

    UIScrollView *scrollView = (UIScrollView *)[self.contentScrollViews.firstObject superview];
    while (![scrollView isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)scrollView.superview;
        if (!scrollView) return;
    }
    if (scrollView.p.markScroll) return;
    _contentSuperScrollView = scrollView;
    [self addObserverForScrollView:_contentSuperScrollView];
}

#pragma mark - Setters / Getters

- (void)setFixHorizontalSuperScrollView:(UIScrollView *)fixHorizontalSuperScrollView {
    [self removeObserverFromScrollView:_contentSuperScrollView];
    _contentSuperScrollView = fixHorizontalSuperScrollView;
    [self addObserverForScrollView:_contentSuperScrollView];
    self.hasGetContentSuper = YES;
}

- (void)setDynamicResistance:(CGFloat)dynamicResistance {
    _dynamicResistance = dynamicResistance;
    _dynamicSimulate.resistance = dynamicResistance;
}

- (XDynamicSimulate *)dynamicSimulate {
    if (!_dynamicSimulate) {
        _dynamicSimulate = [XDynamicSimulate new];
        _dynamicSimulate.delegate = self;
        _dynamicSimulate.resistance = self.dynamicResistance;
    }
    return _dynamicSimulate;
}

- (void)setShowIndicatorType:(XShowIndicatorType)showIndicatorType {
    _showIndicatorType = showIndicatorType;
    self.mainScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType == XShowIndicatorTypeChange;
    self.mainScrollView.showsVerticalScrollIndicator = self.mainScrollView.p.needShowsVerticalScrollIndicator;
    for (UIScrollView *contentScrollView in self.contentScrollViews) {
        contentScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType != XShowIndicatorTypeNone;
    }
}

- (void)setContentScrollDistance:(CGFloat)contentScrollDistance {
    _contentScrollDistance = ceil(contentScrollDistance);
}

#pragma mark - Custom Config Setters

- (void)setShowIndicatorType:(XShowIndicatorType)showIndicatorType forScrollView:(UIScrollView *)contentScrollView {
    if (![self.contentScrollViews containsObject:contentScrollView]) return;
    contentScrollView.p.needShowsVerticalScrollIndicator = showIndicatorType != XShowIndicatorTypeNone;
    [self.indicatorTypeDic setObject:@(showIndicatorType) forKey:@(contentScrollView.p.index)];
}

- (void)setMixScrollPullType:(XMixScrollPullType)mixScrollPullType forScrollView:(UIScrollView *)contentScrollView {
    if (![self.contentScrollViews containsObject:contentScrollView]) return;
    [self.pullTypeDic setObject:@(mixScrollPullType) forKey:@(contentScrollView.p.index)];
}

- (void)setScrollsToMainTop:(BOOL)scrollsToMainTop forScrollView:(UIScrollView *)contentScrollView {
    if (![self.contentScrollViews containsObject:contentScrollView]) return;
    [self.scrollsToMainTopDic setObject:@(scrollsToMainTop) forKey:@(contentScrollView.p.index)];
}

- (void)setEnableDynamicSimulate:(BOOL)enableDynamicSimulate forScrollView:(UIScrollView *)contentScrollView {
    if (![self.contentScrollViews containsObject:contentScrollView]) return;
    [self.enableDynamicDic setObject:@(enableDynamicSimulate) forKey:@(contentScrollView.p.index)];
}

- (XMixScrollPullType)mixScrollPullType {
    if (!_enableCustomConfig) return _mixScrollPullType;
    NSNumber *number = _pullTypeDic[@(self.currentIndex)];
    return number ? [number intValue] : _mixScrollPullType;
}

- (BOOL)scrollsToMainTop {
    if (!_enableCustomConfig) return _scrollsToMainTop;
    NSNumber *number = _scrollsToMainTopDic[@(self.currentIndex)];
    return number ? [number boolValue] : _scrollsToMainTop;
}

- (BOOL)enableDynamicSimulate {
    if (!_enableCustomConfig) return _enableDynamicSimulate;
    NSNumber *number = _enableDynamicDic[@(self.currentIndex)];
    return number ? [number boolValue] : _enableDynamicSimulate;
}

CREATE_LAZYLOAD_XMutableDic(indicatorTypeDic)
CREATE_LAZYLOAD_XMutableDic(pullTypeDic)
CREATE_LAZYLOAD_XMutableDic(scrollsToMainTopDic)
CREATE_LAZYLOAD_XMutableDic(enableDynamicDic)

@end
