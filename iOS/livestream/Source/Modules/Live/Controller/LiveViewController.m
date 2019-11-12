//
//  LiveViewController.m
//  livestream
//
//  Created by Max on 2017/5/18.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "LiveViewController.h"

#import "LiveFinshViewController.h"
#import "LiveWebViewController.h"
#import "LSAddCreditsViewController.h"

#import "LiveModule.h"
#import "LiveUrlHandler.h"

#import "LiveGobalManager.h"
#import "LiveStreamPublisher.h"


#import "MsgTableViewCell.h"
#import "TalentMsgCell.h"
#import "HangOutOpenDoorCell.h"
#import "MsgItem.h"

#import "LikeView.h"

#import "LSFileCacheManager.h"
#import "LSSessionRequestManager.h"
#import "LSGiftManager.h"
#import "LSChatEmotionManager.h"
#import "LiveStreamSession.h"
#import "LSRoomUserInfoManager.h"
#import "LiveRoomCreditRebateManager.h"

#import "AudienceModel.h"
#import "GetNewFansBaseInfoRequest.h"
#import "LSSendinvitationHangoutRequest.h"
#import "LSGetHangoutInvitStatusRequest.h"

#import "DialogChoose.h"
#import "DialogTip.h"
#import "DialogWarning.h"
#import "LSShadowView.h"
#define RECORD_START @"!record=1!"
#define RECORD_STOP @"!record=0!"

#define DEBUG_START @"!debug=1!"
#define DEBUG_STOP @"!debug=0!"

#define INPUTMESSAGEVIEW_MAX_HEIGHT 44.0 * 2

#define LevelFontSize 14
#define LevelFont [UIFont systemFontOfSize:LevelFontSize]
#define LevelGrayColor [LSColor colorWithIntRGB:56 green:135 blue:213 alpha:255]

#define MessageFontSize 16
#define MessageFont [UIFont fontWithName:@"AvenirNext-DemiBold" size:MessageFontSize]

#define NameFontSize 14
#define NameFont [UIFont fontWithName:@"AvenirNext-DemiBold" size:NameFontSize]

#define NameColor [LSColor colorWithIntRGB:255 green:210 blue:5 alpha:255]
#define MessageTextColor [UIColor whiteColor]

#define UnReadMsgCountFontSize 14
#define UnReadMsgCountColor NameColor
#define UnReadMsgCountFont [UIFont boldSystemFontOfSize:UnReadMsgCountFontSize]

#define UnReadMsgTipsFontSize 14
#define UnReadMsgTipsColor MessageTextColor
#define UnReadMsgTipsFont [UIFont boldSystemFontOfSize:UnReadMsgCountFontSize]

#define MessageCount 500

#define TIMECOUNT 30

#define OpenDoorHeight 71

#pragma mark - 流[播放/推送]逻辑
#define STREAM_PLAYER_RECONNECT_MAX_TIMES 5
#define STREAM_PUBLISH_RECONNECT_MAX_TIMES STREAM_PLAYER_RECONNECT_MAX_TIMES

@interface LiveViewController () <UITextFieldDelegate, LSCheckButtonDelegate, BarrageViewDataSouce, BarrageViewDelegate, GiftComboViewDelegate, IMLiveRoomManagerDelegate, IMManagerDelegate, DriveViewDelegate, MsgTableViewCellDelegate, LiveStreamPlayerDelegate, LiveStreamPublisherDelegate, LiveGobalManagerDelegate, TalentMsgCellDelegate, HangOutOpenDoorCellDelegate>

#pragma mark - 流[播放/推送]管理
// 流播放地址
@property (strong) NSString *playUrl;

// 流播放重连次数
@property (assign) NSUInteger playerReconnectTime;
// 流推送地址
@property (strong) NSString *publishUrl;
// 流推送组件
@property (strong) LiveStreamPublisher *publisher;
// 流推送重连次数
@property (assign) NSUInteger publisherReconnectTime;

#pragma mark - 观众管理
// 观众数组
@property (strong) NSMutableArray *audienArray;

#pragma mark - 消息列表
/**
 用于显示的消息列表
 @description 注意在主线程操作
 */
@property (strong) NSMutableArray<MsgItem *> *msgShowArray;
/**
 用于保存真实的消息列表
 @description 注意在主线程操作
 */
@property (strong) NSMutableArray<MsgItem *> *msgArray;
/**
 是否需要刷新消息列表
 @description 注意在主线程操作
 */
@property (assign) BOOL needToReload;

#pragma mark - 接口管理器
@property (nonatomic, strong) LSSessionRequestManager *sessionManager;

#pragma mark - 礼物管理器
@property (nonatomic, strong) GiftComboManager *giftComboManager;

#pragma mark - 用户信息管理器
@property (nonatomic, strong) LSRoomUserInfoManager *roomUserInfoManager;

#pragma mark - 礼物连击界面
@property (nonatomic, strong) NSMutableArray<GiftComboView *> *giftComboViews;
@property (nonatomic, strong) NSMutableArray<MASConstraint *> *giftComboViewsLeadings;

#pragma mark - 礼物下载器
@property (nonatomic, strong) LSGiftManager *giftDownloadManager;

#pragma mark - 表情管理器
@property (nonatomic, strong) LSChatEmotionManager *emotionManager;

#pragma mark - 消息管理器
@property (nonatomic, strong) PublicLiveMsgManager *msgManager;

#pragma mark - 余额及返点信息管理器
@property (nonatomic, strong) LiveRoomCreditRebateManager *creditRebateManager;

#pragma mark - 倒数控制
// 视频按钮倒数
@property (strong) LSTimer *videoBtnTimer;
// 视频按钮消失倒数
@property (nonatomic, assign) int videoBtnLeftSecond;

#pragma mark - 图片下载器
@property (nonatomic, strong) LSImageViewLoader *headImageLoader;
@property (nonatomic, strong) LSImageViewLoader *giftImageLoader;
@property (nonatomic, strong) LSImageViewLoader *cellHeadImageLoader;

#pragma mark - 倒计时关闭直播间
@property (strong) LSTimer *timer;
@property (nonatomic, assign) NSInteger timeCount;

#pragma mark - 弹幕
// 显示的弹幕数量 用于判断隐藏弹幕阴影
@property (nonatomic, assign) int showToastNum;

#pragma mark - 对话框
@property (strong) DialogTip *dialogProbationTip;
@property (strong) DialogWarning *dialogView;

#pragma mark - 用于显示试用倦提示
@property (nonatomic, assign) BOOL showTip;

#pragma mark - 后台处理
@property (nonatomic, assign) BOOL isBackground;

// 是否已退入后台超时
@property (nonatomic, assign) BOOL isTimeOut;

// 是否是推荐邀请Hangout
@property (nonatomic, assign) BOOL isRecommend;
// 是否邀请Hangout成功
@property (nonatomic, assign) BOOL isInviteHangout;
// 是否正在Hangout邀请
@property (nonatomic, assign) BOOL isInvitingHangout;
// HangOut邀请ID
@property (nonatomic, copy) NSString *hangoutInviteId;
// Hangout邀请主播名称 ID
@property (nonatomic, copy) NSString *hangoutAnchorName;
@property (nonatomic, copy) NSString *hangoutAnchorId;
// push跳转Url
@property (nonatomic, strong) NSURL *pushUrl;

#pragma mark - 测试
@property (nonatomic, weak) NSTimer *testTimer;
@property (nonatomic, assign) NSInteger giftItemId;
@property (nonatomic, weak) NSTimer *testTimer2;
@property (nonatomic, weak) NSTimer *testTimer3;
@property (nonatomic, weak) NSTimer *testTimer4;
@property (nonatomic, assign) NSInteger msgId;
@property (nonatomic, assign) BOOL isDriveShow;

@end

@implementation LiveViewController
#pragma mark - 界面初始化
- (void)initCustomParam {
    [super initCustomParam];

    NSLog(@"LiveViewController::initCustomParam()");

    self.isShowNavBar = NO;

    // 初始化流组件
    self.playUrl = @"rtmp://172.25.32.133:7474/test_flash/max_mv";
    self.player = [LiveStreamPlayer instance];
    self.player.delegate = self;
    self.playerReconnectTime = 0;

    self.publishUrl = @"rtmp://172.25.32.133:7474/test_flash/max_i";
    self.publisher = [LiveStreamPublisher instance:LiveStreamType_Audience_Private];
    self.publisher.delegate = self;
    self.publisherReconnectTime = 0;

    // 初始化消息
    self.msgArray = [NSMutableArray array];
    self.msgShowArray = [NSMutableArray array];
    self.needToReload = NO;

    // 初始请求管理器
    self.sessionManager = [LSSessionRequestManager manager];

    // 初始化IM管理器
    self.imManager = [LSImManager manager];
    [self.imManager addDelegate:self];
    [self.imManager.client addDelegate:self];

    // 初始化后台管理器
    [[LiveGobalManager manager] addDelegate:self];

    // 初始登录
    self.loginManager = [LSLoginManager manager];
    self.giftComboManager = [[GiftComboManager alloc] init];

    // 初始化用户信息管理器
    self.roomUserInfoManager = [LSRoomUserInfoManager manager];

    // 初始化礼物管理器
    self.giftDownloadManager = [LSGiftManager manager];

    // 初始化表情管理器
    self.emotionManager = [LSChatEmotionManager emotionManager];

    // 初始化文字管理器
    self.msgManager = [[PublicLiveMsgManager alloc] init];

    // 初始化余额及返点信息管理器
    self.creditRebateManager = [LiveRoomCreditRebateManager creditRebateManager];

    // 初始化大礼物播放队列
    self.bigGiftArray = [NSMutableArray array];

    // 初始化观众队列
    self.audienArray = [[NSMutableArray alloc] init];

    // 显示的弹幕数量
    self.showToastNum = 0;

    // 初始化视频控制按钮消失计时器
    self.videoBtnLeftSecond = 3;

    // 图片下载器
    self.headImageLoader = [LSImageViewLoader loader];
    self.giftImageLoader = [LSImageViewLoader loader];
    self.cellHeadImageLoader = [LSImageViewLoader loader];

    // 注册前后台切换通知
    _isBackground = NO;
    self.isTimeOut = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    // 注册大礼物结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animationWhatIs:) name:@"GiftAnimationIsOver" object:nil];

    // 初始化计时器
    self.videoBtnTimer = [[LSTimer alloc] init];

    // 初始化倒数关闭直播间计时器
    self.timer = [[LSTimer alloc] init];

    self.dialogProbationTip = [DialogTip dialogTip];
    self.showTip = YES;

    // 初始化是否推荐邀请hangout
    self.isRecommend = NO;
    // 初始化是否邀请多人互动成功
    self.isInviteHangout = NO;
    // 初始化是否正在多人互动邀请
    self.isInvitingHangout = NO;
}

- (void)dealloc {
    NSLog(@"LiveViewController::dealloc()");

    // 去除大礼物结束通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GiftAnimationIsOver" object:nil];

    [self.giftComboManager removeManager];

    for (GiftComboView *giftView in self.giftComboViews) {
        [giftView stopGiftCombo];
    }

    [self.timer stopTimer];

    // 移除直播间后台代理监听
    [[LiveGobalManager manager] removeDelegate:self];
    [[LiveGobalManager manager] setupLiveVC:nil orHangOutVC:nil];

    // 移除直播间IM代理监听
    [self.imManager removeDelegate:self];
    [self.imManager.client removeDelegate:self];

    // 停止流
    [self stopPlay];
    [self stopPublish];

    // 关闭锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    if (self.liveRoom.roomId.length > 0) {
        // 发送退出直播间
        NSLog(@"LiveViewController::dealloc( [发送退出直播间], roomId : %@ )", self.liveRoom.roomId);
        [self.imManager leaveRoom:self.liveRoom];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 赋值到全局变量, 用于后台计时操作
    [LiveGobalManager manager].liveRoom = self.liveRoom;
    // 赋值到全局变量 用于观看信件或chat视频关闭直播声音
    [[LiveGobalManager manager] setupLiveVC:self orHangOutVC:nil];

    // 禁止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // 初始化消息列表
    [self setupTableView];

    // 初始化座驾控件
    [self setupDriveView];

    // 初始化连击控件
    [self setupGiftView];

    // 初始化视频界面
    self.player.playView = self.videoView;
    self.player.playView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;

    // 隐藏返点按钮
    [self.rewardedBtn setHighlighted:NO];
    [self setUpRewardedCredit:self.liveRoom.imLiveRoom.rebateInfo.curCredit];

    // 弹幕
    self.barrageView.hidden = YES;

    // 隐藏视频预览界面
    self.previewVideoViewWidth.constant = 0;

    // 隐藏互动直播ActivityView
    self.preActivityView.hidden = YES;

    // 隐藏startOneView
    [self hiddenStartOneView];

    // 倒计时关闭直播间控件
    self.countdownView.layer.cornerRadius = self.countdownView.frame.size.height * 0.5;
    self.countdownView.hidden = YES;

    // 隐藏房间提示view
    self.roomTipView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self hideNavigationBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.barrageView.hidden = YES;

    self.bigGiftArray = nil;
    [self.giftAnimationView removeFromSuperview];
    self.giftAnimationView = nil;

    if (self.dialogProbationTip.isShow) {
        [self.dialogProbationTip removeShow];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.liveRoom.imLiveRoom.usedVoucher && self.showTip) {
        self.showTip = NO;
        [self.dialogProbationTip showDialogTip:self.liveRoom.superView tipText:[NSString stringWithFormat:NSLocalizedStringFromSelf(@"LIVE_VOUCHER_APPLIED"), self.liveRoom.imLiveRoom.useCoupon]];
    }

    if (!self.viewDidAppearEver) {
        // 第一次进入
        // 开始播放流
        [self play];

        // 自己座驾入场
        [self getDriveInfo:self.loginManager.loginItem.userId];
    }

    // 开始计时器
    [self startVideoBtnTimer];

    [super viewDidAppear:animated];

    //    [self test];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // 停止计时器
    [self stopVideoBtnTimer];

    //    [self stopTest];
}

- (void)setupContainView {
    [super setupContainView];

    // 初始化返点按钮
    [self setupRewardImageView];

    // 初始化弹幕
    [self setupBarrageView];

    // 初始化预览界面
    [self setupPreviewView];
}

- (void)setupRewardImageView {
    // 设置返点按钮
    self.rewardedBgView.layer.cornerRadius = 10;
}

- (void)bringSubviewToFrontFromView:(UIView *)view {

    [self.view bringSubviewToFront:self.giftView];
    [self.view bringSubviewToFront:self.barrageView];
    //    [self.view bringSubviewToFront:self.cameraBtn];

    [view bringSubviewToFront:self.giftView];
    [view bringSubviewToFront:self.barrageView];
    //    [view bringSubviewToFront:self.cameraBtn];
}

- (void)showPreview {
    // 显示预览控件
    self.previewVideoViewWidth.constant = 115;
}

- (void)hiddenStartOneView {
    // 默认隐藏邀请私密控件
    self.startOneViewHeigh.constant = 0;

    self.startOneBtn.layer.cornerRadius = self.startOneBtn.tx_height / 2;
    self.startOneBtn.layer.masksToBounds = YES;

    LSShadowView *shadowView = [[LSShadowView alloc] init];
    [shadowView showShadowAddView:self.startOneBtn];

    self.startOneBtn.hidden = YES;
}

- (void)showRoomTipView:(NSString *)tip isReject:(BOOL)isReject {
    self.roomTipView.hidden = NO;
    self.roomTipLabel.text = tip;
    if (isReject) {
        LSTimer *timer = [[LSTimer alloc] init];
        [timer startTimer:dispatch_get_main_queue()
             timeInterval:3.0 * NSEC_PER_SEC
                  starNow:NO
                   action:^{
                       self.roomTipView.hidden = YES;
                       [timer stopTimer];
                   }];
    }
}

/** 显示买点弹框 **/
- (void)showAddCreditsView:(NSString *)tip {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:tip preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *canaelAC = [UIAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *addAC = [UIAlertAction actionWithTitle:NSLocalizedString(@"ADD_CREDITS", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([self.liveDelegate respondsToSelector:@selector(noCreditPushTo:)]) {
            [self.liveDelegate noCreditPushTo:self];
        }
    }];
    [alertVC addAction:canaelAC];
    [alertVC addAction:addAC];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - 界面事件
- (IBAction)showAction:(id)sender {
    self.stopVideoBtn.hidden = NO;
    self.muteBtn.hidden = NO;

    @synchronized(self) {
        self.videoBtnLeftSecond = 3;
    }
}

- (IBAction)muteAction:(id)sender {
    self.publisher.mute = !self.publisher.mute;
    self.muteBtn.selected = !self.muteBtn.selected;

    @synchronized(self) {
        self.videoBtnLeftSecond = 3;
    }
}

- (IBAction)startOneOnOneAction:(id)sender {
    LSNavigationController *nvc = (LSNavigationController *)self.navigationController;
    [nvc forceToDismissAnimated:NO completion:nil];
    [[LiveModule module].moduleVC.navigationController popToViewController:[LiveModule module].moduleVC animated:NO];

    NSURL *url = [[LiveUrlHandler shareInstance] createUrlToInviteByRoomId:@"" anchorId:self.liveRoom.userId roomType:LiveRoomType_Private];
    [[LiveUrlHandler shareInstance] handleOpenURL:url];
}

- (IBAction)showRewardView:(id)sender {
    [[LiveModule module].analyticsManager reportActionEvent:VipBroadcastClickReward eventCategory:EventCategoryBroadcast];
    if ([self.liveDelegate respondsToSelector:@selector(bringRewardViewInTop:)]) {
        [self.liveDelegate bringRewardViewInTop:self];
    }
}

- (IBAction)startHangoutBtnDid:(UIButton *)sender {
    if ([self.liveDelegate respondsToSelector:@selector(showHangoutTipView:)]) {
        [self.liveDelegate showHangoutTipView:self];
    }
}

#pragma mark - 流[播放/推送]逻辑
- (void)play {
    self.playUrl = self.liveRoom.playUrl;
    NSLog(@"LiveViewController::play( [开始播放流], playUrl : %@ )", self.playUrl);
    [self debugInfo];

    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *recordDir = [NSString stringWithFormat:@"%@/record", cacheDir];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:recordDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *dateString = [LSDateFormatter toStringYMDHMSWithUnderLine:[NSDate date]];
    NSString *recordFilePath = [LiveModule module].debug ? [NSString stringWithFormat:@"%@/%@_%@.flv", recordDir, self.liveRoom.userId, dateString] : @"";
    NSString *recordH264FilePath = @""; //[NSString stringWithFormat:@"%@/%@", recordDir, @"play.h264"];
    NSString *recordAACFilePath = @"";  //[NSString stringWithFormat:@"%@/%@", recordDir, @"play.aac"];

    // 开始转菊花
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL bFlag = [self.player playUrl:self.playUrl recordFilePath:recordFilePath recordH264FilePath:recordH264FilePath recordAACFilePath:recordAACFilePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 停止菊花
            if (bFlag) {
                // 播放成功
                if ([self.liveDelegate respondsToSelector:@selector(liveViewIsPlay:)]) {
                    [self.liveDelegate liveViewIsPlay:self];
                }
                if (self.liveRoom.roomType != LiveRoomType_Public) {
                    self.rewardedBgView.hidden = YES;
                    self.rewardedBtn.hidden = YES;
                }
            } else {
                // 播放失败
            }
        });
    });
}

- (void)stopPlay {
    NSLog(@"LiveViewController::stopPlay()");

    [self.player stop];
}

- (void)initPublish {
    NSLog(@"LiveViewController::initPublish( [初始化推送流] )");
    // 初始化采集
    [[LiveStreamSession session] checkAudio:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedStringFromSelf(@"Open_Permissions_Tip") preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionOK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *_Nonnull action){

                                                                 }];
                [alertVC addAction:actionOK];
                [self presentViewController:alertVC animated:NO completion:nil];
            }
        });
    }];

    [[LiveStreamSession session] checkVideo:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedStringFromSelf(@"Open_Permissions_Tip") preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionOK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *_Nonnull action){

                                                                 }];
                [alertVC addAction:actionOK];
                [self presentViewController:alertVC animated:NO completion:nil];
            }
        });
    }];

    // 初始化预览界面
    self.publisher.publishView = self.previewVideoView;
    self.publisher.publishView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
}

- (void)publish {
    self.publishUrl = self.liveRoom.publishUrl;
    NSLog(@"LiveViewController::publish( [开始推送流], publishUrl : %@ )", self.publishUrl);
    [self debugInfo];
    [self.publisher pushlishUrl:self.publishUrl recordH264FilePath:@"" recordAACFilePath:@""];
}

- (void)stopPublish {
    NSLog(@"LiveViewController::stopPublish()");
    [self.publisher stop];
}

#pragma mark - 流[播放/推送]通知
- (NSString *_Nullable)playerShouldChangeUrl:(LiveStreamPlayer *_Nonnull)player {
    NSString *url = player.url;

    @synchronized(self) {
        if (self.playerReconnectTime++ > STREAM_PLAYER_RECONNECT_MAX_TIMES) {
            // 断线超过指定次数, 切换URL
            url = [self.liveRoom changePlayUrl];
            self.playerReconnectTime = 0;

            NSLog(@"LiveViewController::playerShouldChangeUrl( [切换播放流URL], url : %@)", url);
        }
    }

    return url;
}

- (NSString *_Nullable)publisherShouldChangeUrl:(LiveStreamPublisher *_Nonnull)publisher {
    NSString *url = publisher.url;

    @synchronized(self) {
        if (self.publisherReconnectTime++ > STREAM_PUBLISH_RECONNECT_MAX_TIMES) {
            // 断线超过指定次数, 切换URL
            url = [self.liveRoom changePublishUrl];
            self.publisherReconnectTime = 0;

            NSLog(@"LiveViewController::publisherShouldChangeUrl( [切换推送流URL], url : %@)", url);
        }
    }

    return url;
}

#pragma mark - 关闭/开启直播间声音(LiveChat使用)
- (void)openOrCloseSuond:(BOOL)isClose {
    self.publisher.mute = isClose;
    self.player.mute = isClose;
}

#pragma mark - 初始化座驾控件
- (void)setupDriveView {

    // 初始化座驾播放标志
    self.isDriveShow = NO;

    self.driveView = [[DriveView alloc] init];
    [self.driveView setupViewColor:self.roomStyleItem];
    self.driveView.alpha = 0.3;
    self.driveView.delegate = self;
    self.driveView.hidden = YES;
    [self.view addSubview:self.driveView];
}

#pragma mark - 座驾（入场信息）
- (void)canPlayDirve:(DriveView *)driveView audienceModel:(AudienceModel *)model offset:(int)offset ifError:(NSError *)error {
    if (error) {
        // 移除错误下载
        [self drivePlayCallback];
    } else {
        [self.driveView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@6);
            make.right.equalTo(self.view.mas_right).offset(offset);
            make.width.equalTo(@(offset));
        }];
        // 播放座驾动画
        [self driveAnimationOffset:offset];
    }
}

- (void)getDriveInfo:(NSString *)userId {

    NSLog(@"LiveViewController::getDriveInfo( [获取座驾], userId : %@ )", userId);
    [self.roomUserInfoManager getFansBaseInfo:userId
                                finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        @synchronized(self) {
                                            if (item.riderId.length > 0) {
                                                AudienceModel *model = [[AudienceModel alloc] init];
                                                model.userid = userId;
                                                model.nickname = item.nickName;
                                                model.photourl = item.photoUrl;
                                                model.riderid = item.riderId;
                                                model.riderurl = item.riderUrl;
                                                model.ridername = item.riderName;
                                                [self.audienArray addObject:model];
                                                if (!self.isDriveShow) {
                                                    self.isDriveShow = YES;
                                                    [self.driveView audienceComeInLiveRoom:self.audienArray[0]];
                                                }

                                                // 插入自己座驾入场消息
                                                [self addRiderJoinMessageNickName:item.nickName riderName:item.riderName honorUrl:self.liveRoom.imLiveRoom.honorImg fromId:self.loginManager.loginItem.userId isHasTicket:self.liveRoom.httpLiveRoom.showInfo.ticketStatus == PROGRAMTICKETSTATUS_BUYED ? YES : NO];

                                            } else {
                                                // 插入自己入场消息
                                                MsgItem *msgItem = [self addJoinMessageNickName:item.nickName honorUrl:self.liveRoom.imLiveRoom.honorImg fromId:self.loginManager.loginItem.userId isHasTicket:self.liveRoom.httpLiveRoom.showInfo.ticketStatus == PROGRAMTICKETSTATUS_BUYED ? YES : NO];
                                                [self addMsg:msgItem replace:NO scrollToEnd:YES animated:YES];
                                            }
                                        }
                                    });
                                }];
}

#pragma mark - 座驾入场动画
- (void)driveAnimationOffset:(int)offset {
    [self.view layoutIfNeeded];

    self.driveView.hidden = NO;
    [self.driveView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(-13);
    }];

    [UIView animateWithDuration:2
        animations:^{
            self.driveView.alpha = 1;
            [self.view layoutIfNeeded];

        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5
                delay:1
                options:0
                animations:^{
                    self.driveView.alpha = 0;
                }
                completion:^(BOOL finished) {
                    //                    [weakSelf.driveView mas_updateConstraints:^(MASConstraintMaker *make) {
                    //                        make.right.equalTo(self.view.mas_right).offset(offset);
                    //                    }];
                    self.driveView.hidden = YES;
                    // 播放完回调
                    [self drivePlayCallback];
                }];
        }];
}

#pragma mark - 座驾动画播放完回调
- (void)drivePlayCallback {

    if (self.audienArray.count) {
        [self.audienArray removeObjectAtIndex:0];

        if (self.audienArray.count) {
            self.isDriveShow = YES;
            [self.driveView audienceComeInLiveRoom:self.audienArray[0]];
        } else {
            self.isDriveShow = NO;
        }
    }
}

#pragma mark - 连击管理
- (void)setupGiftView {
    [self.giftView removeAllSubviews];

    self.giftComboViews = [NSMutableArray array];
    self.giftComboViewsLeadings = [NSMutableArray array];

    GiftComboView *preGiftComboView = nil;

    for (int i = 0; i < 2; i++) {
        GiftComboView *giftComboView = [GiftComboView giftComboView:self];
        [self.giftView addSubview:giftComboView];
        [self.giftComboViews addObject:giftComboView];

        giftComboView.tag = i;
        giftComboView.delegate = self;
        giftComboView.hidden = YES;

        UIImage *image = self.roomStyleItem.comboViewBgImage; // [UIImage imageNamed:@"Live_Public_Bg_Combo"]
        [giftComboView.backImageView setImage:image];

        NSNumber *height = [NSNumber numberWithInteger:giftComboView.frame.size.height];

        if (!preGiftComboView) {
            [giftComboView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.giftView);
                make.width.equalTo(@220);
                make.height.equalTo(height);
                MASConstraint *leading = make.left.equalTo(self.giftView.mas_left).offset(-220);
                [self.giftComboViewsLeadings addObject:leading];
            }];

        } else {
            [giftComboView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(preGiftComboView.mas_top).offset(-5);
                make.width.equalTo(@220);
                make.height.equalTo(height);
                MASConstraint *leading = make.left.equalTo(self.giftView.mas_left).offset(-220);
                [self.giftComboViewsLeadings addObject:leading];
            }];
        }

        preGiftComboView = giftComboView;
    }
}

- (BOOL)showCombo:(GiftItem *)giftItem giftComboView:(GiftComboView *)giftComboView withUserID:(NSString *)userId {
    BOOL bFlag = YES;

    giftComboView.hidden = NO;

    // 发送人名 礼物名
    giftComboView.nameLabel.text = giftItem.nickname;
    giftComboView.sendLabel.text = giftItem.giftname;

    // 数量
    giftComboView.beginNum = giftItem.multi_click_start;
    giftComboView.endNum = giftItem.multi_click_end;

    NSLog(@"LiveViewController::showCombo( [显示连击礼物], beginNum : %ld, endNum: %ld, clickID : %ld )", (long)giftComboView.beginNum, (long)giftComboView.endNum, (long)giftItem.multi_click_id);

    // 连击礼物
    LSGiftManagerItem *item = [self.giftDownloadManager getGiftItemWithId:giftItem.giftid];
    NSString *imgUrl = item.infoItem.bigImgUrl;
    [self.giftImageLoader loadImageWithImageView:giftComboView.giftImageView
                                         options:0
                                        imageUrl:imgUrl
                                placeholderImage:
                                    [UIImage imageNamed:@"Live_Gift_Nomal"]
                                   finishHandler:nil];

    giftComboView.item = giftItem;

    // 获取用户头像
    [self.roomUserInfoManager getUserInfo:userId
                            finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    // 当前用户
                                    [self.headImageLoader loadImageFromCache:giftComboView.iconImageView
                                                                         options:SDWebImageRefreshCached
                                                                        imageUrl:item.photoUrl
                                                                placeholderImage:[UIImage imageNamed:@"Default_Img_Man_Circyle"]
                                                                   finishHandler:^(UIImage *image){
                                                                   }];
                                });
                            }];

    // 从左到右
    NSInteger index = giftComboView.tag;
    MASConstraint *giftComboViewsLeading = [self.giftComboViewsLeadings objectAtIndex:index];
    [giftComboViewsLeading uninstall];
    [giftComboView mas_updateConstraints:^(MASConstraintMaker *make) {
        MASConstraint *newGiftComboViewLeading = make.left.equalTo(self.giftView.mas_left).offset(10);
        [self.giftComboViewsLeadings replaceObjectAtIndex:index withObject:newGiftComboViewLeading];
    }];

    [giftComboView reset];
    [giftComboView start];

    NSTimeInterval duration = 0.3;
    [UIView animateWithDuration:duration
        animations:^{
            [self.giftView layoutIfNeeded];

        }
        completion:^(BOOL finished) {
            // 开始连击
            [giftComboView playGiftCombo];
        }];

    return bFlag;
}

- (void)addCombo:(GiftItem *)giftItem {
    // 寻找可用界面
    GiftComboView *giftComboView = nil;

    for (GiftComboView *view in self.giftComboViews) {
        if (!view.playing) {
            // 寻找空闲的界面
            giftComboView = view;

        } else {

            if ([view.item.itemId isEqualToString:giftItem.itemId]) {

                // 寻找正在播放同一个连击礼物的界面
                giftComboView = view;
                // 更新最后连击数字
                giftComboView.endNum = giftItem.multi_click_end;
                break;
            }
        }
    }

    if (giftComboView) {
        // 有空闲的界面
        if (!giftComboView.playing) {
            // 开始播放新的礼物连击
            [self showCombo:giftItem giftComboView:giftComboView withUserID:giftItem.fromid];
            NSLog(@"LiveViewController::addCombo( [增加连击礼物, 播放], starNum : %ld, endNum : %ld, clickID : %ld )", (long)giftItem.multi_click_start, (long)giftItem.multi_click_end, (long)giftItem.multi_click_id);
        }

    } else {
        // 没有空闲的界面, 放到缓存
        [self.giftComboManager pushGift:giftItem];
        NSLog(@"LiveViewController::addCombo( [增加连击礼物, 缓存], starNum : %ld, endNum : %ld, clickID : %ld )", (long)giftItem.multi_click_start, (long)giftItem.multi_click_end, (long)giftItem.multi_click_id);
    }
}

#pragma mark - 连击回调(GiftComboViewDelegate)
- (void)playComboFinish:(GiftComboView *)giftComboView {
    // 收回界面
    NSInteger index = giftComboView.tag;
    MASConstraint *giftComboViewsLeading = [self.giftComboViewsLeadings objectAtIndex:index];
    [giftComboViewsLeading uninstall];
    [giftComboView mas_updateConstraints:^(MASConstraintMaker *make) {
        MASConstraint *newGiftComboViewLeading = make.left.equalTo(self.giftView.mas_left).offset(-220);
        [self.giftComboViewsLeadings replaceObjectAtIndex:index withObject:newGiftComboViewLeading];
    }];
    giftComboView.hidden = YES;
    [self.giftView layoutIfNeeded];

    // 显示下一个
    GiftItem *giftItem = [self.giftComboManager popGift:nil];
    if (giftItem) {
        // 开始播放新的礼物连击
        [self showCombo:giftItem giftComboView:giftComboView withUserID:giftItem.fromid];
    }
}

#pragma mark - 播放大礼物
- (void)starBigAnimationWithGiftID:(NSString *)giftID {
    self.giftAnimationView = [BigGiftAnimationView sharedObject];
    self.giftAnimationView.userInteractionEnabled = NO;

    LSGiftManagerItem *item = [self.giftDownloadManager getGiftItemWithId:giftID];
    LSYYImage *image = item.bigGiftImage;

    // 判断本地文件是否损伤 有则播放 无则删除重下播放下一个
    if (image) {
        //        UIWindow *window = [UIApplication sharedApplication].delegate.window;
        self.giftAnimationView.contentMode = UIViewContentModeScaleAspectFit;
        self.giftAnimationView.image = image;
        [self.liveRoom.superView addSubview:self.giftAnimationView];
        [self.liveRoom.superView bringSubviewToFront:self.giftAnimationView];
        [self.giftAnimationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.liveRoom.superView);
            make.width.height.equalTo(self.liveRoom.superView);
        }];
        [self bringLiveRoomSubView];

    } else {
        // 重新下载
        [item download];
        // 结束动画
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GiftAnimationIsOver" object:self userInfo:nil];
    }
}

// 遍历最外层控制器视图 将dialog放到最上层
- (void)bringLiveRoomSubView {
    for (UIView *view in self.liveRoom.superView.subviews) {
        if (IsDialog(view)) {
            [self.liveRoom.superView bringSubviewToFront:view];
        }
    }
}

#pragma mark - 通知大动画结束
- (void)animationWhatIs:(NSNotification *)notification {
    if (self.giftAnimationView) {
        [self.giftAnimationView removeFromSuperview];
        self.giftAnimationView = nil;

        if (self.bigGiftArray.count) {
            [self.bigGiftArray removeObjectAtIndex:0];
        }
    }
    if (self.bigGiftArray.count) {
        [self starBigAnimationWithGiftID:self.bigGiftArray[0]];
    }
}

#pragma mark - 弹幕管理
- (void)setupBarrageView {
    self.barrageView.delegate = self;
    self.barrageView.dataSouce = self;
}

#pragma mark - 弹幕回调(BarrageView)
- (NSUInteger)numberOfRowsInTableView:(BarrageView *)barrageView {
    return 1;
}

- (BarrageViewCell *)barrageView:(BarrageView *)barrageView cellForModel:(id<BarrageModelAble>)model {
    BarrageModelCell *cell = [BarrageModelCell cellWithBarrageView:barrageView];
    BarrageModel *bgItem = (BarrageModel *)model;
    cell.model = bgItem;
    NSLog(@"LiveViewController:: barrageView message:%@", bgItem.message);
    // 获取用户头像
    [self.roomUserInfoManager getUserInfo:bgItem.userId
                            finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.headImageLoader loadImageFromCache:cell.imageViewHeader
                                                                         options:SDWebImageRefreshCached
                                                                        imageUrl:item.photoUrl
                                                                placeholderImage:[UIImage imageNamed:@"Default_Img_Man_Circyle"]
                                                                   finishHandler:^(UIImage *image){
                                                                   }];
                                });
                            }];

    cell.labelName.text = bgItem.name;
    cell.labelMessage.attributedText = [self.emotionManager parseMessageTextEmotion:bgItem.message font:[UIFont boldSystemFontOfSize:15]];

    return cell;
}

- (void)barrageView:(BarrageView *)barrageView didSelectedCell:(BarrageViewCell *)cell {
}

- (void)barrageView:(BarrageView *)barrageView willDisplayCell:(BarrageViewCell *)cell {
    self.showToastNum += 1;
    self.barrageView.hidden = NO;
}

- (void)barrageView:(BarrageView *)barrageView didEndDisplayingCell:(BarrageViewCell *)cell {
    self.showToastNum -= 1;

    if (self.showToastNum == 0) {
        self.barrageView.hidden = YES;
    }
}

#pragma mark - 消息列表管理
- (void)setupTableView {
    
    self.msgSuperViewBottom.constant = 143;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.msgTableView setTableFooterView:footerView];

    self.msgTableView.clipsToBounds = YES;
    self.msgTableView.backgroundView = nil;
    self.msgTableView.backgroundColor = [UIColor clearColor];
    self.msgTableView.contentInset = UIEdgeInsetsMake(12, 0, 0, 0);
    [self.msgTableView registerClass:[MsgTableViewCell class] forCellReuseIdentifier:[MsgTableViewCell cellIdentifier]];
    [self.msgTableView registerClass:[HangOutOpenDoorCell class] forCellReuseIdentifier:[HangOutOpenDoorCell cellIdentifier]];

    self.msgTipsView.clipsToBounds = YES;
    self.msgTipsView.layer.cornerRadius = 6.0;
    self.msgTipsView.hidden = YES;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMsgTipsView:)];
    [self.msgTipsView addGestureRecognizer:singleTap];

    [self.view insertSubview:self.barrageView aboveSubview:self.tableSuperView];
}

- (BOOL)sendMsg:(NSString *)text isLounder:(BOOL)isLounder {
    BOOL bFlag = NO;
    BOOL bDebug = NO;

    bDebug = [self handleDebugCmd:text];
    NSString *str = [text stringByReplacingOccurrencesOfString:@" " withString:@""];

    // 发送IM文本
    if (!bDebug) {
        if (str.length > 0) {
            bFlag = YES;
            if (isLounder) {
                // 调用IM命令(发送弹幕)
                [self sendRoomToastRequestFromText:text];

            } else {
                // 调用IM命令(发送直播间消息)
                [self sendRoomMsgRequestFromText:text];
            }
        }
    }

    return bFlag;
}

- (void)addTips:(NSAttributedString *)text {
    MsgItem *item = [[MsgItem alloc] init];
    item.text = text.string;
    item.msgType = MsgType_Announce;
    NSMutableAttributedString *attributeString = [self.msgManager presentTheRoomStyleItem:self.roomStyleItem msgItem:item];
    item.attText = attributeString;
    [self addMsg:item replace:NO scrollToEnd:YES animated:YES];
}

#pragma mark - 聊天文本消息管理
// 插入普通聊天消息
- (void)addChatMessageNickName:(NSString *)name text:(NSString *)text honorUrl:(NSString *)honorUrl fromId:(NSString *)fromId
                   isHasTicket:(BOOL)isHasTicket {
    // 发送普通消息
    MsgItem *item = [[MsgItem alloc] init];

    // 判断是谁发送
    if ([fromId isEqualToString:self.loginManager.loginItem.userId]) {
        item.usersType = UsersType_Me;

    } else if ([fromId isEqualToString:self.liveRoom.userId]) {
        item.usersType = UsersType_Liver;

    } else {
        item.usersType = UsersType_Audience;
    }
    item.msgType = MsgType_Chat;
    item.sendName = name;
    item.text = text;
    item.honorUrl = honorUrl;
    item.isHasTicket = isHasTicket;

    if (text.length > 0) {
        NSMutableAttributedString *attributeString = [self.msgManager setupChatMessageStyle:self.roomStyleItem msgItem:item];
        item.attText = [self.emotionManager parseMessageAttributedTextEmotion:attributeString font:MessageFont];
    }
    // 插入到消息列表
    [self addMsg:item replace:NO scrollToEnd:YES animated:YES];
}

// 插入送礼消息
- (void)addGiftMessageNickName:(NSString *)nickName giftID:(NSString *)giftID giftNum:(int)giftNum honorUrl:(NSString *)honorUrl
                        fromId:(NSString *)fromId
                   isHasTicket:(BOOL)isHasTicket {

    LSGiftManagerItem *item = [[LSGiftManager manager] getGiftItemWithId:giftID];

    MsgItem *msgItem = [[MsgItem alloc] init];
    // 判断是谁发送
    if ([fromId isEqualToString:self.loginManager.loginItem.userId]) {
        msgItem.usersType = UsersType_Me;

    } else if ([fromId isEqualToString:self.liveRoom.userId]) {
        msgItem.usersType = UsersType_Liver;

    } else {
        msgItem.usersType = UsersType_Audience;
    }
    msgItem.msgType = MsgType_Gift;
    msgItem.giftType = item.infoItem.type;
    msgItem.sendName = nickName;
    msgItem.giftName = item.infoItem.name;

    LSGiftManagerItem *giftItem = [[LSGiftManager manager] getGiftItemWithId:giftID];
    msgItem.smallImgUrl = giftItem.infoItem.smallImgUrl;

    msgItem.giftNum = giftNum;
    msgItem.honorUrl = honorUrl;
    msgItem.isHasTicket = isHasTicket;
    // 增加文本消息
    NSMutableAttributedString *attributeString = [self.msgManager setupGiftMessageStyle:self.roomStyleItem msgItem:msgItem];
    msgItem.attText = attributeString;

    [self addMsg:msgItem replace:NO scrollToEnd:YES animated:YES];
}

- (MsgItem *)addJoinMessageNickName:(NSString *)nickName honorUrl:(NSString *)honorUrl fromId:(NSString *)fromId isHasTicket:(BOOL)isHasTicket {
    MsgItem *msgItem = [[MsgItem alloc] init];
    // 判断是谁
    if ([fromId isEqualToString:self.loginManager.loginItem.userId]) {
        msgItem.usersType = UsersType_Me;

    } else if ([fromId isEqualToString:self.liveRoom.userId]) {
        msgItem.usersType = UsersType_Liver;

    } else {
        msgItem.usersType = UsersType_Audience;
    }
    msgItem.msgType = MsgType_Join;
    msgItem.sendName = nickName;
    msgItem.honorUrl = honorUrl;
    msgItem.isHasTicket = isHasTicket;
    NSMutableAttributedString *attributeString = [self.msgManager presentTheRoomStyleItem:self.roomStyleItem msgItem:msgItem];
    msgItem.attText = attributeString;
    return msgItem;
}

- (void)addRiderJoinMessageNickName:(NSString *)nickName riderName:(NSString *)riderName honorUrl:(NSString *)honorUrl fromId:(NSString *)fromId isHasTicket:(BOOL)isHasTicket {
    // 用户座驾入场信息
    MsgItem *riderItem = [[MsgItem alloc] init];
    // 判断是谁
    if ([fromId isEqualToString:self.loginManager.loginItem.userId]) {
        riderItem.usersType = UsersType_Me;

    } else if ([fromId isEqualToString:self.liveRoom.userId]) {
        riderItem.usersType = UsersType_Liver;

    } else {
        riderItem.usersType = UsersType_Audience;
    }
    riderItem.msgType = MsgType_RiderJoin;
    riderItem.sendName = nickName;
    riderItem.riderName = riderName;
    riderItem.honorUrl = honorUrl;
    riderItem.isHasTicket = isHasTicket;
    NSMutableAttributedString *riderString = [self.msgManager presentTheRoomStyleItem:self.roomStyleItem msgItem:riderItem];
    riderItem.attText = riderString;
    [self addMsg:riderItem replace:NO scrollToEnd:YES animated:YES];
}

- (void)addMsg:(MsgItem *)item replace:(BOOL)replace scrollToEnd:(BOOL)scrollToEnd animated:(BOOL)animated {
    // 计算文本高度
    if (item.msgType == MsgType_Knock || item.msgType == MsgType_Recommend) {
        item.containerHeight = OpenDoorHeight;
    } else {
        item.containerHeight = [self computeContainerHeight:item];
    }

    // 计算当前显示的位置
    NSInteger lastVisibleRow = -1;
    if (self.msgTableView.indexPathsForVisibleRows.count > 0) {
        lastVisibleRow = [self.msgTableView.indexPathsForVisibleRows lastObject].row;
    }
    NSInteger lastRow = self.msgShowArray.count - 1;

    // 计算消息数量
    BOOL deleteOldMsg = NO;
    @synchronized(self.msgArray) {
        if (self.msgArray.count > 0) {
            if (replace) {
                deleteOldMsg = YES;
                // 删除一条最新消息
                [self.msgArray removeObjectAtIndex:self.msgArray.count - 1];

            } else {
                deleteOldMsg = (self.msgArray.count >= MessageCount);
                if (deleteOldMsg) {
                    // 超出最大消息限制, 删除一条最旧消息
                    [self.msgArray removeObjectAtIndex:0];
                }
            }
        }
        // 增加新消息
        [self.msgArray addObject:item];
    }

    if (lastVisibleRow >= lastRow) {
        // 如果消息列表当前能显示最新的消息

        // 直接刷新
        [self.msgTableView beginUpdates];
        if (deleteOldMsg) {
            if (replace) {
                // 删除一条最新消息
                [self.msgTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.msgShowArray.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

            } else {
                // 超出最大消息限制, 删除列表一条旧消息

                [self.msgTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }

        // 替换显示的消息列表
        self.msgShowArray = [NSMutableArray arrayWithArray:self.msgArray];

        // 增加列表一条新消息
        [self.msgTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.msgShowArray.count - 1 inSection:0]] withRowAnimation:(deleteOldMsg && replace) ? UITableViewRowAnimationNone : UITableViewRowAnimationBottom];

        [self.msgTableView endUpdates];

        // 拉到最底
        if (scrollToEnd) {
            [self scrollToEnd:animated];
        }

    } else {
        // 标记为需要刷新数据
        self.needToReload = YES;

        // 显示提示信息
        [self showUnReadMsg];
    }
}

- (void)scrollToEnd:(BOOL)animated {
    NSInteger count = [self.msgTableView numberOfRowsInSection:0];
    if (count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count - 1 inSection:0];
        [self.msgTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)showUnReadMsg {
    self.unReadMsgCount++;

    if (!self.tableSuperView.hidden) {
        self.msgTipsView.hidden = NO;
    }
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld ", (long)self.unReadMsgCount]];
    [attString addAttributes:@{
        NSFontAttributeName : UnReadMsgCountFont,
        NSForegroundColorAttributeName : UnReadMsgCountColor
    }
                       range:NSMakeRange(0, attString.length)];

    NSMutableAttributedString *attStringMsg = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromSelf(@"UnRead_Messages")];
    [attStringMsg addAttributes:@{
        NSFontAttributeName : UnReadMsgTipsFont,
        NSForegroundColorAttributeName : UnReadMsgTipsColor
    }
                          range:NSMakeRange(0, attStringMsg.length)];
    [attString appendAttributedString:attStringMsg];
    self.msgTipsLabel.attributedText = attString;
}

- (void)hideUnReadMsg {
    self.unReadMsgCount = 0;
    self.msgTipsView.hidden = YES;
}

- (void)tapMsgTipsView:(id)sender {
    [self scrollToEnd:YES];

    //    [self scrollViewDidScroll:self.msgTableView];
}

// 可能有用
/**
 聊天图片富文本

 @param image 图片
 @param font 字体
 @return 富文本
 */
- (NSAttributedString *)parseImageMessage:(UIImage *)image font:(UIFont *)font {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] init];

    LSChatTextAttachment *attachment = nil;

    // 增加表情文本
    attachment = [[LSChatTextAttachment alloc] init];
    //    attachment.bounds = CGRectMake(0, 0, font.lineHeight, font.lineHeight);
    attachment.image = image;

    // 生成表情富文本
    NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributeString appendAttributedString:imageString];

    return attributeString;
}

- (CGFloat)computeContainerHeight:(MsgItem *)item {
    CGFloat height = 0;
    CGFloat width = self.tableSuperView.frame.size.width;
    YYTextContainer *container = [[YYTextContainer alloc] init];
    if (item.msgType == MsgType_Gift) {
        width = width - 3;
    }
    container.size = CGSizeMake(width, CGFLOAT_MAX);
    YYTextLayout *layout = [YYTextLayout layoutWithContainer:container text:item.attText];
    height = layout.textBoundingSize.height + 1;
    if (height < 22) {
        height = 22;
    }
    item.layout = layout;
    item.labelFrame = CGRectMake(0, 0, layout.textBoundingSize.width, height);
    return height;
}

#pragma mark - 消息列表列表界面回调 (UITableViewDataSource / UITableViewDelegate)
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int count = 1;
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = self.msgArray ? self.msgArray.count : 0;

    return number;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MsgItem *item = [self.msgShowArray objectAtIndex:indexPath.row];
    if (item.msgType == MsgType_Talent) {
        return [TalentMsgCell cellHeight];
    }
    return item.containerHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    // 数据填充
    if (indexPath.row < self.msgShowArray.count) {
        MsgItem *item = [self.msgShowArray objectAtIndex:indexPath.row];

        switch (item.msgType) {
            case MsgType_Talent: {
                TalentMsgCell *msgCell = [TalentMsgCell getUITableViewCell:tableView];
                [msgCell updateMsg:item];
                msgCell.talentCellDelegate = self;
                cell = msgCell;
            } break;

            case MsgType_Knock:
            case MsgType_Recommend: {
                HangOutOpenDoorCell *msgCell = [tableView dequeueReusableCellWithIdentifier:[HangOutOpenDoorCell cellIdentifier]];
                msgCell.delagate = self;
                [msgCell updataChatMessage:item];
                cell = msgCell;
            } break;

            default: {
                MsgTableViewCell *msgCell = [tableView dequeueReusableCellWithIdentifier:[MsgTableViewCell cellIdentifier]];
                msgCell.clipsToBounds = YES;
                msgCell.msgDelegate = self;
//                [msgCell changeMessageLabelWidth:tableView.frame.size.width];
                [msgCell updataChatMessage:item styleItem:self.roomStyleItem];
                cell = msgCell;
            } break;
        }

    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@""];
        if (!cell) {
            cell = [[UITableViewCell alloc] init];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)talentMsgCellDid {

    [[NSNotificationCenter defaultCenter] postNotificationName:@"showTalentList" object:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger lastVisibleRow = -1;
    if (self.msgTableView.indexPathsForVisibleRows.count > 0) {
        lastVisibleRow = [self.msgTableView.indexPathsForVisibleRows lastObject].row;
    }
    NSInteger lastRow = self.msgShowArray.count - 1;

    if (self.msgShowArray.count > 0 && lastVisibleRow <= lastRow) {
        // 已经拖动到最底, 刷新界面
        if (self.needToReload) {
            self.needToReload = NO;

            // 收起提示信息
            [self hideUnReadMsg];

            // 刷新消息列表
            self.msgShowArray = [NSMutableArray arrayWithArray:self.msgArray];
            [self.msgTableView reloadData];

            // 同步位置
            [self scrollToEnd:NO];
        }
    }
}

#pragma mark - MsgTableViewCellDelegate
- (void)msgCellRequestHttp:(NSString *)linkUrl {
    LiveWebViewController *webViewController = [[LiveWebViewController alloc] initWithNibName:nil bundle:nil];
    webViewController.url = linkUrl;
    webViewController.isIntimacy = NO;
    [self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark - HangOutOpenDoorCellDelegate
- (void)inviteHangoutAnchor:(MsgItem *)item {
    //[[LiveModule module].analyticsManager reportActionEvent:ClickHangOutNow eventCategory:EventCategoryBroadcast];
    // 处理主播推荐好友请求
   // [self inviteAnchorWithHangout:item.recommendItem.recommendId anchorId:item.recommendItem.friendId anchorName:item.recommendItem.friendNickName];
}

- (void)agreeAnchorKnock:(MsgItem *)item {
}

#pragma mark - HTTP请求
// TODO:直播间发送Hangout邀请
/*
- (void)inviteAnchorWithHangout:(NSString *)recommendId anchorId:(NSString *)anchorId anchorName:(NSString *)anchorName {
    if (!self.isInvitingHangout) {
        self.isInvitingHangout = YES;
        // 显示提示控件
        //[self showRoomTipView:[NSString stringWithFormat:NSLocalizedStringFromSelf(@"INVITING_HANG_OUT"), self.liveRoom.userName] isReject:NO];
        
        LSSendinvitationHangoutRequest *request = [[LSSendinvitationHangoutRequest alloc] init];
        request.roomId = self.liveRoom.roomId;
        request.anchorId = self.liveRoom.userId;
        request.recommendId = recommendId;
        request.isCreateOnly = YES;
        request.finishHandler = ^(BOOL success, HTTP_LCC_ERR_TYPE errnum, NSString *_Nonnull errmsg, NSString *_Nonnull roomId, NSString *_Nonnull inviteId, int expire) {
            NSLog(@"LiveViewController::sendHangoutInvite( [发起多人互动邀请], success : %@, errnum : %d, errmsg : %@, roomId : %@, inviteId : %@, expire : %d )",
                  BOOL2SUCCESS(success), errnum, errmsg, roomId, inviteId, expire);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errnum == HTTP_LCC_ERR_SUCCESS) {
                    if (recommendId.length > 0) {
                        self.isRecommend = YES;
                    }
                    self.hangoutInviteId = inviteId;
                    self.hangoutAnchorName = anchorName;
                    self.hangoutAnchorId = anchorId;
                } else {
                    self.isInvitingHangout = NO;
                    
                    self.isRecommend = NO;
                    self.isInviteHangout = NO;
                    self.hangoutInviteId = nil;
                    // 发送邀请失败提示
                    [self.dialogProbationTip showDialogTip:self.liveRoom.superView tipText:errmsg];
                    self.roomTipView.hidden = YES;
                    
                    // 如果没钱
                    if (errnum == HTTP_LCC_ERR_NO_CREDIT) {
                        [self showAddCreditsView:NSLocalizedStringFromSelf(@"SEND_INVITE_NO_CREDIT")];
                    }
                }
            });
        };
        [self.sessionManager sendRequest:request];
    }
}

// TODO:查询Hangout邀请状态
- (void)getHangoutInviteStatu {

    if (self.hangoutInviteId.length > 0) {
        LSGetHangoutInvitStatusRequest *request = [[LSGetHangoutInvitStatusRequest alloc] init];
        request.inviteId = self.hangoutInviteId;
        request.finishHandler = ^(BOOL success, HTTP_LCC_ERR_TYPE errnum, NSString *_Nonnull errmsg, HangoutInviteStatus status, NSString *_Nonnull roomId, int expire) {
            NSLog(@"LiveViewController::getHangoutInviteStatu( [查询多人互动邀请状态] success : %@, errnum : %d, errmsg : %@,"
                   "status : %d, roomId : %@, expire : %d )",
                  BOOL2SUCCESS(success), errnum, errmsg, status, roomId, expire);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    switch (status) {
                        case IMREPLYINVITETYPE_AGREE: {
                            self.isInvitingHangout = YES;
                            self.isInviteHangout = YES;
                            //[self showRoomTipView:NSLocalizedStringFromSelf(@"INVITE_SUCCESS_HANGOUT") isReject:NO];
                            if (roomId.length > 0) {
                                // 拼接push跳转多人互动url
                                if (self.isRecommend) {
                                    self.pushUrl = [[LiveUrlHandler shareInstance] createUrlToHangoutByRoomId:roomId anchorId:self.hangoutAnchorId anchorName:self.hangoutAnchorName hangoutAnchorId:self.liveRoom.userId hangoutAnchorName:self.liveRoom.userName];
                                } else {
                                    self.pushUrl = [[LiveUrlHandler shareInstance] createUrlToHangoutByRoomId:roomId anchorId:self.hangoutAnchorId anchorName:self.hangoutAnchorName hangoutAnchorId:@"" hangoutAnchorName:@""];
                                }
                            }
                        } break;

                        case IMREPLYINVITETYPE_NOCREDIT: {
                            self.isInvitingHangout = NO;
                            [self showAddCreditsView:NSLocalizedString(@"INVITE_HANGOUT_ADDCREDIT", nil)];
                        } break;

                        default: {
                            self.isInvitingHangout = NO;
                            self.isRecommend = NO;
                            self.isInviteHangout = NO;
                            self.hangoutInviteId = nil;
                            NSString *tip = [NSString stringWithFormat:NSLocalizedStringFromSelf(@"INVITE_REJECT_HANGOUT"), self.liveRoom.userName];
                            [self showRoomTipView:tip isReject:YES];
                        } break;
                    }
                }
            });
        };
        [self.sessionManager sendRequest:request];
    }
}
*/
#pragma mark - IM请求
- (void)sendRoomToastRequestFromText:(NSString *)text {
    // 发送弹幕
    [self.imManager sendToast:self.liveRoom.roomId nickName:self.loginManager.loginItem.nickName msg:text];
}

- (void)sendRoomMsgRequestFromText:(NSString *)text {
    // 发送直播间消息
    [self.imManager sendLiveChat:self.liveRoom.roomId nickName:self.loginManager.loginItem.nickName msg:text at:nil];
}

#pragma mark - IM通知
- (void)onLogin:(LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errmsg item:(ImLoginReturnObject *_Nonnull)item {
    NSLog(@"LiveViewController::onLogin( [IM登陆, %@], errType : %d, errmsg : %@ )", (errType == LCC_ERR_SUCCESS) ? @"成功" : @"失败", errType, errmsg);

    if (errType == LCC_ERR_SUCCESS) {
        // 重新进入直播间
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.liveRoom.roomId.length) {
                // 获取Hangout邀请回复状态
                //[self getHangoutInviteStatu];

                [self.imManager enterRoom:self.liveRoom.roomId
                            finishHandler:^(BOOL success, LCC_ERR_TYPE errType, NSString *_Nonnull errMsg, ImLiveRoomObject *_Nonnull roomItem, ImAuthorityItemObject *_Nonnull priv) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.liveRoom.priv = priv;
                                    if (success) {
                                        NSLog(@"LiveViewController::onLogin( [IM登陆, 成功, 重新进入直播间], roomId : %@ isHasOneOnOneAuth :%d, isHasBookingAuth : %d)", self.liveRoom.roomId, priv.isHasOneOnOneAuth, priv.isHasBookingAuth);
                                        // 更新直播间信息
                                        [self.liveRoom reset];
                                        self.liveRoom.imLiveRoom = roomItem;

                                        // 重新推流
                                        [self stopPlay];
                                        [self play];

                                        if ([self.liveDelegate respondsToSelector:@selector(onReEnterRoom:)]) {
                                            [self.liveDelegate onReEnterRoom:self];
                                        }

                                        // 设置余额及返点信息管理器
                                        IMRebateItem *imRebateItem = [[IMRebateItem alloc] init];
                                        imRebateItem.curCredit = roomItem.rebateInfo.curCredit;
                                        imRebateItem.curTime = roomItem.rebateInfo.curTime;
                                        imRebateItem.preCredit = roomItem.rebateInfo.preCredit;
                                        imRebateItem.preTime = roomItem.rebateInfo.preTime;
                                        [self.creditRebateManager setReBateItem:imRebateItem];
                                        [self.creditRebateManager setCredit:roomItem.credit];

                                    } else {
                                        NSLog(@"LiveViewController::onLogin( [IM登陆, 成功, 但直播间已经关闭], roomId : %@ )", self.liveRoom.roomId);

                                        // 如果是正在邀请Hangout状态 跳转Hangout直播间
                                        if (self.isInviteHangout) {
                                            [self stopPlay];
                                            [self stopPublish];

                                            LSNavigationController *nvc = (LSNavigationController *)self.navigationController;
                                            [nvc forceToDismissAnimated:NO completion:nil];
                                            [[LiveModule module].moduleVC.navigationController popToViewController:[LiveModule module].moduleVC animated:NO];

                                            [[LiveUrlHandler shareInstance] handleOpenURL:self.pushUrl];
                                        } else {
                                            if (errType != LCC_ERR_CONNECTFAIL) {
                                                // 停止推拉流、结束直播
                                                [self stopLiveWithErrtype:LCC_ERR_NOT_FOUND_ROOM errMsg:NSLocalizedStringFromSelf(@"LIVE_NOT_ROOM")];
                                            }
                                        }
                                    }
                                });
                            }];
            } else {
                // 停止推拉流、结束直播
                [self stopLiveWithErrtype:LCC_ERR_NOT_FOUND_ROOM errMsg:NSLocalizedStringFromSelf(@"LIVE_NOT_ROOM")];
            }
        });
    }
}

- (void)onLogout:(LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errmsg {
    NSLog(@"LiveViewController::onLogout( [IM注销通知], errType : %d, errmsg : %@, playerReconnectTime : %lu, publisherReconnectTime : %lu )", errType, errmsg, (unsigned long)self.playerReconnectTime, (unsigned long)self.publisherReconnectTime);

    @synchronized(self) {
        // IM断开, 重置RTMP断开次数
        self.playerReconnectTime = 0;
        self.publisherReconnectTime = 0;
    }
}

- (void)onSendGift:(BOOL)success reqId:(SEQ_T)reqId errType:(LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errmsg credit:(double)credit rebateCredit:(double)rebateCredit {
    NSLog(@"LiveViewController::onSendGift( [发送直播间礼物消息], errmsg : %@, credit : %f, rebateCredit : %f )", errmsg, credit, rebateCredit);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            if (credit >= 0) {
                [self setUpRewardedCredit:rebateCredit];
                // 设置余额及返点信息管理器
                [self.creditRebateManager setCredit:credit];
            }
            [self.creditRebateManager updateRebateCredit:rebateCredit];

        } else if (errType == LCC_ERR_NO_CREDIT) {
            [self showAddCreditsView:NSLocalizedStringFromSelf(@"SENDTOSAT_ERR_ADD_CREDIT")];
        }
    });
}

- (void)onRecvSendGiftNotice:(NSString *_Nonnull)roomId fromId:(NSString *_Nonnull)fromId nickName:(NSString *_Nonnull)nickName giftId:(NSString *_Nonnull)giftId giftName:(NSString *_Nonnull)giftName giftNum:(int)giftNum multi_click:(BOOL)multi_click multi_click_start:(int)multi_click_start multi_click_end:(int)multi_click_end multi_click_id:(int)multi_click_id honorUrl:(NSString *_Nonnull)honorUrl {
    NSLog(@"LiveViewController::onRecvRoomGiftNotice( [接收礼物], roomId : %@, fromId : %@, nickName : %@, giftId : %@, giftName : %@, giftNum : %d, honorUrl : %@ )", roomId, fromId, nickName, giftId, giftName, giftNum, honorUrl);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            // 判断本地是否有该礼物
            BOOL bHave = ([self.giftDownloadManager getGiftItemWithId:giftId] != nil);
            if (bHave) {
                // 连击起始数
                int starNum = multi_click_start - 1;

                // 接收礼物消息item
                GiftItem *item = [GiftItem itemRoomId:roomId
                                               fromID:fromId
                                             nickName:nickName
                                               giftID:giftId
                                             giftName:giftName
                                              giftNum:giftNum
                                          multi_click:multi_click
                                              starNum:starNum
                                               endNum:multi_click_end
                                              clickID:multi_click_id];

                if (item.giftItem.infoItem.type == GIFTTYPE_COMMON) {
                    // 连击礼物
                    [self addCombo:item];

                } else {
                    // 礼物添加到队列
                    if (!self.bigGiftArray && self.viewIsAppear) {
                        self.bigGiftArray = [NSMutableArray array];
                    }
                    for (int i = 0; i < giftNum; i++) {
                        [self.bigGiftArray addObject:item.giftid];
                    }

                    // 防止动画播完view没移除
                    if (!self.giftAnimationView.isAnimating) {
                        [self.giftAnimationView removeFromSuperview];
                        self.giftAnimationView = nil;
                    }

                    if (!self.giftAnimationView) {
                        // 显示大礼物动画
                        if (self.bigGiftArray.count) {
                            [self starBigAnimationWithGiftID:self.bigGiftArray[0]];
                        }
                    }
                }

                if ([fromId isEqualToString:[LSLoginManager manager].loginItem.userId]) {
                    // 插入送礼文本消息
                    [self addGiftMessageNickName:nickName giftID:giftId giftNum:giftNum honorUrl:honorUrl fromId:fromId isHasTicket:self.liveRoom.httpLiveRoom.showInfo.ticketStatus == PROGRAMTICKETSTATUS_BUYED ? YES : NO];
                } else {
                    [self.roomUserInfoManager getUserInfo:fromId
                                            finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    // 插入送礼文本消息
                                                    [self addGiftMessageNickName:nickName giftID:giftId giftNum:giftNum honorUrl:honorUrl fromId:fromId isHasTicket:item.isHasTicket];
                                                });
                                            }];
                }
            } else {
                // 获取礼物详情
                // [self.giftDownloadManager requestListnotGiftID:giftId];
            }
        }
    });
}

- (void)onSendToast:(BOOL)success reqId:(SEQ_T)reqId errType:(LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errmsg credit:(double)credit rebateCredit:(double)rebateCredit {
    NSLog(@"LiveViewController::onSendToast( [发送直播间弹幕消息, %@], errmsg : %@, credit : %f, rebateCredit : %f )", (errType == LCC_ERR_SUCCESS) ? @"成功" : @"失败", errmsg, credit, rebateCredit);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            if (credit >= 0) {
                [self setUpRewardedCredit:rebateCredit];

                // 设置余额及返点信息管理器
                [self.creditRebateManager setCredit:credit];
            }
            [self.creditRebateManager updateRebateCredit:rebateCredit];

        } else if (errType == LCC_ERR_NO_CREDIT) {
            [self showAddCreditsView:NSLocalizedStringFromSelf(@"SENDTOSAT_ERR_ADD_CREDIT")];
        }
    });
}

- (void)onRecvSendToastNotice:(NSString *_Nonnull)roomId fromId:(NSString *_Nonnull)fromId nickName:(NSString *_Nonnull)nickName msg:(NSString *_Nonnull)msg honorUrl:(NSString *_Nonnull)honorUrl {
    NSLog(@"LiveViewController::onRecvSendToastNotice( [接收直播间弹幕通知], roomId : %@, fromId : %@, nickName : %@, msg : %@ honorUrl:%@)", roomId, fromId, nickName, msg, honorUrl);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            self.barrageView.hidden = NO;

            if ([fromId isEqualToString:[LSLoginManager manager].loginItem.userId]) {
                // 插入普通文本消息
                [self addChatMessageNickName:nickName text:msg honorUrl:honorUrl fromId:fromId isHasTicket:self.liveRoom.httpLiveRoom.showInfo.ticketStatus == PROGRAMTICKETSTATUS_BUYED ? YES : NO];
            } else {
                [self.roomUserInfoManager getUserInfo:fromId
                                        finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                // 插入普通文本消息
                                                [self addChatMessageNickName:nickName text:msg honorUrl:honorUrl fromId:fromId isHasTicket:item.isHasTicket];
                                            });
                                        }];
            }
            // 插入到弹幕
            BarrageModel *bgItem = [BarrageModel barrageModelForName:nickName message:msg urlWihtUserID:fromId];
            NSArray *items = [NSArray arrayWithObjects:bgItem, nil];
            [self.barrageView insertBarrages:items immediatelyShow:YES];
        }
    });
}

- (void)onRecvSendChatNotice:(NSString *_Nonnull)roomId level:(int)level fromId:(NSString *_Nonnull)fromId nickName:(NSString *_Nonnull)nickName msg:(NSString *_Nonnull)msg honorUrl:(NSString *_Nonnull)honorUrl {
    NSLog(@"LiveViewController::onRecvSendChatNotice( [接收直播间文本消息通知], roomId : %@, nickName : %@, msg : %@ )", roomId, nickName, msg);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.imLiveRoom.roomId]) {

            if ([fromId isEqualToString:[LSLoginManager manager].loginItem.userId]) {
                // 插入聊天消息到列表
                [self addChatMessageNickName:nickName text:msg honorUrl:honorUrl fromId:fromId isHasTicket:self.liveRoom.httpLiveRoom.showInfo.ticketStatus == PROGRAMTICKETSTATUS_BUYED ? YES : NO];
            } else {
                [self.roomUserInfoManager getUserInfo:fromId
                                        finishHandler:^(LSUserInfoModel *_Nonnull item) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                // 插入聊天消息到列表
                                                [self addChatMessageNickName:nickName text:msg honorUrl:honorUrl fromId:fromId isHasTicket:item.isHasTicket];
                                            });
                                        }];
            }
        }
    });
}

- (void)onRecvEnterRoomNotice:(NSString *_Nonnull)roomId userId:(NSString *_Nonnull)userId nickName:(NSString *_Nonnull)nickName photoUrl:(NSString *_Nonnull)photoUrl riderId:(NSString *_Nonnull)riderId riderName:(NSString *_Nonnull)riderName riderUrl:(NSString *_Nonnull)riderUrl fansNum:(int)fansNum honorImg:(NSString *_Nonnull)honorImg isHasTicket:(BOOL)isHasTicket {

    NSLog(@"LiveViewController::onRecvFansRoomIn( [接收观众进入直播间], roomId : %@, userId : %@, nickName : %@, photoUrl : %@ )", roomId, userId, nickName, photoUrl);

    dispatch_async(dispatch_get_main_queue(), ^{

        if ([roomId isEqualToString:self.liveRoom.imLiveRoom.roomId]) {
            if (![userId isEqualToString:self.loginManager.loginItem.userId]) {
                // 如果有座驾
                if (riderId.length) {
                    // 坐骑队列
                    AudienceModel *model = [[AudienceModel alloc] init];
                    model.userid = userId;
                    model.nickname = nickName;
                    model.photourl = photoUrl;
                    model.riderid = riderId;
                    model.ridername = riderName;
                    model.riderurl = riderUrl;
                    [self.audienArray addObject:model];
                    if (!self.isDriveShow) {
                        self.isDriveShow = YES;
                        [self.driveView audienceComeInLiveRoom:self.audienArray[0]];
                    }

                    // 用户座驾入场信息
                    [self addRiderJoinMessageNickName:nickName riderName:riderName honorUrl:honorImg fromId:userId isHasTicket:isHasTicket];

                } else { // 如果没座驾
                    // 插入入场消息到列表
                    MsgItem *msgItem = [self addJoinMessageNickName:nickName honorUrl:honorImg fromId:userId isHasTicket:isHasTicket];

                    // (插入/替换)到到消息列表
                    BOOL replace = NO;
                    if (self.msgArray.count > 0) {
                        MsgItem *lastItem = [self.msgArray lastObject];
                        if (lastItem.msgType == msgItem.msgType) {
                            // 同样是入场消息, 替换最后一条
                            replace = NO;
                        }
                    }
                    [self addMsg:msgItem replace:replace scrollToEnd:YES animated:YES];
                }
            }
        }
    });
}

- (void)onRecvRebateInfoNotice:(NSString *_Nonnull)roomId rebateInfo:(RebateInfoObject *_Nonnull)rebateInfo {
    NSLog(@"LiveViewController::onRecvRebateInfoNotice( [接收返点通知], roomId : %@ )", roomId);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            // 设置余额及返点信息管理器
            IMRebateItem *imRebateItem = [[IMRebateItem alloc] init];
            imRebateItem.curCredit = rebateInfo.curCredit;
            imRebateItem.curTime = rebateInfo.curTime;
            imRebateItem.preCredit = rebateInfo.preCredit;
            imRebateItem.preTime = rebateInfo.preTime;
            [self.creditRebateManager setReBateItem:imRebateItem];

            // 更新本地返点信息
            self.liveRoom.imLiveRoom.rebateInfo = rebateInfo;
            // 更新返点控件
            [self setUpRewardedCredit:rebateInfo.curCredit];

            // 插入返点更新文本
            NSString *msg = [NSString stringWithFormat:@"%@ %.2f credits", NSLocalizedStringFromSelf(@"Recv_Rebate"), rebateInfo.preCredit];
            NSAttributedString *atrStr = [[NSAttributedString alloc] initWithString:msg];
            [self addTips:atrStr];
        }
    });
}

- (void)onRecvLevelUpNotice:(int)level {
    NSLog(@"LiveViewController::onRecvLevelUpNotice( [接收观众等级升级通知], level : %d )", level);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 插入观众等级升级文本
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Recv_Level_Up", @"Recv_Level_Up"), level];
        NSAttributedString *atrStr = [[NSAttributedString alloc] initWithString:msg];
        [self addTips:atrStr];

        self.liveRoom.imLiveRoom.manLevel = level;
    });
}

- (void)onRecvLoveLevelUpNotice:(IMLoveLevelItemObject *_Nonnull)loveLevelItem {
    NSLog(@"LiveViewController::onRecvLoveLevelUpNotice( [接收观众亲密度升级通知], loveLevel : %d, anchorId: %@, anchorName: %@  )", loveLevelItem.loveLevel, loveLevelItem.anchorId, loveLevelItem.anchorName);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 插入观众等级升级文本
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Recv_Love_Up", @"Recv_Love_Up"), self.liveRoom.userName, loveLevelItem.loveLevel];
        NSAttributedString *atrStr = [[NSAttributedString alloc] initWithString:msg];
        [self addTips:atrStr];

        self.liveRoom.imLiveRoom.loveLevel = loveLevelItem.loveLevel;
    });
}

- (void)onRecvRoomKickoffNotice:(NSString *_Nonnull)roomId errType:(LCC_ERR_TYPE)errType errmsg:(NSString *_Nonnull)errmsg credit:(double)credit priv:(ImAuthorityItemObject *_Nonnull)priv {
    NSLog(@"LiveViewController::onRecvRoomKickoffNotice( [接收踢出直播间通知], roomId : %@ credit:%f, isHasOneOnOneAuth :%d, isHasBookingAuth : %d", roomId, credit, priv.isHasOneOnOneAuth, priv.isHasBookingAuth);

    dispatch_async(dispatch_get_main_queue(), ^{

        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            self.liveRoom.priv = priv;
            // 发送退出直播间
            [self.imManager leaveRoom:self.liveRoom];

            // 设置余额及返点信息管理器
            if (credit >= 0) {
                [self.creditRebateManager setCredit:credit];
            }

            LCC_ERR_TYPE type;
            if (errType == LCC_ERR_NO_CREDIT || errType == LCC_ERR_COUPON_FAIL) {
                type = errType;
            } else {
                type = LCC_ERR_ROOM_LIVEKICKOFF;
            }
            // 停止推拉流、显示结束直播间界面
            [self stopLiveWithErrtype:type errMsg:errmsg];
        }
    });
}

- (void)onRecvLackOfCreditNotice:(NSString *_Nonnull)roomId msg:(NSString *_Nonnull)msg credit:(double)credit errType:(LCC_ERR_TYPE)errType {
    NSLog(@"LiveViewController::onRecvLackOfCreditNotice( [接收充值通知], roomId : %@ credit:%f errType:%d", roomId, credit, errType);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置余额及返点信息管理器
        if (credit >= 0) {
            [self.creditRebateManager setCredit:credit];
        }

        [self showAddCreditsView:NSLocalizedStringFromSelf(@"WATCHING_WILL_NO_MONEY")];
    });
}

- (void)onRecvCreditNotice:(NSString *_Nonnull)roomId credit:(double)credit {
    NSLog(@"LiveViewController::onRecvCreditNotice( [接收定时扣费通知], roomId : %@, credit : %f ）", roomId, credit);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置余额及返点信息管理器
        if (credit >= 0) {
            [self.creditRebateManager setCredit:credit];
        }
    });
}

- (void)onRecvSendTalentNotice:(ImTalentReplyObject *)item {
    NSLog(@"LiveViewController::onRecvSendTalentNotice( [接收直播间才艺点播回复通知] )");

    dispatch_async(dispatch_get_main_queue(), ^{
        if (item.status == TALENTSTATUS_AGREE && item.credit >= 0) {
            // 更新返点控件
            [self setUpRewardedCredit:item.rebateCredit];

            [self starBigAnimationWithGiftID:item.giftId];
        }
    });
}

- (void)onRecvTalentPromptNotice:(NSString *)roomId introduction:(NSString *)introduction {
    NSLog(@"LiveViewController::onRecvTalentPromptNotice( [接收直播间才艺点播提示公告通知] :%@)", introduction);

//    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([self.liveRoom.roomId isEqualToString:roomId]) {
//            MsgItem *msgItem = [[MsgItem alloc] init];
//            msgItem.msgType = MsgType_Talent;
//            msgItem.honorUrl = self.liveRoom.photoUrl;
//            msgItem.toName = self.liveRoom.userName;
//            msgItem.text = introduction;
//            [self addMsg:msgItem replace:NO scrollToEnd:YES animated:YES];
//        }
//    });
}

- (void)onRecvSendSystemNotice:(NSString *_Nonnull)roomId msg:(NSString *_Nonnull)msg link:(NSString *_Nonnull)link type:(IMSystemType)type {
    NSLog(@"LiveViewController::onRecvSendSystemNotice( [接收直播间公告消息], roomId : %@, msg : %@, link: %@ type:%d)", roomId, msg, link, type);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            MsgItem *msgItem = [[MsgItem alloc] init];
            if (type == IMSYSTEMTYPE_COMMON) {
                msgItem.text = msg;
                if ([link isEqualToString:@""] || link == nil) {
                    msgItem.msgType = MsgType_Announce;
                } else {
                    msgItem.msgType = MsgType_Link;
                    msgItem.linkStr = link;
                }

            } else {
                if (self.dialogView) {
                    [self.dialogView removeFromSuperview];
                }
                self.dialogView = [DialogWarning dialogWarning];
                self.dialogView.tipsLabel.text = msg;
                [self.dialogView showDialogWarning:self.view actionBlock:nil];

                msgItem.text = msg;
                msgItem.msgType = MsgType_Warning;
            }
            NSMutableAttributedString *attributeString = [self.msgManager presentTheRoomStyleItem:self.roomStyleItem msgItem:msgItem];
            msgItem.attText = attributeString;
            [self addMsg:msgItem replace:NO scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onRecvLeavingPublicRoomNotice:(NSString *_Nonnull)roomId leftSeconds:(int)leftSeconds err:(LCC_ERR_TYPE)err errMsg:(NSString *_Nonnull)errMsg priv:(ImAuthorityItemObject *_Nonnull)priv {
    NSLog(@"LiveViewController::onRecvLeavingPublicRoomNotice( [接收关闭直播间倒数通知], roomId : %@ , leftSeconds : %d ,isHasOneOnOneAuth : %d ,isHasOneOnOneAuth : %d)", roomId, leftSeconds, priv.isHasOneOnOneAuth, priv.isHasBookingAuth);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            self.liveRoom.priv = priv;
            // 开启关闭倒计时定时器
            //            [self hiddenStartOneView];
            self.countdownView.hidden = NO;
            [self.view bringSubviewToFront:self.countdownLabel];

            self.timeCount = leftSeconds;
            [self.timer startTimer:nil
                      timeInterval:1.0 * NSEC_PER_SEC
                           starNow:YES
                            action:^{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self changeTimeLabel];
                                });
                            }];
        }
    });
}

- (void)onRecvRoomCloseNotice:(NSString *_Nonnull)roomId errType:(LCC_ERR_TYPE)errType errMsg:(NSString *_Nonnull)errmsg priv:(ImAuthorityItemObject *_Nonnull)priv {
    NSLog(@"LiveViewController::onRecvRoomCloseNotice( [接收关闭直播间回调], roomId : %@, errType : %d, errMsg : %@, isHasOneOnOneAuth : %d, isHasOneOnOneAuth: %d )", roomId, errType, errmsg, priv.isHasOneOnOneAuth, priv.isHasBookingAuth);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.liveRoom.roomId) {
            if ([self.liveRoom.roomId isEqualToString:roomId]) {
                self.liveRoom.priv = priv;
                // 是否邀请Hangout
                if (self.isInviteHangout) {
                    [self stopPlay];
                    [self stopPublish];

                    LSNavigationController *nvc = (LSNavigationController *)self.navigationController;
                    [nvc forceToDismissAnimated:NO completion:nil];
                    [[LiveModule module].moduleVC.navigationController popToViewController:[LiveModule module].moduleVC animated:NO];

                    [[LiveUrlHandler shareInstance] handleOpenURL:self.pushUrl];

                } else {
                    // 停止流、显示结束直播页
                    [self stopLiveWithErrtype:errType errMsg:errmsg];
                }
            }
        }
    });
}

- (void)onRecvChangeVideoUrl:(NSString *_Nonnull)roomId isAnchor:(BOOL)isAnchor playUrl:(NSArray<NSString *> *_Nonnull)playUrl userId:(NSString *_Nonnull)userId {
    NSLog(@"LiveViewController::onRecvChangeVideoUrl( [接收观众／主播切换视频流通知], roomId : %@, playUrl : %@ userId : %@ )", roomId, playUrl, userId);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([roomId isEqualToString:self.liveRoom.roomId]) {
            // 更新流地址
            [self.liveRoom reset];
            self.liveRoom.playUrlArray = [playUrl copy];

            [self stopPlay];
            [self play];
        }
    });
}

- (void)onRecvRecommendHangoutNotice:(IMRecommendHangoutItemObject *)item {
    NSLog(@"LiveViewController::onRecvRecommendHangoutNotice( [接收主播推荐好友通知] roomId : %@, anchorID : %@,"
           "nickName : %@, recommendId : %@, photourl : %@ )",
          item.roomId, item.anchorId, item.nickName, item.recommendId, item.photoUrl);

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([item.roomId isEqualToString:self.liveRoom.roomId]) {

            NSAttributedString *atrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedStringFromSelf(@"WOULD_LIKE_TO_HANGOUT"), item.nickName, item.friendNickName]];
            [self addTips:atrStr];

            MsgItem *msgItem = [[MsgItem alloc] init];
            msgItem.msgType = MsgType_Recommend;
            msgItem.sendName = item.nickName;
            msgItem.recommendItem = item;
            [self addMsg:msgItem replace:NO scrollToEnd:YES animated:YES];
        }
    });
}

- (void)onRecvDealInviteHangoutNotice:(IMRecvDealInviteItemObject *)item {
    NSLog(@"LiveViewController::onRecvDealInviteHangoutNotice( [接收主播回复观众多人互动邀请通知] invteId : %@, roomId : %@,"
           "anchorId : %@, type : %d, anchorId : %@ )",
          item.inviteId, item.roomId, item.anchorId, item.type, item.anchorId);
/*
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (item.type) {
            case IMREPLYINVITETYPE_AGREE: {
                self.isInvitingHangout = YES;
                self.isInviteHangout = YES;
                [self showRoomTipView:NSLocalizedStringFromSelf(@"INVITE_SUCCESS_HANGOUT") isReject:NO];
                // 拼接push跳转多人互动url
                // 是否是推荐邀请
                if (self.isRecommend) {
                    self.pushUrl = [[LiveUrlHandler shareInstance] createUrlToHangoutByRoomId:item.roomId anchorId:self.hangoutAnchorId anchorName:self.hangoutAnchorName hangoutAnchorId:self.liveRoom.userId hangoutAnchorName:self.liveRoom.userName];
                } else {
                    self.pushUrl = [[LiveUrlHandler shareInstance] createUrlToHangoutByRoomId:item.roomId anchorId:self.hangoutAnchorId anchorName:self.hangoutAnchorName hangoutAnchorId:@"" hangoutAnchorName:@""];
                }

            } break;

            case IMREPLYINVITETYPE_NOCREDIT: {
                self.isInvitingHangout = NO;
                [self showAddCreditsView:NSLocalizedString(@"INVITE_HANGOUT_ADDCREDIT", nil)];
            } break;

            default: {
                self.isInvitingHangout = NO;
                self.isRecommend = NO;
                self.isInviteHangout = NO;
                self.hangoutInviteId = nil;
                NSString *tip = [NSString stringWithFormat:NSLocalizedStringFromSelf(@"INVITE_REJECT_HANGOUT"), item.nickName];
                [self showRoomTipView:tip isReject:YES];
            } break;
        }
    });
 */
}

#pragma mark - 倒数关闭直播间
- (void)changeTimeLabel {
    self.countdownLabel.text = [NSString stringWithFormat:@"%lds", (long)self.timeCount];
    self.timeCount -= 1;

    if (self.timeCount < 0) {
        // 关闭
        [self.timer stopTimer];
        // 关闭之后，重设计数
        self.timeCount = TIMECOUNT;
    }
}

#pragma mark - 倒数控制
- (void)setupPreviewView {
    // 初始化预览界面
    self.stopVideoBtn.hidden = YES;
    self.muteBtn.hidden = YES;

    [self.muteBtn setImage:[UIImage imageNamed:@"Live_Publish_Btn_Mute_Selected"] forState:UIControlStateSelected];
}

- (void)videoBtnCountDown {
    @synchronized(self) {
        self.videoBtnLeftSecond--;
        if (self.videoBtnLeftSecond == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 隐藏视频静音和推送按钮
                self.stopVideoBtn.hidden = YES;
                self.muteBtn.hidden = YES;
            });
        }
    }
}

- (void)startVideoBtnTimer {
    NSLog(@"LiveViewController::startVideoBtnTimer()");
    WeakObject(self, weakSelf);
    [self.videoBtnTimer startTimer:nil
                      timeInterval:1.0 * NSEC_PER_SEC
                           starNow:YES
                            action:^{
                                [weakSelf videoBtnCountDown];
                            }];
}

- (void)stopVideoBtnTimer {
    NSLog(@"LiveViewController::stopVideoBtnTimer()");

    [self.videoBtnTimer stopTimer];
}

#pragma mark - 后台处理
- (void)willEnterBackground:(NSNotification *)notification {
    if (_isBackground == NO) {
        _isBackground = YES;

        [LiveGobalManager manager].enterRoomBackgroundTime = [NSDate date];
    }
}

- (void)willEnterForeground:(NSNotification *)notification {
    if (_isBackground == YES) {
        _isBackground = NO;

        if (self.isTimeOut) {
            if (self.liveRoom) {
                NSLog(@"LiveViewController::willEnterForeground ( [接收后台关闭直播间]  IsTimeOut : %@ )", (self.isTimeOut == YES) ? @"Yes" : @"No");
                // 弹出直播间关闭界面
                [self showLiveFinshViewWithErrtype:LCC_ERR_BACKGROUND_TIMEOUT errMsg:NSLocalizedStringFromErrorCode(@"LIVE_ROOM_BACKGROUND_TIMEOUT")];
            }
        }
    }
}

#pragma mark - LiveGobalManagerDelegate
- (void)enterBackgroundTimeOut:(NSDate *_Nullable)time {
    self.isTimeOut = YES;

    if (self.liveRoom.roomId.length > 0) {
        // 发送IM退出直播间命令
        [[LSImManager manager] leaveRoom:self.liveRoom];
    }

    if (self.player) {
        // 停止播放器
        [self.player stop];
    }
    if (self.publisher) {
        // 停止推流器
        [self.publisher stop];
    }
}

// 显示直播结束界面
- (void)showLiveFinshViewWithErrtype:(LCC_ERR_TYPE)errType errMsg:(NSString *)errMsg {
    if ([self.liveDelegate respondsToSelector:@selector(liveFinshViewIsShow:)]) {
        [self.liveDelegate liveFinshViewIsShow:self];
    }

    if (self.liveRoom.superView) {
        LiveFinshViewController *finshController = [[LiveFinshViewController alloc] initWithNibName:nil bundle:nil];
        finshController.liveRoom = self.liveRoom;
        finshController.errType = errType;
        finshController.errMsg = errMsg;

        [self.liveRoom.superController addChildViewController:finshController];
        [self.liveRoom.superView addSubview:finshController.view];
        [finshController.view bringSubviewToFront:self.liveRoom.superView];
        [finshController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.liveRoom.superView);
        }];
    }

    if (self.liveRoom.roomId.length > 0) {
        // 发送退出直播间
        NSLog(@"LiveViewController::dealloc( [发送退出直播间], roomId : %@ )", self.liveRoom.roomId);
        [self.imManager leaveRoom:self.liveRoom];
    }
    // 清空直播间信息
    self.liveRoom = nil;
}

// 直播结束停止推拉流并显示结束页
- (void)stopLiveWithErrtype:(LCC_ERR_TYPE)errType errMsg:(NSString *)errMsg {
    if (self.liveRoom) {
        [self.timer stopTimer];
        // 停止流
        [self stopPlay];
        [self stopPublish];

        // 弹出直播间关闭界面
        [self showLiveFinshViewWithErrtype:errType errMsg:errMsg];
    }
}

#pragma mark - 字符串拼接
- (void)setUpRewardedCredit:(double)rebateCredit {
    NSMutableAttributedString *attribuStr = [[NSMutableAttributedString alloc] init];
    [attribuStr appendAttributedString:[self parseMessage:NSLocalizedStringFromSelf(@"Rebate_Tip") font:[UIFont systemFontOfSize:10] color:[UIColor whiteColor]]];
    [attribuStr appendAttributedString:[self parseMessage:[NSString stringWithFormat:@"%.2f", rebateCredit] font:[UIFont systemFontOfSize:12] color:COLOR_WITH_16BAND_RGB(0xffd205)]];
    // 设置标题
    self.rewardedBtn.titleLabel.attributedText = attribuStr;
    [self.rewardedBtn setAttributedTitle:attribuStr forState:UIControlStateNormal];
}


- (NSAttributedString *)parseMessage:(NSString *)text font:(UIFont *)font color:(UIColor *)textColor {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributeString addAttributes:@{
                                     NSFontAttributeName : font,
                                     NSForegroundColorAttributeName:textColor
                                     }
                             range:NSMakeRange(0, attributeString.length)
     ];
    return attributeString;
}

#pragma mark - 调试
- (BOOL)handleDebugCmd:(NSString *)text {
    BOOL bFlag = NO;
    
    // 录制命令
    if( [text isEqualToString:RECORD_START] ) {
        NSLog(@"LiveViewController::handleDebugCmd( [record start] ）");
        [LiveModule module].debug = YES;
        [self stopPlay];
        [self play];
        bFlag = YES;
        
    } else if( [text isEqualToString:RECORD_STOP] ) {
        NSLog(@"LiveViewController::handleDebugCmd( [record stop] ）");
        [LiveModule module].debug = NO;
        [self stopPlay];
        [self play];
        bFlag = YES;
    }
    
    // 显示Debug信息命令
    if( [text isEqualToString:DEBUG_START] ) {
        NSLog(@"LiveViewController::handleDebugCmd( [debug show] ）");
        self.debugLabel.hidden = NO;
        bFlag = YES;
        
    } else if( [text isEqualToString:DEBUG_STOP] ) {
        NSLog(@"LiveViewController::handleDebugCmd( [debug hide] ）");
        self.debugLabel.hidden = YES;
        bFlag = YES;
    }
    
    return bFlag;
}

- (void)debugInfo {
    NSString *debugString = [NSString stringWithFormat:@"play: %@\n\npublish: %@\n", self.playUrl, self.publishUrl];
    self.debugLabel.text = debugString;
    [self.debugLabel sizeToFit];
}

#pragma mark - 测试
- (void)test {
    self.giftItemId = 1;
    self.msgId = 1;
    
//    self.testTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(testMethod) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.testTimer forMode:NSRunLoopCommonModes];
//
//    self.testTimer2 = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(testMethod2) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.testTimer2 forMode:NSRunLoopCommonModes];
//
//    self.testTimer3 = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(testMethod3) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.testTimer3 forMode:NSRunLoopCommonModes];
//
//    self.testTimer4 = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(testMethod4) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.testTimer4 forMode:NSRunLoopCommonModes];
}

- (void)stopTest {
    [self.testTimer invalidate];
    self.testTimer = nil;
    
    [self.testTimer2 invalidate];
    self.testTimer2 = nil;
    
    [self.testTimer3 invalidate];
    self.testTimer3 = nil;
    
    [self.testTimer4 invalidate];
    self.testTimer4 = nil;
}

- (void)testMethod {
    GiftItem* item = [[GiftItem alloc] init];
    item.fromid = self.loginManager.loginItem.userId;
    item.nickname = @"Max";
    item.giftid = [NSString stringWithFormat:@"%ld", (long)self.giftItemId++];
    item.multi_click_start = 0;
    item.multi_click_end = 10;
    
    [self addCombo:item];
}

- (void)testMethod2 {
    NSString* msg = [NSString stringWithFormat:@"msg%ld", (long)self.msgId++];
    [self sendMsg:msg isLounder:YES];
}

- (void)testMethod3 {
    NSString* msg = [NSString stringWithFormat:@"msg%ld", (long)self.msgId++];
//    [self sendMsg:msg isLounder:NO];
    [self addChatMessageNickName:@"randy" text:msg honorUrl:nil fromId:nil isHasTicket:NO];
}

- (void)testMethod4 {
}

@end
