# XMixScrollManager

## 介绍
管理UIScrollView嵌套滑动的一个小组件。
通过KVO实现，无UI布局，低耦合。

## 主要功能
- 支持滑动进度条可选择是否显示；
- 支持嵌套主次UIScrollView可选择是否允许下拉；
- 支持点击状态栏可选择主次UIScrollView回到顶部；
- 支持主次UIScrollView滑动过渡可选择惯性模拟移动。


## 使用方法
简单使用
``` 
self.scrollManager = [XMixScrollManager managerWithMainScrollView:mainScrollView contentScrollViews:@[contentScrollView1,contentScrollView2]];
self.scrollManager.contentScrollDistance = 300;
```

XMixScrollManager不关注UI布局，contentScrollDistance需要传入准确的值。

## 部分效果图
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图1.gif)
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图2.gif)
## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'XMixScrollManager'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 <XMixScrollManager.h>。

## 系统要求
`iOS 8.0+`
