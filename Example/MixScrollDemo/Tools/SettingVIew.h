//
//  SettingVIew.h
//  MixScrollDemo
//
//  Created by xing on 2019/12/16.
//  Copyright © 2019 xing. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingVIew : UIView

@property (nonatomic) XShowIndicatorType showIndicatorType;
@property (nonatomic) XMixScrollPullType mixScrollPullType;
@property (nonatomic) BOOL scrollsToMainTop;
@property (nonatomic) BOOL enableDynamicSimulate;
@property (nonatomic) BOOL enableCustomConfig;

@property (nonatomic, copy, nullable) void (^ hideBlock)(void);
+ (instancetype)shareInstance;
- (void)show;
@end

NS_ASSUME_NONNULL_END
