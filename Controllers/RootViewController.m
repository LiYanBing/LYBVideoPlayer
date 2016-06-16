//
//  RootViewController.m
//  LYBVideoPlayer
//
//  Created by 李彦兵 on 16/6/13.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import "RootViewController.h"
#import "LYBOverlayView.h"
#import "LYBPlayerManager.h"

@interface RootViewController ()
@property (strong, nonatomic) LYBOverlayView *overlayView;
@property (nonatomic,strong) LYBPlayerManager * manager;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    headerView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:headerView];
    
//    NSArray * nib =  [[NSBundle mainBundle] loadNibNamed:@"LYBOverlayView"
//                                                   owner:self
//                                                 options:nil];
//    self.overlayView = [nib firstObject];
//    
//    self.overlayView.normalFrame = CGRectMake(0, 0, size.width, size.width);
//    self.overlayView.autorotate = YES;
//    [self.view addSubview:_overlayView];
//    _overlayView.backgroundColor = [UIColor greenColor];

    
    _manager = [LYBPlayerManager managerWithURL:@"http://7mnm7p.com2.z0.glb.qiniucdn.com/o_1ag32dgdt1lt3115l1foo5q01cgi1t.mp4"];
    _manager.playerFrame = CGRectMake(0, 0, size.width, size.width/1.7);
    UIView * playView = [_manager view];
    _manager.autoRatate = YES;
    [headerView addSubview:playView];
    
    [self performSelector:@selector(toDo) withObject:nil afterDelay:10];
}

- (void)toDo{
    _manager.url = @"http://7mnm7p.com2.z0.glb.qiniucdn.com/o_1ag32dgdt1lt3115l1foo5q01cgi1t.mp4";
}

- (IBAction)playLocalVideo:(id)sender {
}

- (IBAction)playRemoteVideo:(id)sender {
}

- (IBAction)playStreamVideo:(id)sender {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
