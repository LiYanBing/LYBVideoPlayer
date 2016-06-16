//
//  LYBThumbnail.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/14.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "LYBThumbnail.h"

@implementation LYBThumbnail

+ (instancetype)thumbnailWithImage:(UIImage *)image time:(CMTime)time {
    return [[self alloc] initWithImage:image time:time];
}

- (id)initWithImage:(UIImage *)image time:(CMTime)time {
    self = [super init];
    if (self) {
        _image = image;
        _time = time;
    }
    return self;
}

@end
