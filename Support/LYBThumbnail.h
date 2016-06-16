//
//  LYBThumbnail.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/14.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

@interface LYBThumbnail : NSObject

+ (instancetype)thumbnailWithImage:(UIImage *)image time:(CMTime)time;

@property (nonatomic, readonly) CMTime time;
@property (strong, nonatomic, readonly) UIImage *image;

@end
