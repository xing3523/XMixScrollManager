//
//  ChildView.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import "ChildView.h"

@interface ChildView ()<UIScrollViewDelegate>
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *contentViews;
@end

@implementation ChildView

- (instancetype)init
{
    if (self = [super init]) {
        [self initUI];
    }
    return self;
}

- (void)initUI
{
    int childNum = 5;
    NSMutableArray *items = [NSMutableArray new];
    for (int i = 0; i < childNum; i++) {
        [items addObject:[NSString stringWithFormat:@"View%d", i + 1]];
    }
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.segment = [[UISegmentedControl alloc] initWithItems:items];
    self.segment.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.segment addTarget:self action:@selector(segmentChange:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.segment];
    [self.segment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(5);
        make.centerX.equalTo(self);
    }];
    self.segment.selectedSegmentIndex = 0;
    [self addSubview:self.scrollView];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.equalTo(self.segment.mas_bottom).offset(5);
    }];

    NSMutableArray *dataArray = [NSMutableArray new];
    for (int i = 0; i < 50; i++) {
        [dataArray addObject:@"Testdata"];
    }
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    for (int i = 0; i < childNum; i++) {
        ChildContentView *contentView = [self contentViewWithIndex:i];
        [self.scrollView addSubview:contentView];
        contentView.dataArray = dataArray;
        [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.width.equalTo(self);
            make.left.mas_equalTo(width * i);
            make.bottom.equalTo(self);
            if (i == childNum - 1) {
                make.right.equalTo(self.scrollView);
            }
        }];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.segment.selectedSegmentIndex = index;
}

- (void)segmentChange:(UISegmentedControl *)segment
{
    NSInteger index = segment.selectedSegmentIndex;
    CGFloat offsetx = index * self.frame.size.width;
    [self.scrollView setContentOffset:CGPointMake(offsetx, 0) animated:YES];
}

- (ChildContentView *)contentViewWithIndex:(NSInteger)index
{
    ChildContentView *view = nil;
    if (self.contentViews.count > index) {
        view = self.contentViews[index];
    }
    if (!view) {
        view = [[ChildContentView alloc] initWithShowTableView:YES];
        [self.contentViews addObject:view];
    }
    return view;
}

- (NSArray *)scrollViewArray
{
    return [self.contentViews valueForKey:@"scrollView"];
}

CREATE_LAZYLOAD(NSMutableArray, contentViews)
CREATE_LAZYLOAD(UIScrollView, scrollView)
@end
