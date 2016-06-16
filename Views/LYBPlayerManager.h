//
//  LYBPlayerManager.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/14.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LYBPlayerManager : NSObject

/**
 * 后续添加URL再播放视频
 */
@property (nonatomic,strong)NSString  * url;

/**
 * 设置播放尺寸
 */
@property (nonatomic,assign)CGRect      playerFrame;

/**
 * 是否支持自动旋转屏幕
 */
@property (nonatomic,assign)BOOL        autoRatate;

/**
 * 初始化的同时播放视频
 */
+ (id)managerWithURL:(NSString *)url;

@property (strong, nonatomic, readonly) UIView *view;

@end
