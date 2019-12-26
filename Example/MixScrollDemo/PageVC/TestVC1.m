//
//  TestVC1.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/5.
//  Copyright © 2019 xing. All rights reserved.
//

#import "TestVC1.h"
@interface TestVC1 ()
@property (nonatomic, strong) UIButton *headButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) ChildView *childView;
@end

@implementation TestVC1

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView = [UIScrollView new];
    self.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(reloadData)];
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    [self addContentView];
}

- (void)addContentView
{
    CGFloat topHeight = 300;
    UIButton *button = [UIButton new];
    [button setTitle:[NSString stringWithFormat:@"height:%.0f 改变高度", topHeight] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor brownColor];
    self.headButton = button;

    [self.scrollView addSubview:button];
    CGFloat systemHeight = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets.top;
    systemHeight += CGRectGetHeight(self.navigationController.navigationBar.frame);
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scrollView);
        make.width.equalTo(self.view);
        make.height.mas_equalTo(topHeight);
        make.bottom.equalTo(self.scrollView).offset(-(self.view.frame.size.height - systemHeight));
    }];
    [self.scrollView addSubview:self.childView];

    [self.childView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(button);
        make.top.equalTo(button.mas_bottom);
        make.bottom.equalTo(self.scrollView);
    }];

    self.scrollManager = [XMixScrollManager managerWithMainScrollView:self.scrollView contentScrollViews:self.childView.scrollViewArray];
    self.scrollManager.contentScrollDistance = topHeight;
    [self reloadSetting];
}

- (void)buttonClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    CGFloat topHeight = sender.selected ? 150 : 300;
    [self.headButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(topHeight);
    }];
    [sender setTitle:[NSString stringWithFormat:@"height:%.0f 改变高度", topHeight] forState:UIControlStateNormal];
    self.scrollManager.contentScrollDistance = topHeight;
}

- (void)reloadData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView.mj_header endRefreshing];
    });
}

CREATE_LAZYLOAD(ChildView, childView)

@end
