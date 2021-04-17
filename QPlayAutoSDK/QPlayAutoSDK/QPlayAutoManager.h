//
//  QPlayAutoManager.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QPlayAutoSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface QPlayAutoManager : NSObject


@property (nonatomic, assign) BOOL isStarted;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, strong) QPlayAutoAppInfo *appInfo;

+ (instancetype)sharedInstance;

- (void)start:(QPlayAutoAppInfo*)appInfo;

- (void)stop;

- (NSInteger)requestItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                    appId:(nullable NSString*)appId         //访问用户歌单需要
                   openId:(nullable NSString*)openId        //访问用户歌单需要
                openToken:(nullable NSString*)openToken     //访问用户歌单需要
                calllback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestQueryFavoriteState:(NSString*)songId calllback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetFavoriteState:(BOOL)isFav songId:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestGetPlayMode:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestGetCurrentSong:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSetAssenceMode:(QPlayAutoAssenceMode)assenceMode callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block;

- (void)requestMediaInfo:(NSString*)songId;

- (void)requestPlaySongList:(NSArray<NSString*>*)songIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block;

- (void)requestPlaySongMidList:(NSArray<NSString*>*)songMIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayNext:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayPrev:(QPlayAutoRequestFinishBlock)block;

- (void)reqeustPlayPause;

- (void)reqeustPlayResume:(QPlayAutoRequestFinishBlock)block;

- (void)requestSeek:(NSInteger)position;

- (NSInteger)requestOpenIDAuthWithAppId:(NSString*)appId
                            packageName:(NSString*)packageName
                          encryptString:(NSString*)encryptString
                               callback:(QPlayAutoRequestFinishBlock)block;

- (NSInteger)requestSearch:(NSString*)keyword firstPage:(BOOL)firstPage callback:(QPlayAutoRequestFinishBlock)block;

// wuwenhao
/// 获取媒体信息（开启 QQ 音乐音频数据解析）
/// @param songId 歌曲 id
/// @param block 回调
- (void) requestMediaInfo:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block;
/// 获取 PCM 数据
/// @param songId 歌曲 id
/// @param packageIndex 子包 index
/// @param block 回调
- (void) requestPcmData:(NSString*)songId packageIndex:(NSUInteger)packageIndex callback:(QPlayAutoRequestFinishBlock)block;
/// 查询歌曲图片
/// @param songId 歌曲 id
/// @param pageIndex 子页 index
- (void) requestAlbumImage:(NSString*)songId pageIndex:(NSUInteger)pageIndex callback:(QPlayAutoRequestFinishBlock)block;
/// 查询歌词
/// @param songId 歌曲 id
/// @param lyricType 0: QRC | 1: LRC
/// @param pageIndex 子页 index
- (void) requestLyric:(NSString*)songId lyricType:(NSInteger)lyricType pageIndex:(NSUInteger)pageIndex callback:(QPlayAutoRequestFinishBlock)block;
/// 停止传输数据
/// @param songId 歌曲 id
/// @param type 1: PCM 数据 | 2: 图片数据 | 3: 歌词数据
/// @param block 回调
- (void) stopData:(NSString*)songId dataType:(NSInteger)type callback:(QPlayAutoRequestFinishBlock)block;
@end

NS_ASSUME_NONNULL_END
