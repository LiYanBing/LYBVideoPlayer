//
//  LYBPlayerManager.m
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/14.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "LYBPlayerManager.h"
#import "LYBPlayerView.h"
#import "LYBThumbnail.h"
#import "AVAsset+THAdditions.h"
#import "UIAlertView+THAdditions.h"
#import "LYBNotifications.h"
#import <AVFoundation/AVFoundation.h>

//状态
#define STATUS_KEYPATH @"status"
#define REFRESH_INTERVAL 0.5f
static const NSString *PlayerItemStatusContext;

//缓冲
#define BUFFER_KEYPATH @"loadedTimeRanges"
static  const NSString * PlayerItemloadedRange;

//是否可播放
#define KEEPUP_KEYPATH @"playbackLikelyToKeepUp"
static const NSString   * PlayerItemKeepUp;

static const NSString   * PlayerItemBufferEmpty;

@interface LYBPlayerManager()<LYBTransportDelegate>

@property (strong, nonatomic) AVAsset    * asset;     //视频的静态信息
@property (strong, nonatomic) AVPlayerItem  * playerItem;//视频的动态信息
@property (strong, nonatomic) AVPlayer      * player;
@property (strong, nonatomic) LYBPlayerView * playerView;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (weak, nonatomic) id <LYBTransport> transport;

@property (assign, nonatomic) BOOL      isPlaying;
@property (strong, nonatomic) id        timeObserver;
@property (strong, nonatomic) id        itemEndObserver;
@property (assign, nonatomic) float     lastPlaybackRate;
@property (assign, nonatomic) NSTimeInterval   totalTime;
@property (assign, nonatomic) BOOL      isManualPause;

@end

@implementation LYBPlayerManager

- (void)setPlayerFrame:(CGRect)playerFrame{
    self.playerView.frame = playerFrame;
    self.playerView.originalFrame = playerFrame;
}

- (void)setAutoRatate:(BOOL)autoRatate{
    self.playerView.autorotate = autoRatate;
}

+ (id)managerWithURL:(NSString *)url {
    LYBPlayerManager * mananer = [[self alloc] init];
    [mananer setUrl:url];
    return mananer;
}

- (instancetype)init{
    if (self =  [super init]) {
        [self prepareToPlay];
    }
    return self;
}

- (void)setUrl:(NSString *)url{
    _url = url;
    BOOL flag = NO;
    self.asset = [AVAsset assetWithURL:[NSURL URLWithString:url]];
    NSArray *keys = @[
                      @"tracks",
                      @"duration",
                      @"commonMetadata",
                      @"availableMediaCharacteristicsWithMediaSelectionOptions"
                      ];
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self
                             forKeyPath:BUFFER_KEYPATH];
        [self.playerItem removeObserver:self
                             forKeyPath:KEEPUP_KEYPATH];
        [self.player removeTimeObserver:self.timeObserver];
        
        if (self.itemEndObserver) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc removeObserver:self.itemEndObserver
                          name:AVPlayerItemDidPlayToEndTimeNotification
                        object:self.player.currentItem];
            self.itemEndObserver = nil;
        }
        
        self.playerItem = nil;
        flag = YES;
        
    }
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset
                           automaticallyLoadedAssetKeys:keys];
    
    [self.playerItem addObserver:self
                      forKeyPath:STATUS_KEYPATH
                         options:0
                         context:&PlayerItemStatusContext];
    
    if (flag) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }else{
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    
    self.playerView.player = self.player;
}

- (void)prepareToPlay {
    self.playerView = [[LYBPlayerView alloc] init];
    self.transport = self.playerView.transport;
    self.transport.delegate = self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == &PlayerItemStatusContext) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
            
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                [self addPlayerItemTimeObserver];
                [self addItemEndObserverForPlayerItem];
                [self addItemBufferObserver];
                [self addItemCanPlayObserver];
                
                CMTime duration = self.playerItem.duration;
                _totalTime = CMTimeGetSeconds(duration);
                
                [self.transport setCurrentTime:CMTimeGetSeconds(kCMTimeZero)
                                      duration:_totalTime];
                
                [self.transport setTitle:self.asset.title];
                
                [self play];
                
                [self loadMediaOptions];
                [self generateThumbnails];
                
            } else {
                [UIAlertView showAlertWithTitle:@"Error"
                                        message:@"Failed to load video"];
            }
        });
    }
    
    if (context == &PlayerItemloadedRange) {
        NSArray *array=_player.currentItem.loadedTimeRanges;
        
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
        NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
        
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        [self.transport setBufferTime:totalBuffer/_totalTime];
        
        NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
        
        //NSLog(@"startSeconds:%lf, currentTime:%lf,totaoBuffer:%lf",startSeconds,currentTime,totalBuffer);
        if (currentTime < totalBuffer && _isPlaying == NO) {
            NSLog(@"继续播放");
            if (_isManualPause) {
                return;
            }
            [self play];
            [self.transport play];
        }else if(currentTime >= totalBuffer || currentTime <= startSeconds){
            
            NSLog(@"缓存中");
            
            if (_isPlaying) {
                [self pause];
                [self.transport pause];
            }
            
        }
        
        
    }
    
    if (context == &PlayerItemKeepUp) {
        if (_playerItem.playbackLikelyToKeepUp) {
            NSLog(@"暂停播放");
            //[self pause];
            _isPlaying = NO;
            //[self.transport pause];
            
        }else{
            NSLog(@"开始播放");
            //[self play];
            _isPlaying = YES;
            //[self.transport play];
        }
    }
}


#pragma mark - Time Observers
/**
 * 每隔0.5秒就去更新一下UI界面的播放时间
 */
- (void)addPlayerItemTimeObserver {
    
    CMTime interval =
    CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    __weak typeof(self) weakSelf = self;
    void (^callback)(CMTime time) = ^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
        [weakSelf.transport setCurrentTime:currentTime duration:duration];
    };
    
    self.timeObserver =
    [self.player addPeriodicTimeObserverForInterval:interval
                                              queue:queue
                                         usingBlock:callback];
}

/**
 * 监测播放结束
 */
- (void)addItemEndObserverForPlayerItem {
    
    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;
    
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    
    __weak typeof(self) weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification) {
        [weakSelf.player seekToTime:kCMTimeZero
                  completionHandler:^(BOOL finished) {
                      [weakSelf.transport playbackComplete];
                  }];
    };
    
    self.itemEndObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                      object:self.playerItem
                                                       queue:queue
                                                  usingBlock:callback];
}

/**
 * 监测缓冲
 */
- (void)addItemBufferObserver{
    [_playerItem addObserver:self
                  forKeyPath:BUFFER_KEYPATH
                     options:NSKeyValueObservingOptionNew
                     context:&PlayerItemloadedRange];
}

/**
 * 监控当前是否可以播放
 */
- (void)addItemCanPlayObserver{
    [_playerItem addObserver:self
                  forKeyPath:KEEPUP_KEYPATH
                     options:0
                     context:&PlayerItemKeepUp];
}

- (void)loadMediaOptions {
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group =
    [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        NSMutableArray *subtitles = [NSMutableArray array];
        for (AVMediaSelectionOption *option in group.options) {
            [subtitles addObject:option.displayName];
        }
        [self.transport setSubtitles:subtitles];
    } else {
        [self.transport setSubtitles:nil];
    }
}

#pragma mark - Thumbnail Generation

- (void)generateThumbnails {
    
    self.imageGenerator =
    [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    
    // Generate the @2x equivalent
    self.imageGenerator.maximumSize = CGSizeMake(200.0f, 0.0f);
    
    CMTime duration = self.asset.duration;
    
    NSMutableArray *times = [NSMutableArray array];
    CMTimeValue increment = duration.value / 20;
    CMTimeValue currentValue = 2.0 * duration.timescale;
    while (currentValue <= duration.value) {
        CMTime time = CMTimeMake(currentValue, duration.timescale);
        [times addObject:[NSValue valueWithCMTime:time]];
        currentValue += increment;
    }
    
    __block NSUInteger imageCount = times.count;
    __block NSMutableArray *images = [NSMutableArray array];
    
    AVAssetImageGeneratorCompletionHandler handler;
    
    handler = ^(CMTime requestedTime,
                CGImageRef imageRef,
                CMTime actualTime,
                AVAssetImageGeneratorResult result,
                NSError *error) {
        
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            id thumbnail =
            [LYBThumbnail thumbnailWithImage:image time:actualTime];
            [images addObject:thumbnail];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        
        // If the decremented image count is at 0, we're all done.
        if (--imageCount == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *name = THThumbnailsGeneratedNotification;
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                [nc postNotificationName:name object:images];
            });
        }
    };
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                              completionHandler:handler];
}

- (UIView *)view {
    return self.playerView;
}

- (void)dealloc {
    if (self.itemEndObserver) {                                             
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self.itemEndObserver
                      name:AVPlayerItemDidPlayToEndTimeNotification
                    object:self.player.currentItem];
        self.itemEndObserver = nil;
    }
    
    if (self.playerItem) {
        [self.playerItem removeObserver:self
                             forKeyPath:BUFFER_KEYPATH];
        
        [self.playerItem removeObserver:self
                             forKeyPath:KEEPUP_KEYPATH];
    }
}

#pragma mark - THTransportDelegate Methods

/**
 * 开始播放
 */
- (void)play {
    [self.player play];
    _isPlaying = YES;
}

/**
 * 暂停播放
 */
- (void)pause {
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    _isPlaying = NO;
}

/**
 * 停止播放
 */
- (void)stop {
    [self.player setRate:0.0f];
    [self.transport playbackComplete];
}

/**
 * 跳到指定时间开始播放
 */
- (void)jumpedToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}

/**
 * 拖拽开始
 */
- (void)scrubbingDidStart {
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

/**
 * 拖拽到指定时间开始播放
 */
- (void)scrubbedToTime:(NSTimeInterval)time {
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

/**
 * 拖拽结束
 */
- (void)scrubbingDidEnd {
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        [self.player play];
    }
}

/**
 * 全屏
 */
- (void)fullScreen{
    [self.playerView leftScreen];
}

/**
 * 竖屏
 */
- (void)portraitScreen{
    [self.playerView portraitScreen];
}

/**
 * 是否手动暂停
 */
- (void)manualPause:(BOOL)pause{
    _isManualPause = pause;
}

@end


