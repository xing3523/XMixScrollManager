//
//  ChildContentView.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import "ChildContentView.h"
@interface ChildContentView ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic) BOOL showTable;
@end

@implementation ChildContentView

- (instancetype)initWithShowTableView:(BOOL)showTable
{
    if (self = [super init]) {
        self.showTable = showTable;
        [self initUI];
    }
    return self;
}

- (void)initUI
{
    if (self.showTable) {
        [self addSubview:self.tableView];
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    } else {
        [self addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
    self.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
    self.scrollView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
}

- (void)loadData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView.mj_header endRefreshing];
    });
}

- (void)loadMoreData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView.mj_footer endRefreshing];
        NSArray *array = @[@"add", @"add", @"add", @"add", @"add"];
        NSMutableArray *dataArray = [self.dataArray mutableCopy];
        [dataArray addObjectsFromArray:array];
        self.dataArray = [dataArray copy];
        [self.scrollView performSelector:@selector(reloadData)];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%d-%@", (int)indexPath.row + 1, self.dataArray[indexPath.row]];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [self colorWithIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (UIColor *)colorWithIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = (indexPath.item / 3) % 3;
    if (index == 0) {
        return [UIColor brownColor];
    } else if (index == 1) {
        return [UIColor purpleColor];
    } else {
        return [UIColor cyanColor];
    }
}

- (void)setDataArray:(NSArray *)dataArray
{
    _dataArray = dataArray;
    self.showTable ? [self.tableView reloadData] : [self.collectionView reloadData];
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
        fl.minimumLineSpacing = 10;
        fl.minimumInteritemSpacing = 10;
        fl.itemSize = CGSizeMake(100, 120);
        fl.scrollDirection = UICollectionViewScrollDirectionVertical;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:fl];
        collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [UITableView new];
        tableView.dataSource = self;
        tableView.delegate = self;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _tableView = tableView;
    }
    return _tableView;
}

- (UIScrollView *)scrollView
{
    return self.showTable ? self.tableView : self.collectionView;
}

@end
