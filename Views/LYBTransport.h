//
//  THTransport
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol LYBTransportDelegate <NSObject>

/**
 * 播放
 */
- (void)play;
/**
 * 暂停
 */
- (void)pause;
/**
 * 停止
 */
- (void)stop;

/**
 * 拖拽滑块开始
 */
- (void)scrubbingDidStart;
/**
 * 拖拽滑块到一定时间
 */
- (void)scrubbedToTime:(NSTimeInterval)time;
/**
 * 拖拽滑块结束
 */
- (void)scrubbingDidEnd;

/**
 * 跳到指定时间
 */
- (void)jumpedToTime:(NSTimeInterval)time;

/**
 * 全屏
 */
- (void)fullScreen;

/**
 * 竖屏
 */
- (void)portraitScreen;

/**
 * 是否手动暂停
 */
- (void)manualPause:(BOOL)pause;


@optional
- (void)subtitleSelected:(NSString *)subtitle;

@end


@protocol LYBTransport <NSObject>

@property (weak, nonatomic) id <LYBTransportDelegate> delegate;
@property (nonatomic,assign)BOOL                      autorotate;

- (void)setTitle:(NSString *)title;
- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;
- (void)setScrubbingTime:(NSTimeInterval)time;
- (void)playbackComplete;
- (void)setSubtitles:(NSArray *)subtitles;
- (void)setBufferTime:(NSTimeInterval)time;
- (void)play;
- (void)pause;
- (void)setNetStream:(double)stream;

@end


