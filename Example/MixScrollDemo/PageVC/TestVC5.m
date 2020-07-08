//
//  TestVC5.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/17.
//  Copyright © 2019 xing. All rights reserved.
//

#import "TestVC5.h"

@interface TestVC5 ()

@end

@implementation TestVC5

- (void)loadView
{
    UIScrollView *s = [self newScrollView];
    s.frame = [UIScreen mainScreen].bounds;
    self.view = s;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    UIScrollView *mainScrollView = (UIScrollView *)self.view;
    mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    CGFloat width = mainScrollView.bounds.size.width;
    CGFloat height = mainScrollView.bounds.size.height;
    CGFloat contentHeight = height;
    CGFloat navy = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat rheight = height - navy;
    CGFloat top = 200;
    contentHeight += top;
    UIScrollView *hs = [UIScrollView new];
    [mainScrollView addSubview:hs];
    BOOL showLabel = YES;
    CGFloat labelHeight = 80;
    CGFloat fixHeight = showLabel ? 0 : 80;
    hs.frame = CGRectMake(0, top, width, rheight + fixHeight);
    hs.pagingEnabled = YES;
    hs.showsHorizontalScrollIndicator = NO;
    NSMutableArray *contentScrollViews = [NSMutableArray new];
    int num = 3;
    for (int i = 0; i < num; i++) {
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:50];
        label.text = [NSString stringWithFormat:@"%d/%d", i + 1, num];
        label.textAlignment = NSTextAlignmentCenter;
        label.frame = CGRectMake(i * width, 0, width, labelHeight);
        [hs addSubview:label];

        //模拟需要使用fixHorizontalSuperScrollView的情况 若不修正则无法正确区分当前显示的scrollView、散装属性无法发挥作用
        if (i == 0) {
            UIScrollView *anotherSuperView = [self newScrollView];
            anotherSuperView.frame = CGRectMake(i * width, CGRectGetHeight(label.bounds), width, CGRectGetHeight(hs.bounds) - CGRectGetHeight(label.bounds));
            anotherSuperView.scrollEnabled = NO;
            [hs addSubview:anotherSuperView];

            UIScrollView *s = [self newScrollView];
            s.backgroundColor = [self randomColor];
            label.backgroundColor = s.backgroundColor;
            s.frame = anotherSuperView.bounds;
            s.contentSize = CGSizeMake(width, 2000);
            [anotherSuperView addSubview:s];
            [contentScrollViews addObject:s];
        } else {
            UIScrollView *s = [self newScrollView];
            s.backgroundColor = [self randomColor];
            label.backgroundColor = s.backgroundColor;
            s.frame = CGRectMake(i * width, CGRectGetHeight(label.bounds), width, CGRectGetHeight(hs.bounds) - CGRectGetHeight(label.bounds));
            s.contentSize = CGSizeMake(width, 2000);
            [hs addSubview:s];
            [contentScrollViews addObject:s];
        }
    }
    hs.contentSize = CGSizeMake(width * num, rheight);
    self.scrollManager = [XMixScrollManager managerWithMainScrollView:mainScrollView contentScrollViews:contentScrollViews];
    self.scrollManager.contentScrollDistance = top + fixHeight;
    self.scrollManager.fixHorizontalSuperScrollView = hs;

    UIScrollView *customCofigScrollView = contentScrollViews[1];
    [self.scrollManager setMixScrollPullType:XMixScrollPullTypeSub forScrollView:customCofigScrollView];
    [self.scrollManager setShowIndicatorType:XShowIndicatorTypeSub forScrollView:customCofigScrollView];
    [self.scrollManager setScrollsToMainTop:NO forScrollView:customCofigScrollView];
    [self.scrollManager setEnableDynamicSimulate:YES forScrollView:customCofigScrollView];

    mainScrollView.contentSize = CGSizeMake(width, contentHeight);
    [self reloadSetting];

    self.scrollManager.enableCustomConfig = YES;
}

- (UIColor *)randomColor
{
    return [UIColor colorWithRed:arc4random() % 256 / 255.0 green:arc4random() % 256 / 255.0 blue:arc4random() % 256 / 255.0 alpha:1];
}


- (UIScrollView *)newScrollView
{
    UIScrollView *scrollView = [UIScrollView new];
    __weak typeof(scrollView) weakScrollView = scrollView;
    scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakScrollView.mj_header endRefreshing];
    }];
    return scrollView;
}

@end
