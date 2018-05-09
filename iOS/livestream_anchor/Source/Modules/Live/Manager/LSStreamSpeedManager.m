//
//  LSStreamSpeedManager.m
//  livestream
//
//  Created by randy on 2017/11/1.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "LSStreamSpeedManager.h"
#import "LSLoginManager.h"
#import "LSConfigManager.h"
#import "LSAnchorRequestManager.h"

@interface LSStreamSpeedManager () <LoginManagerDelegate, NSURLSessionDelegate>

@property (nonatomic, strong) LSLoginManager *loginManager;
@property (strong, nonatomic) LSSessionRequestManager *sessionManager;

@end

@implementation LSStreamSpeedManager

- (instancetype)init {
    if (self = [super init]) {
        self.loginManager = [LSLoginManager manager];
        [self.loginManager addDelegate:self];

        self.sessionManager = [LSSessionRequestManager manager];
    }
    return self;
}

- (void)manager:(LSLoginManager *)manager onLogin:(BOOL)success loginItem:(ZBLSLoginItemObject *)loginItem errnum:(ZBHTTP_LCC_ERR_TYPE)errnum errmsg:(NSString *)errmsg {
    if (success) {
        NSArray *svrList = [LSConfigManager manager].item.svrList;
        for (ZBLSSvrItemObject *object in svrList) {
            NSLog(@"LSStreamSpeedManager::onLogin( 服务器(%@), 开始测速, url : %@ )", object.svrId, object.tUrl);
            
            NSURLSession *session = [NSURLSession sharedSession];
            // 设置超时
            session.configuration.timeoutIntervalForRequest = 10;
            NSDate *startDate = [NSDate date];
            NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:object.tUrl]
                                                completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                                    NSDate *date = [NSDate date];
                                                    NSTimeInterval time = [date timeIntervalSince1970] - [startDate timeIntervalSince1970];
                                                    double timeMS = error ? -1 : (time * 1000);
                                                    
                                                    NSLog(@"LSStreamSpeedManager::onLogin( 服务器(%@), 测速%@用时 : %f 毫秒, url : %@ )", object.svrId, BOOL2SUCCESS(!error), timeMS, object.tUrl);
                                                    
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        // 发送测速结果
                                                        [self requestSpeedResult:timeMS svrID:object.svrId];
                                                    });
                                                }];
            [task resume];
        }
    }
}

- (void)requestSpeedResult:(int)res svrID:(NSString *)svrID {
    [[LSAnchorRequestManager manager] anchorServerSpeed:svrID res:res finishHandler:^(BOOL success, ZBHTTP_LCC_ERR_TYPE errnum, NSString * _Nonnull errmsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"LSStreamSpeedManager::requestSpeedResult:( [流媒体服务器测速] success : %@ )", (success == YES) ? @"成功" : @"失败");
        });
    }];
}

@end
