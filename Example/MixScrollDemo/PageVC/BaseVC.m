//
//  BaseVC.m
//  MixScrollDemo
//
//  Created by xing on 2019/12/16.
//  Copyright © 2019 xing. All rights reserved.
//

#import "BaseVC.h"
#import "SettingVIew.h"
@interface BaseVC ()
@property (nonatomic, strong) SettingVIew *settingView;
@property (nonatomic, strong) UIBarButtonItem *settingBarButtonItem;
@end

@implementation BaseVC

- (void)dealloc
{
//    NSLog(@"%@ dealloc", self.class);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.settingBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(showSettingView)];
    self.navigationItem.rightBarButtonItem = self.settingBarButtonItem;
}

- (void)showSettingView
{
    [self.settingView show];
}

- (void)reloadSetting
{
    if (!self.scrollManager) {
        return;
    }
    self.scrollManager.mixScrollPullType = self.mixScrollPullType;
    self.scrollManager.scrollsToMainTop = self.scrollsToMainTop;
    self.scrollManager.enableDynamicSimulate = self.enableDynamicSimulate;
    self.scrollManager.showIndicatorType = self.showIndicatorType;
    self.scrollManager.enableCustomConfig = self.enableCustomConfig;
}

- (SettingVIew *)settingView
{
    if (!_settingView) {
        _settingView = [SettingVIew shareInstance];
        __weak typeof(self) weakself = self;
        _settingView.hideBlock = ^{
            [weakself reloadSetting];
        };
    }
    return _settingView;
}

- (XShowIndicatorType)showIndicatorType
{
    return self.settingView.showIndicatorType;
}

- (XMixScrollPullType)mixScrollPullType
{
    return self.settingView.mixScrollPullType;
}

- (BOOL)scrollsToMainTop
{
    return self.settingView.scrollsToMainTop;
}

- (BOOL)enableDynamicSimulate
{
    return self.settingView.enableDynamicSimulate;
}

- (BOOL)enableCustomConfig
{
    return self.settingView.enableCustomConfig;
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
