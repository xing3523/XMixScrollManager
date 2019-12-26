//
//  TestVC2.m
//  MixScrollDemo
//
//  Created by 甘新星 on 2019/12/6.
//  Copyright © 2019 xing. All rights reserved.
//

#import "TestVC2.h"

@interface TestVC2 ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ChildView *childView;
@property (nonatomic, strong) UIView *tableHeadView;
@property (nonatomic, strong) UIButton *rightBarButton;
@property (nonatomic, strong) UITableViewCell *uniqeCell;
@property (nonatomic) NSInteger dataNum;

@end

@implementation TestVC2

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataNum = 18;
    [self setUI];
}

- (void)setUI
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"移除head" forState:UIControlStateNormal];
    [button setTitle:@"添加head" forState:UIControlStateSelected];
    [button sizeToFit];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(changeClick:) forControlEvents:UIControlEventTouchUpInside];
    self.rightBarButton = button;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    UILabel *headView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
    headView.textAlignment = NSTextAlignmentCenter;
    headView.text = @"tableHeaderView";
    headView.textColor = [UIColor whiteColor];
    headView.backgroundColor = [UIColor brownColor];
    self.tableHeadView = headView;

    self.tableView.tableHeaderView = self.tableHeadView;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
    self.scrollManager = [XMixScrollManager managerWithMainScrollView:self.tableView contentScrollViews:self.childView.scrollViewArray];
    [self reloadSetting];
}

- (void)changeClick:(UIButton *)sender
{
    sender.selected = !sender.selected;

    self.scrollManager.contentScrollDistance = XMixScrollUndefinedValue;
    self.tableView.contentOffset = CGPointZero;
    self.tableView.tableHeaderView = sender.selected ? nil : self.tableHeadView;
    [self.tableView reloadData];
}

- (void)loadData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView.mj_header endRefreshing];
        self.scrollManager.contentScrollDistance = XMixScrollUndefinedValue;
        self.tableView.tableHeaderView = self.tableView.tableHeaderView ? nil : self.tableHeadView;
        self.rightBarButton.selected = !self.tableView.tableHeaderView;
        [self.tableView reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.dataNum : 4;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastSection = tableView.numberOfSections - 1;
    if (indexPath.section == lastSection && indexPath.row == [tableView numberOfRowsInSection:lastSection] - 1) {
        if (self.scrollManager.contentScrollDistance == XMixScrollUndefinedValue) {
//            NSLog(@"%@\n%@",NSStringFromCGRect([tableView rectForRowAtIndexPath:indexPath]),NSStringFromCGRect([cell convertRect:cell.bounds toView:tableView]));
            self.scrollManager.contentScrollDistance = CGRectGetMinY(cell.frame);
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastSection = tableView.numberOfSections - 1;
    BOOL isLast = indexPath.section == lastSection && indexPath.row == [tableView numberOfRowsInSection:lastSection] - 1;
    if (isLast) {
        if (!self.uniqeCell) {
            self.uniqeCell = [tableView dequeueReusableCellWithIdentifier:@"ChildView"];
            self.uniqeCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self.uniqeCell.contentView addSubview:self.childView];
            [self.childView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(UIEdgeInsetsZero);
            }];
        }
        return self.uniqeCell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"Test%d", (int)indexPath.row + 1];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastSection = tableView.numberOfSections - 1;
    BOOL isLast = indexPath.section == lastSection && indexPath.row == [tableView numberOfRowsInSection:lastSection] - 1;
    return isLast ? CGRectGetHeight(tableView.frame) : 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *classStr = [NSString stringWithFormat:@"TestVC%d", (int)indexPath.row + 1];
    Class class = NSClassFromString(classStr);
    if (!class) {
        return;
    }
    [self.navigationController pushViewController:[NSClassFromString(classStr) new] animated:YES];
}

CREATE_LAZYLOAD(ChildView, childView)

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ChildView"];
        tableView.delegate = self;
        tableView.dataSource = self;
        _tableView = tableView;
    }
    return _tableView;
}

@end
