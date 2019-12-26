//
//  ChildContentView.h
//  MixScrollDemo
//
//  Created by xing on 2019/12/3.
//  Copyright © 2019 xing. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ChildContentView : UIView
- (instancetype)initWithShowTableView:(BOOL)showTable;
@property (nonatomic, copy) NSArray *dataArray;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@end

NS_ASSUME_NONNULL_END
