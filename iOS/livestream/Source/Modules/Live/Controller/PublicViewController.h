//
//  PublicViewController.h
//  livestream
//
//  Created by randy on 2017/8/31.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSGoogleAnalyticsViewController.h"
#import "PlayViewController.h"
#import "LiveRoom.h"

#import "LSUITapImageView.h"
#import "YMAudienceView.h"
#import "ChardTipView.h"

@interface PublicViewController : LSGoogleAnalyticsViewController
#pragma mark - 数据参数
/**
 直播间对象
 */
@property (nonatomic, strong) LiveRoom* liveRoom;

/**
 播放控制器
 */
@property (nonatomic, strong) PlayViewController *playVC;

#pragma mark - 标题栏背景
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleBgImageTop;
@property (weak, nonatomic) IBOutlet UIImageView *titleBackGroundView;

#pragma mark - 界面控件
@property (weak, nonatomic) IBOutlet LSUITapImageView *roomTypeImageView;

@property (weak, nonatomic) IBOutlet YMAudienceView *audienceView;

@property (weak, nonatomic) IBOutlet UIView *followAndHomepageView;

@property (weak, nonatomic) IBOutlet UIView *numShaowView;

@property (weak, nonatomic) IBOutlet UIButton *homePageBtn;

@property (weak, nonatomic) IBOutlet UIButton *followBtn;

@property (weak, nonatomic) IBOutlet UIButton *peopleNumBtn;

@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *followBtnWidth;

@property (strong, nonatomic) ChardTipView *tipView;


- (IBAction)pushLiveHomePage:(id)sender;

- (IBAction)followLiverAction:(id)sender;

- (IBAction)closeAction:(id)sender;


@end
