

//
//  AppDelegate.m
//  RtmpClientTest
//
//  Created by Max on 2017/4/1.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "AppDelegate.h"

#include <common/KLog.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

//    NSURLSession *session = [NSURLSession sharedSession];
//    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http:www.baidu.com"]];
//    NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
//        if ( !error ) {
//            NSLog(@"response:%@", response);
//        } else {
//            NSLog(@"error:%@", error);
//        }
//    }];
//    [task resume];

    KLog::SetLogFileEnable(NO);
    KLog::SetLogLevel(KLog::LOG_MSG);

    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//- (BOOL)canBecomeFirstResponder {
//    return YES;
//}
//
//- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
//    NSLog(@"remoteControlReceivedWithEvent(), %@", event);
//
//    switch (event.subtype) {
//        case UIEventSubtypeRemoteControlPlay:
//            //play
//            break;
//        case UIEventSubtypeRemoteControlPause:
//            //pause
//            break;
//        case UIEventSubtypeRemoteControlStop:
//            //stop
//            break;
//        default:
//            break;
//    }
//}

@end
