//
//  TestViewController.m
//  QPlayAutoDemo
//
//  Created by 吴文豪 on 2020/8/27.
//  Copyright © 2020 腾讯音乐. All rights reserved.
//

#import "TestViewController.h"
#import "ViewController.h"
#import "QPlayAutoSDK.h"
#import "QPlayAutoManager.h"
#import "MPcmPlaYer.h"
#import <AVFoundation/AVFoundation.h>

@interface TestViewController ()<QPlayAutoSDKDelegate>

@property (nonatomic , strong) UIButton *connectBtn;

@property (nonatomic , strong) UIButton *requestPCMBtn;
@property (nonatomic , strong) UIButton *resumeBtn;
@property (nonatomic , strong) UIButton *pauseBtn;
@property (nonatomic , strong) UIButton *stopBtn;
@property (nonatomic , strong) UIButton *playBtn;

@property (strong,nonatomic) MPcmPlaYer *aqPlayer;

@property (nonatomic , strong) NSOperationQueue *opQueue;

@end

#define kMediaId @"511571|1"
// 97773|1 晴天
// 680279|1 烟花易冷
// 511571|1 I lay my love on you - westlife
// 13410|1 三十年
// 13411|1 三十年

@implementation TestViewController
{
    NSInteger _packageIndex;
    
    NSData *_pcmData;
    
    BOOL _isPlaying;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    
    // register app
    QPlayAutoAppInfo *appInfo = [[QPlayAutoAppInfo alloc] init];
    appInfo.deviceId = @"AC:88:FD:75:32:4B";
    appInfo.scheme = @"qplayautodemo://";
    appInfo.brand = @"Mosi";
    appInfo.name = @"QPlayAutoDemo";
    appInfo.bundleId = @"com.tencent.QQMusicOpenSDKDemo123";
    appInfo.appId = App_ID;
    appInfo.secretKey = App_PrivateKey;
    // 1: 车机 | 2: 电表 | 3: APP
    appInfo.deviceType = 1;
    [QPlayAutoSDK registerApp:appInfo delegate:self];

    self.connectBtn;
    self.playBtn;
    self.pauseBtn;
    self.resumeBtn;
    self.stopBtn;
    
    self.opQueue = [[NSOperationQueue alloc]init];
    self.opQueue.maxConcurrentOperationCount = 1;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(notificationAction:)
        name:kNotificationShouldFillAudioQueueBuffer
      object:nil];
}

- (UIButton *)connectBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"未连接" forState:UIControlStateNormal];
    [btn setTitle:@"已连接" forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
    btn.frame = CGRectMake(50, 50, 100, 50);

    return btn;
}

- (void) connect:(UIButton *)btn {

    if ([QPlayAutoSDK isStarted]) {
        [QPlayAutoSDK stop];
    }
    else {
        [QPlayAutoSDK activeQQMusicApp];
        [QPlayAutoSDK start];
    }

}

- (UIButton *)playBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Play" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.frame = CGRectMake(50, 250, 100, 50);
    return btn;
}

- (void) playAction:(UIButton *)sender {
    // PCM
    self->_packageIndex = 0;
    
    __weak typeof(self) weakSelf = self;
    [[QPlayAutoManager sharedInstance] requestMediaInfo:kMediaId callback:^(BOOL success, NSDictionary *dict) {
        if (success) {
            
            __strong typeof(weakSelf) self = weakSelf;
            
            [self.opQueue cancelAllOperations];
            // 重新初始化 tsQueue
            self.opQueue = [[NSOperationQueue alloc]init];
            self.opQueue.maxConcurrentOperationCount = 1;
            
            self.aqPlayer = [[MPcmPlaYer alloc]init];
            [self.aqPlayer play];
            [self.aqPlayer prepareToPlay];
        }
    }];
}


- (UIButton *)pauseBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Pause" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pauseAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
    btn.frame = CGRectMake(50, 350, 100, 50);

    return btn;
}

- (void) pauseAction:(UIButton *)sender {
    [self.aqPlayer pause];
}

- (UIButton *)resumeBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Resume" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(resumeAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
    btn.frame = CGRectMake(50, 450, 100, 50);

    return btn;
}

- (void) resumeAction:(UIButton *)sender {
    [self.aqPlayer resume];
}

- (UIButton *)stopBtn {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Stop" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(stopAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
    btn.frame = CGRectMake(50, 550, 100, 50);

    return btn;
}

- (void) stopAction:(UIButton *)sender {
    [self.aqPlayer stop];
}

- (void) notificationAction:(NSNotification *)noti {
    
    if (![self.aqPlayer isEqual:noti.userInfo[@"player"]]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"*-*开始获取 index: %d", (int)self->_packageIndex);
        
        __block BOOL finish = NO;
        [[QPlayAutoManager sharedInstance] requestPcmData:kMediaId packageIndex:self->_packageIndex callback:^(BOOL success, NSDictionary *dict) {
            finish = YES;
            NSLog(@"*-*结束获取 index: %d", (int)(self->_packageIndex - 1));
            dispatch_async(dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT), ^{
                NSData *pcmData = dict[@"pcmData"];
                
                if (pcmData.length < 1048576) {
                    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"qiangqiang.pcm"];
                    [pcmData writeToFile:path atomically:YES];
                }
                
                __strong typeof(weakSelf) self = weakSelf;
                AudioBuffer buffer;
                short *samples = (short *)pcmData.bytes;
                buffer.mData = samples;
                buffer.mDataByteSize = (uint32_t)pcmData.length;
                buffer.mNumberChannels = 2;
                
                [self.aqPlayer enqueueAudioBuffer:buffer];
            });
        }];
        self->_packageIndex ++;
        while (!finish) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }];
    
    [self.opQueue addOperation:op];
}

//- (void) requestPCM:(UIButton *)btn {
//
//    // PIC
////    [QPlayAutoManager sharedInstance].didReceivePICDataCallback = ^(NSDictionary * _Nonnull descDic, NSData * _Nonnull picData) {
////        UIImage *album = [UIImage imageWithData:picData];
////        NSLog(@"");
////    };
////    [[QPlayAutoManager sharedInstance] requestAlbumImage:kMediaId pageIndex:self->_packageIndex];
//
//    // Lyric
////    [QPlayAutoManager sharedInstance].didReceiveLyricDataCallback = ^(NSDictionary * _Nonnull descDic, NSData * _Nonnull lyricData) {
////        NSString *lyric = [[NSString alloc]initWithData:lyricData encoding:NSUTF8StringEncoding];
////        NSLog(@"lyric:\n%@",lyric);
////    };
////    [[QPlayAutoManager sharedInstance] requestLyric:kMediaId lyricType:1 pageIndex:self->_packageIndex];
//
//}

#pragma mark - QPlayAutoSDKDelegate
//连接状态变化回调
- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (newState) {
            case QPlayAutoConnectState_Disconnect:
                self.connectBtn.selected = NO;
                NSLog(@"****************** onQPlayAutoConnectStateChanged: Disconnect");
                break;
            case QPlayAutoConnectState_Connected:
                self.connectBtn.selected = YES;
                NSLog(@"****************** onQPlayAutoConnectStateChanged: Connect");
                break;
            default:
                break;
        }
    }) ;
}

//变化状态变化回调
- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem*)song position:(NSInteger)position {
    NSLog(@"****************** onQPlayAutoPlayStateChanged: %d", playState);
}

//歌曲收藏状态变化
- (void)onSongFavoriteStateChange:(NSString*)songID isFavorite:(BOOL)isFavorite {

}

//播放状态事件变化
- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode {
    NSLog(@"****************** onPlayModeChange: %d", playMode);
}

//定时关闭事件
- (void)onPlayPausedByTimeoff {
    NSLog(@"****************** onPlayPausedByTimeoff");
}

@end
