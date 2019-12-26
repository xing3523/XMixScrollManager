//
//  ChildContentVC.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/6.
//  Copyright © 2019 xing. All rights reserved.
//

#import "ChildContentVC.h"

@interface ChildContentVC ()
@property (nonatomic, strong) ChildContentView *childContentView;
@end

@implementation ChildContentVC

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *array = [NSMutableArray new];
    for (int i = 0; i < 50; i++) {
        [array addObject:@"Data"];
    }
    self.childContentView.dataArray = array;
    [self.view addSubview:self.childContentView];
    [self.childContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (UIScrollView *)mixScrollView
{
    return self.childContentView.scrollView;
}

- (ChildContentView *)childContentView
{
    if (!_childContentView) {
        _childContentView = [[ChildContentView alloc] initWithShowTableView:NO];
    }
    return _childContentView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
