//
//  DataSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataSocket : NSObject

/// PCM 数据回调
@property (nonatomic , copy) void (^onPcmDataCallback)(NSDictionary *descDic, NSData *pcmData);
/// 图片数据回调
@property (nonatomic , copy) void (^onPicDataCallback)(NSDictionary *descDic, NSData *picData);
/// 歌词数据回调
@property (nonatomic , copy) void (^onLyricDataCallback)(NSDictionary *descDic, NSData *lyricData);

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
