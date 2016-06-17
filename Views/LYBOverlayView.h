//
//  LYBOverlayView.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//
/**
 说明
 
 */

#import <UIKit/UIKit.h>
#import "LYBTransport.h"

typedef NS_ENUM(NSInteger,UIScreenType){
    UIScreenTypePortrait,
    UIScreenTypeLeft,
    UIScreenTypeRight
};


@interface LYBOverlayView : UIView<LYBTransport>

/**
 * 是否全屏
 */
@property (nonatomic,assign) BOOL           isFullScreen;

/**
 * screenFrame
 */
@property (nonatomic,assign)CGRect     normalFrame;

/**
 * 顶部
 */
@property (weak, nonatomic) IBOutlet UINavigationBar *navgationBar;

@property (weak, nonatomic) IBOutlet UIButton *filmstripToggleButton;

/**
 * 拖动显示时间View
 */
@property (weak, nonatomic) IBOutlet UIView *infoView;

/**
 * 拖动显示时间Label
 */
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;


/**
 * 底部
 */
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
/**
 * 播放与暂停按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *togglePlaybackButton;

/**
 * 已经播放时间
 */
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

/**
 * 滑块
 */
@property (weak, nonatomic) IBOutlet UISlider *scrubberSlider;

/**
 * 缓冲进度条
 */
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;


/**
 * 总时间
 */
@property (weak, nonatomic) IBOutlet UILabel *remindingTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *fullbutton;

/**
 * 是否支持屏幕旋转
 */
@property (nonatomic,assign)BOOL  autorotate;

/**
 * 网络提示框
 */
@property (weak, nonatomic) IBOutlet UIView *netAlertView;

/**
 * 网速
 */
@property (weak, nonatomic) IBOutlet UILabel *netStreamLabel;

/**
 * 正在缓冲
 */
@property (weak, nonatomic) IBOutlet UILabel *buffingLabel;

/**
 * 菊花
 */
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activeView;

@property (nonatomic,assign) UIScreenType   screenType;
@property (weak, nonatomic) id <LYBTransportDelegate> delegate;

- (void)setCurrentTime:(NSTimeInterval)time;

@end
