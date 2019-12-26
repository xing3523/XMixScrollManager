//
//  TestVC3.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/6.
//  Copyright © 2019 xing. All rights reserved.
//

#import "TestVC3.h"
#import "ChildVC.h"

@interface TestVC3 ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic) NSInteger sectionNum;
@property (nonatomic, strong) UICollectionViewCell *uniqueCell;
@property (nonatomic, strong) ChildVC *childVC;
@end

@implementation TestVC3

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.sectionNum = 3;
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    self.scrollManager = [XMixScrollManager managerWithMainScrollView:self.collectionView contentScrollViews:self.childVC.mixScrollViewArray];
    [self reloadSetting];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.sectionNum;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self isLastSection:section]) {
        return 1;
    }
    return 20;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self cellForIndexPath:indexPath];
    return cell;
}

- (UICollectionViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    if ([self isLastSection:indexPath.section]) {
        if (self.uniqueCell) {
            return self.uniqueCell;
        }
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"uniqueCell"];
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"uniqueCell" forIndexPath:indexPath];
        [self addChildViewController:self.childVC];
        [cell addSubview:self.childVC.view];
        [self.childVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
        self.uniqueCell = cell;
        return cell;
    } else {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor redColor];
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastSection:indexPath.section]) {
        return collectionView.frame.size;
    }
    return CGSizeMake(100, 120);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if ([self isLastSection:section]) {
        return UIEdgeInsetsZero;
    }
    return UIEdgeInsetsMake(10, 10, 0, 10);
}

/*
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return nil;
    }
    UICollectionReusableView *reuseView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"head" forIndexPath:indexPath];
    reuseView.backgroundColor = [self isLastSection:indexPath.section] ? [UIColor blackColor] : [UIColor grayColor];
    return reuseView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(collectionView.frame.size.width, 60);
}*/

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastSection:indexPath.section]) {
        if (self.scrollManager.contentScrollDistance == XMixScrollUndefinedValue) {
            self.scrollManager.contentScrollDistance = CGRectGetMinY(cell.frame);
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"indexPath:%d-%d", (int)indexPath.section, (int)indexPath.item);
}

- (BOOL)isLastSection:(NSInteger)section
{
    return section == self.sectionNum - 1;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *fl = [UICollectionViewFlowLayout new];
        fl.minimumLineSpacing = 10;
        fl.minimumInteritemSpacing = 10;
//        fl.sectionHeadersPinToVisibleBounds = YES;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:fl];
        collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"head"];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        _collectionView = collectionView;
    }
    return _collectionView;
}

CREATE_LAZYLOAD(ChildVC, childVC)
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
