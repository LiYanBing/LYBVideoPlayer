//
//  LYBPlayerView.m
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "LYBPlayerView.h"
#import "LYBOverlayView.h"

#define WIDTH   [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height

@interface LYBPlayerView()

/**
 * 提供用户界面中操作视频播放的控件
 */
@property (strong, nonatomic) LYBOverlayView *overlayView;

@end

@implementation LYBPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    AVPlayerLayer * layer = (AVPlayerLayer *)[self layer];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (instancetype)init{
    if (self = [super init]) {
        self.frame = CGRectZero;
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
        UIViewAutoresizingFlexibleWidth;
        
        NSArray * nib =  [[NSBundle mainBundle] loadNibNamed:@"LYBOverlayView"
                                                       owner:self
                                                     options:nil];
        self.overlayView = [nib firstObject];
        [self addSubview:_overlayView];
    }
    return self;
}

+ (instancetype)initWithPlayer:(AVPlayer *)player {
    LYBPlayerView * playerView = [[self alloc] init];
    [playerView setPlayer:player];
    return playerView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayView.normalFrame = self.bounds;
}

- (id <LYBTransport>)transport {
    return self.overlayView;
}

- (void)setAutorotate:(BOOL)autorotate{
    _autorotate = autorotate;
    if (autorotate) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(changeRotation:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
}

- (void)changeRotation:(NSNotification *)nf {
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        [self portraitScreen];
        
    }else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft){
        [self leftScreen];
        
    }else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight){
        [self rightScreen];
    }
}

/**
 * 竖屏
 */
- (void)portraitScreen{
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame     = _originalFrame;
        self.overlayView.isFullScreen = NO;
    }];
}

/**
 * 左横屏
 */
- (void)leftScreen{
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.frame     = CGRectMake(0, 0, WIDTH, HEIGHT);
        self.center    = self.window.center;
        self.overlayView.isFullScreen = YES;
    }];
}

/**
 * 右横屏
 */
- (void)rightScreen{
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.frame     = CGRectMake(0, 0, WIDTH, HEIGHT);
        self.center    = self.window.center;
        self.overlayView.isFullScreen = YES;
    }];
}
@end
