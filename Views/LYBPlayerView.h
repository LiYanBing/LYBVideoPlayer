//
//  LYBPlayerView.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "LYBTransport.h"

@class AVPlayer;

@interface LYBPlayerView : UIView
/**
 * 记录原始Frame
 */
@property (nonatomic,assign)CGRect    originalFrame;

/**
 * 后续播放
 */
@property (nonatomic ,strong) AVPlayer *player;

/**
 * 初始化时直接播放
 */
+ (instancetype)initWithPlayer:(AVPlayer *)player;

/**
 * 是否支持屏幕旋转
 */
@property (nonatomic,assign)BOOL  autorotate;


@property (nonatomic, readonly) id <LYBTransport> transport;

/**
 * 竖屏
 */
- (void)portraitScreen;

/**
 * 左横屏
 */
- (void)leftScreen;


@end
