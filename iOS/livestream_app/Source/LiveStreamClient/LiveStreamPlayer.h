//
//  LiveStreamPlayer.h
//  livestream
//
//  Created by Max on 2017/4/14.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RtmpPlayerOC.h"

#import "GPUImage.h"

@class LiveStreamPlayer;
@protocol LiveStreamPlayerDelegate <NSObject>
@optional
- (NSString * _Nullable)playerShouldChangeUrl:(LiveStreamPlayer * _Nonnull)player;

@end

@interface LiveStreamPlayer : NSObject
/**
 显示界面
 */
@property (strong, nonatomic) GPUImageView* _Nullable playView;

/**
 委托
 */
@property (weak) id<LiveStreamPlayerDelegate> _Nullable delegate;

/**
 当前播放URL
 */
@property (strong, readonly) NSString * _Nonnull url;

/**
 *  获取实例
 *
 *  @return 实例
 */
+ (instancetype _Nonnull)instance;

/**
 播放流连接
 
 @param url 连接
 @param recordFilePath 录制路径
 @param recordH264FilePath H264录制路径
 @param recordAACFilePath AAC录制路径
 @return 成功失败
 */
- (BOOL)playUrl:(NSString * _Nonnull)url recordFilePath:(NSString * _Nullable)recordFilePath recordH264FilePath:(NSString * _Nullable)recordH264FilePath recordAACFilePath:(NSString * _Nullable)recordAACFilePath;

/**
 停止
 */
- (void)stop;

@end
