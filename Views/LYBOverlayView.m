//
//  LYBOverlayView.m
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "LYBOverlayView.h"
#import "UIView+THAdditions.h"
#import "NSTimer+Additions.h"
#import <MediaPlayer/MediaPlayer.h>

#define WIDTH   [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height

@interface LYBOverlayView()
{
    double _remainingTime;
}

/**
 * navgationBar是否隐藏
 */
@property (nonatomic,assign) BOOL      controlsHidden;

/**
 * 视频场景是否隐藏
 */
@property (nonatomic,assign) BOOL      filmstripHidden;

@property (nonatomic,assign) CGFloat        infoViewOffset;
@property (nonatomic,strong) NSTimer      * timer;
/**
 * 音量
 */
@property (nonatomic,strong) UISlider     * volumeSlider;

/**
 * 当前是否在拖拽状态
 */
@property (assign) BOOL scrubbing;

@end

@implementation LYBOverlayView

@synthesize delegate = _delegate;

- (void)setNormalFrame:(CGRect)normalFrame{
    _normalFrame = normalFrame;
    self.frame = _normalFrame;
}

- (void)setIsFullScreen:(BOOL)isFullScreen{
    _isFullScreen = isFullScreen;
    self.netAlertView.center = self.center;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.filmstripHidden = YES;
    
    UIImage *thumbNormalImage = [UIImage imageNamed:@"knob.png"];
    UIImage *thumbHighlightedImage = [UIImage imageNamed:@"knob_highlighted.png"];
    [self.scrubberSlider setThumbImage:thumbNormalImage forState:UIControlStateNormal];
    [self.scrubberSlider setThumbImage:thumbHighlightedImage forState:UIControlStateHighlighted];
    self.scrubberSlider.minimumTrackTintColor = [UIColor whiteColor];
    self.scrubberSlider.maximumTrackTintColor = [UIColor clearColor];
    
    self.infoView.hidden = YES;
    self.screenType      = UIScreenTypeLeft;
    
    [self calculateInfoViewOffset];
    
    
    [self.scrubberSlider addTarget:self
                            action:@selector(showPopupUI)
                  forControlEvents:UIControlEventValueChanged];
    [self.scrubberSlider addTarget:self
                            action:@selector(hidePopupUI)
                  forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside
     | UIControlEventTouchCancel];
    [self.scrubberSlider addTarget:self
                            action:@selector(unhidePopupUI)
                  forControlEvents:UIControlEventTouchDown];
    
    [self resetTimer];
    
    //音量
    MPVolumeView *mpVolumeView=[[MPVolumeView alloc] initWithFrame:CGRectMake(50,50,40,40)];
    for (UIView *view in [mpVolumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeSlider=(UISlider*)view;
            break;
        }
    }
    
    [self setAutorotate:YES];
    
    //网络提示框
    self.netAlertView.layer.cornerRadius = 5;
    self.netAlertView.backgroundColor    = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.netAlertView.clipsToBounds      = YES;
    self.netAlertView.hidden             = YES;
    //self.netAlertView.alpha              = 0;
}

/**
 * 显示网络提示框
 */
- (void)showNetAlertViewWithNetStream:(NSString *)stream title:(NSString *)title{
    self.netAlertView.center = self.center;
    [UIView animateWithDuration:0.3 animations:^{
        self.netAlertView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        self.netAlertView.hidden  = NO;
        [self.activeView startAnimating];
    }];
    
    if (stream) {
        self.netStreamLabel.text = stream;
    }
    
    if (title) {
        self.buffingLabel.text = title;
    }
}

/**
 * 隐藏网络提示框
 */
- (void)hideNetAlertView{
    [UIView animateWithDuration:0.3 animations:^{
        self.netAlertView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        self.netAlertView.hidden  = YES;
        [self.activeView stopAnimating];
    }];
}

/**
 * 屏幕点击手势
 */
- (IBAction)toggleControls:(id)sender {
    [UIView animateWithDuration:0.35 animations:^{
        if (!self.controlsHidden) {
            if (!self.filmstripHidden) {
                [UIView animateWithDuration:0.35 animations:^{
                    //self.filmStripView.frameY -= self.filmStripView.frameHeight;
                    self.filmstripHidden = YES;
                    //self.filmstripToggleButton.selected = NO;
                } completion:^(BOOL complete) {
                    //self.filmStripView.hidden = YES;
                    [UIView animateWithDuration:0.35 animations:^{
                        self.navgationBar.frameY -= self.navgationBar.frameHeight;
                        self.toolBar.frameY += self.toolBar.frameHeight;
                        //[self hidePopupUI];
                        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
                    }];
                }];
            } else {
                self.navgationBar.frameY -= self.navgationBar.frameHeight;
                self.toolBar.frameY += self.toolBar.frameHeight;
                //[self hidePopupUI];
                [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
            }
        } else {
            self.navgationBar.frameY += self.navgationBar.frameHeight;
            self.toolBar.frameY -= self.toolBar.frameHeight;
            [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
        }
        self.controlsHidden = !self.controlsHidden;
    }];
    [self resetTimer];
}

/**
 * 拖动改变音量和进度手势
 */
- (IBAction)tapAction:(UIPanGestureRecognizer *)sender {
    
    if(sender.numberOfTouches>1) {
        return;
    }
    CGPoint translationPoint=[sender translationInView:self];
    
    CGFloat x=translationPoint.x;
    CGFloat y=translationPoint.y;
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self hidePopupUI];
    }
    
    if ((x==0&&fabs(y)>=5)||fabs(y)/fabs(x)>=3) { //上下拖动调节音量
        if (self.scrubbing) {
            return;
        }
        CGFloat ratio = ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location != NSNotFound)?20000.0f:13000.0f;
        CGPoint velocity = [sender velocityInView:self];
        
        CGFloat nowValue = _volumeSlider.value;
        CGFloat changedValue = 1.0f * (nowValue - velocity.y / ratio);
        if(changedValue < 0) {
            changedValue = 0;
        }
        if(changedValue > 1) {
            changedValue = 1;
        }
        
        [_volumeSlider setValue:changedValue animated:YES];
        [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
        
    }else{//左右改变进度
        if (sender.state == UIGestureRecognizerStateBegan) {
            [self unhidePopupUI];
        }
        
        if (sender.state == UIGestureRecognizerStateEnded) {
            [self hidePopupUI];
        }
        
        if((y==0&&fabs(x)>=5)||fabs(x)/fabs(y)>=3) {
            if (_remainingTime == 0 && x > 0) {
                return;
            }
            if (self.controlsHidden) {
                self.controlsHidden = NO;
                [UIView animateWithDuration:0.35 animations:^{
                    self.navgationBar.frameY += self.navgationBar.frameHeight;
                    self.toolBar.frameY -= self.toolBar.frameHeight;
                    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
                }];
            }
            _scrubberSlider.value = _scrubberSlider.value + x;
            [self showPopupUI];
        }
    }
    [sender setTranslation:CGPointZero inView:self];
}


/**
 * 播放与暂停
 */
- (IBAction)playControls:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) { // 播放
        [self hideNetAlertView];
        [self.delegate play];
        [self.delegate manualPause:NO];
    }else{ //暂停
        [self.delegate pause];
        [self.delegate manualPause:YES];
    }
//    if (self.delegate) {
//        SEL callback = sender.selected ? @selector(play) : @selector(pause);
//        [self.delegate performSelector:callback];
//    }
}

/**
 * 关闭视频
 */
- (IBAction)closeControls:(id)sender {
    [self.timer invalidate];
    self.timer = nil;
    [self.delegate stop];
}

/**
 * 展示
 */
- (void)showControls:(UIButton *)button{
    
}

/**
 * 全屏切换
 */
- (IBAction)changeScreen:(id)sender {
    if (self.isFullScreen) {
        [self.delegate portraitScreen];
    }else{
        [self.delegate fullScreen];
    }
}

/**
 * 让时间显示器随着拖拽改变位置
 */
- (void)showPopupUI {
    self.infoView.hidden = NO;
    self.scrubbing = YES;
    CGRect trackRect = [self.scrubberSlider convertRect:self.scrubberSlider.bounds toView:self];
    CGRect thumbRect = [self.scrubberSlider thumbRectForBounds:self.scrubberSlider.bounds trackRect:trackRect value:self.scrubberSlider.value];
    
    CGRect rect = self.infoView.frame;
    rect.origin.x = (thumbRect.origin.x) - self.infoViewOffset + 16;
    rect.origin.y = self.boundsHeight - 80;
    self.infoView.frame = rect;
    
//    self.currentTimeLabel.text = @"-- : --";
//    self.remindingTimeLabel.text = @"-- : --";
    
    [self setScrubbingTime:self.scrubberSlider.value];
    [self.delegate scrubbedToTime:self.scrubberSlider.value];
}

/**
 * 显示时间显示器
 */
- (void)unhidePopupUI {
    self.infoView.hidden = NO;
    self.infoView.alpha = 0.0f;
    [UIView animateWithDuration:0.2f animations:^{
        self.infoView.alpha = 1.0f;
    }];
    self.scrubbing = YES;
    [self.delegate scrubbingDidStart];
}

/**
 * 隐藏时间显示器
 */
- (void)hidePopupUI {
    [UIView animateWithDuration:0.3f animations:^{
        self.infoView.alpha = 0.0f;
    } completion:^(BOOL complete) {
        self.infoView.alpha = 1.0f;
        self.infoView.hidden = YES;
    }];
    
    self.scrubbing = NO;
    [self.delegate scrubbingDidEnd];
    [self resetTimer];
}

/**
 * 计算拖拽时间的偏移
 */
- (void)calculateInfoViewOffset {
    [self.infoView sizeToFit];
    self.infoViewOffset = ceilf(CGRectGetWidth(self.infoView.frame) / 2);
}

/**
 * 五秒之后检测上下工具条是否显示
 */
- (void)resetTimer {
    [self.timer invalidate];
    if (!self.scrubbing) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 firing:^{
            if (self.timer.isValid && !self.controlsHidden && !self.scrubbing) {
                [self toggleControls:nil];
            }
        }];
    }
}

- (void)setCurrentTime:(NSTimeInterval)time{
    [self.delegate jumpedToTime:time];
}

- (void)setTitle:(NSString *)title{
    self.navgationBar.topItem.title = title ? title : @"LIYANBING Video Player";
}

- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration{
    //NSInteger currentSeconds = ceilf(time);
    _remainingTime = duration - time;
    self.currentTimeLabel.text = [self formatSeconds:time];
    self.remindingTimeLabel.text = [self formatSeconds:_remainingTime];
    self.scrubberSlider.minimumValue = 0.0f;
    self.scrubberSlider.maximumValue = duration;
    self.scrubberSlider.value = time;
}

/**
 * 将时间转换为分钟加秒的格式
 */
- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long) minutes, (long) seconds];
}

/**
 * 气泡时间展示
 */
- (void)setScrubbingTime:(NSTimeInterval)time{
    self.infoLabel.text = [self formatSeconds:time];
}

/**
 * 播放结束
 */
- (void)playbackComplete{
    self.scrubberSlider.value = 0.0f;
    self.togglePlaybackButton.selected = NO;
}

- (void)setSubtitles:(NSArray *)subtitles{
    
}

/**
 * 设置缓冲
 */
- (void)setBufferTime:(NSTimeInterval)time{
    [_progressView setProgress:time animated:YES];
}

/**
 * 开始播放
 */
- (void)play{
    self.togglePlaybackButton.selected = YES;
    [self hideNetAlertView];
}

/**
 * 暂停播放
 */
- (void)pause{
     self.togglePlaybackButton.selected = NO;
    [self showNetAlertViewWithNetStream:nil title:nil];
}

/**
 * 设置网速
 */
- (void)setNetStream:(double)stream{
    self.netStreamLabel.text = [NSString stringWithFormat:@"%lfkB/s",stream];
    if (stream >= 100) {
        self.netStreamLabel.textColor = [UIColor greenColor];
    }else{
        self.netStreamLabel.textColor = [UIColor colorWithRed:223/255.0 green:25/255.0 blue:33/255.0 alpha:1];
    }
}

- (void)fullScreen{
    _isFullScreen  = YES;
    if (self.screenType == UIScreenTypeLeft) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.frame     = CGRectMake(0, 0, WIDTH, HEIGHT);
            self.center    = self.window.center;
            self.netAlertView.center = self.center;
        }];
    }else{
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.frame     = CGRectMake(0, 0, WIDTH, HEIGHT);
            self.center    = self.window.center;
            self.netAlertView.center = self.center;
        }];
    }
   
}

- (void)normallScreen{
    _isFullScreen  = NO;
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame     = _normalFrame;
        self.netAlertView.center = self.center;
    }];
    
}

@end
