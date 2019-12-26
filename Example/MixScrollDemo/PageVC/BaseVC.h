//
//  BaseVC.h
//  MixScrollDemo
//
//  Created by xing on 2019/12/16.
//  Copyright © 2019 xing. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseVC : UIViewController
@property (nonatomic) XShowIndicatorType showIndicatorType;
@property (nonatomic) XMixScrollPullType mixScrollPullType;
@property (nonatomic) BOOL scrollsToMainTop;
@property (nonatomic) BOOL enableDynamicSimulate;
@property (nonatomic) BOOL enableCustomConfig;

@property (nonatomic, strong, readonly) UIBarButtonItem *settingBarButtonItem;
@property (nonatomic, strong, nullable) XMixScrollManager *scrollManager;
- (void)reloadSetting;
@end

NS_ASSUME_NONNULL_END
