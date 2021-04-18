//
//  TestVC6.m
//  MixScrollDemo
//
//  Created by xing on 2022/5/24.
//  Copyright © 2022 xing. All rights reserved.
//

#import "TestVC6.h"

@interface TestVC6 ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ChildView *childView;
@property (nonatomic, strong) UIView *tableHeadView;
@property (nonatomic, strong) UITableViewCell *uniqeCell;
@property (nonatomic) NSInteger dataNum;
@property (nonatomic) NSInteger data2Num;
@property (nonatomic) NSInteger data2AllNum;
@end

@implementation TestVC6

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataNum = 5;
    self.data2Num = 30;
    self.data2AllNum = 60;
    [self setUI];
}

- (void)setUI
{
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
    self.scrollManager = [XMixScrollManager managerWithMainScrollView:self.tableView contentScrollViews:@[self.collectionView]];
    [self reloadSetting];
}

///MARK:- UITableView
- (void)loadData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView.mj_header endRefreshing];
        self.scrollManager.contentScrollDistance = XMixScrollUndefinedValue;
        self.tableView.tableHeaderView = self.tableView.tableHeaderView ? nil : self.tableHeadView;
        [self.tableView reloadData];
        self.data2Num = 30;
        [self.collectionView reloadData];
        [self.collectionView.mj_footer resetNoMoreData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.dataNum : 1;
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
            UIScrollView *superScrollView = [UIScrollView new];
            [self.uniqeCell.contentView addSubview:superScrollView];
            [superScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(UIEdgeInsetsZero);
            }];
            [superScrollView addSubview:self.collectionView];
            [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(UIEdgeInsetsZero);
                make.size.mas_equalTo(self.uniqeCell.contentView);
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

///MARK: - UICollectionView
- (void)refresh {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.data2Num = 30;
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer resetNoMoreData];
        [self.collectionView reloadData];
    });
}

- (void)loadMore {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.data2Num += 10;
        if (self.data2Num >= self.data2AllNum) {
            self.data2Num = self.data2AllNum;
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.collectionView.mj_footer endRefreshing];
        }
        [self.collectionView reloadData];
    });
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.data2Num;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self cellForIndexPath:indexPath];
    return cell;
}

- (UICollectionViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"foot" forIndexPath:indexPath];
        view.backgroundColor = [UIColor cyanColor];
        return view;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 120);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.data2Num < self.data2AllNum) {
        return CGSizeZero;
    }
    return CGSizeMake(collectionView.frame.size.width, 150);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 0, 10);
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
        fl.minimumLineSpacing = 10;
        fl.minimumInteritemSpacing = 10;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:fl];
        collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
        collectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
        collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"foot"];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        _collectionView = collectionView;
    }
    return _collectionView;
}

@end
