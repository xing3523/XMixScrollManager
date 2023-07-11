//
//  ViewController.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *textArray;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Demo";
    self.navigationController.navigationBar.translucent = NO;
    self.textArray = @[@"简单SrollView嵌套",
                       @"tableView嵌套",
                       @"collectionView嵌套",
                       @"即用式添加嵌套",
                       @"散装属性设置",
                       @"tableView嵌套collectionView（无横向）",
    ];
    [self setUI];
}

- (void)setUI
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.textArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.textArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *classStr = [NSString stringWithFormat:@"TestVC%d", (int)indexPath.row + 1];
    Class class = NSClassFromString(classStr);
    if (!class) {
        return;
    }
    UIViewController *vc = [class new];
    vc.navigationItem.title = self.textArray[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

CREATE_LAZYLOAD(UITableView, tableView)
@end

//@implementation UIScrollView (Test)
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    return YES;
//}
//
//@end
