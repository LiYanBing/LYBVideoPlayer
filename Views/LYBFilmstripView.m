//
//  LYBPlayerManager.h
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/14.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "LYBFilmstripView.h"
#import "LYBThumbnail.h"
#import "LYBOverlayView.h"
#import "LYBNotifications.h"

@interface LYBFilmstripView ()
@property (strong, nonatomic) NSArray *thumbnails;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView  * actView;

@end

@implementation LYBFilmstripView

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(buildScrubber:)
                                                     name:THThumbnailsGeneratedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)show{
    self.actView.center = self.scrollView.center;
}

- (void)buildScrubber:(NSNotification *)notification {
    [self.actView stopAnimating];
    self.thumbnails = [notification object];
    CGFloat currentX = 0.0f;

    CGSize size = [(UIImage *)[[self.thumbnails firstObject] image] size];
    CGSize imageSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(0.5, 0.5));
    //CGSize imageSize  = size;
    CGRect imageRect = CGRectMake(currentX, 0, imageSize.width, imageSize.height);

    CGFloat imageWidth = CGRectGetWidth(imageRect) * self.thumbnails.count;
    self.scrollView.contentSize = CGSizeMake(imageWidth, imageRect.size.height);

    for (NSUInteger i = 0; i < self.thumbnails.count; i++) {
        LYBThumbnail *timedImage = self.thumbnails[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.adjustsImageWhenHighlighted = NO;
        [button setBackgroundImage:timedImage.image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(imageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(currentX, 0, imageSize.width, imageSize.height);
        button.tag = i;
        [self.scrollView addSubview:button];
        currentX += imageSize.width;
    }
}

- (void)imageButtonTapped:(UIButton *)sender {
    LYBThumbnail *image = self.thumbnails[sender.tag];
    if (image) {
        if ([self.superview respondsToSelector:@selector(setCurrentTime:)]) {
            [(LYBOverlayView *)self.superview setCurrentTime:CMTimeGetSeconds(image.time)];
        }
    }
}

@end
