//
//  ChildVC.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/8.
//  Copyright © 2019 xing. All rights reserved.
//

#import "ChildVC.h"
#import "ChildContentVC.h"
@interface ChildVC ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) NSMutableArray *contentVCArray;
@end

@implementation ChildVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:self.segment];
    self.segment.selectedSegmentIndex = 0;
    [self.segment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.mas_equalTo(5);
    }];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.equalTo(self.segment.mas_bottom).offset(5);
    }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.segment.selectedSegmentIndex = index;
}

- (void)segmentChange:(UISegmentedControl *)segment
{
    NSInteger index = segment.selectedSegmentIndex;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.contentVCArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForIndexPath:indexPath];
}

- (UICollectionViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    if (self.cellArray.count > indexPath.row) {
        cell = self.cellArray[indexPath.row];
        return cell;
    }
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:[self reuseIdentifierWithIndex:indexPath.row]];
    cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[self reuseIdentifierWithIndex:indexPath.item] forIndexPath:indexPath];
    ChildContentVC *vc = self.contentVCArray[indexPath.item];
    [self addChildViewController:vc];
    [cell.contentView addSubview:vc.view];
    [vc.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    [self.cellArray addObject:cell];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.frame.size;
}

- (NSString *)reuseIdentifierWithIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"cellIdentifier%d", (int)index];
}

- (NSArray *)mixScrollViewArray
{
    return [self.contentVCArray valueForKey:@"mixScrollView"];
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
        fl.minimumLineSpacing = 0;
        fl.minimumInteritemSpacing = 0;
        fl.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:fl];
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.pagingEnabled = YES;
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (UISegmentedControl *)segment
{
    if (!_segment) {
        NSMutableArray *items = [NSMutableArray new];
        for (int i = 0; i < self.contentVCArray.count; i++) {
            [items addObject:[NSString stringWithFormat:@"VC%d", i + 1]];
        }
        UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:items];
        segment.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [segment addTarget:self action:@selector(segmentChange:) forControlEvents:UIControlEventValueChanged];
        _segment = segment;
    }
    return _segment;
}

- (NSMutableArray *)contentVCArray
{
    if (!_contentVCArray) {
        NSMutableArray *array = [NSMutableArray new];
        for (int i = 0; i < 5; i++) {
            ChildContentVC *contentVC = [ChildContentVC new];
            [array addObject:contentVC];
        }
        _contentVCArray = array;
    }
    return _contentVCArray;
}

CREATE_LAZYLOAD(NSMutableArray, cellArray)
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
