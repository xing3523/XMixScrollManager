//
//  SettingVIew.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/16.
//  Copyright © 2019 xing. All rights reserved.
//

#import "SettingVIew.h"

@interface SettingVIew ()
@property (nonatomic, strong) NSMutableArray <UISegmentedControl *> *segmentViews;
@end

@implementation SettingVIew

+ (instancetype)shareInstance
{
    static SettingVIew *view = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        view = [SettingVIew new];
    });
    return view;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setUI];
    }
    return self;
}

- (void)setUI
{
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    NSArray *titles = @[@"进度条显示:", @"支持下拉:", @"回到顶部:", @"动态模拟:", @"散装属性开启:"];
    NSArray *segmentTitles = @[@[@"hide", @"sub", @"change"],
                               @[@"none", @"main", @"sub", @"all"],
                               @[@"main", @"sub"],
                               @[@"YES", @"NO"],
                               @[@"YES", @"NO"]];
    NSMutableArray *views = [NSMutableArray new];
    UIView *view = [UIView new];
    view.layer.cornerRadius = 8;
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    for (int i = 0; i < titles.count; i++) {
        UILabel *label = [UILabel new];
        label.text = titles[i];
        [view addSubview:label];
        [views addObject:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
        }];

        UISegmentedControl *segment = [self segmentWithTitles:segmentTitles[i]];
        [view addSubview:segment];
        if (i == 0) {
            segment.selectedSegmentIndex = 2;
        } else if (i == 3 || i == 4) {
            segment.selectedSegmentIndex = 1;
        } else {
            segment.selectedSegmentIndex = 0;
        }
        [self.segmentViews addObject:segment];
        [segment mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(120);
            make.centerY.equalTo(label);
            make.right.mas_equalTo(-10);
        }];
    }
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    [views mas_distributeViewsAlongAxis:MASAxisTypeVertical withFixedSpacing:20 leadSpacing:15 tailSpacing:15];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
}

- (void)hide
{
    if (self.hideBlock) {
        self.hideBlock();
    }
    [self removeFromSuperview];
}

- (void)show
{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (UISegmentedControl *)segmentWithTitles:(NSArray *)titles
{
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:titles];
    segment.backgroundColor = [UIColor groupTableViewBackgroundColor];
    return segment;
}

- (XShowIndicatorType)showIndicatorType
{
    return self.segmentViews[0].selectedSegmentIndex;
}

- (XMixScrollPullType)mixScrollPullType
{
    return self.segmentViews[1].selectedSegmentIndex;
}

- (BOOL)scrollsToMainTop
{
    return !self.segmentViews[2].selectedSegmentIndex;
}

- (BOOL)enableDynamicSimulate
{
    return !self.segmentViews[3].selectedSegmentIndex;
}

- (BOOL)enableCustomConfig
{
    return !self.segmentViews[4].selectedSegmentIndex;
}

CREATE_LAZYLOAD(NSMutableArray, segmentViews)
@end
