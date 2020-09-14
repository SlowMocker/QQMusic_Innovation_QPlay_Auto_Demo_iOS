//
//  DataSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "DataSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMNetworkHelper.h"
#import "QMMacros.h"

@interface DataSocket()<GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket *tcpSocket;
@property (nonatomic,strong) GCDAsyncSocket *qmSocket;

@property (nonatomic , strong) NSMutableDictionary *descPcmDicM;
@property (nonatomic , strong) NSMutableData *pcmDataM;

@property (nonatomic , strong) NSMutableDictionary *descPicDicM;
@property (nonatomic , strong) NSMutableData *picDataM;

@property (nonatomic , strong) NSMutableDictionary *descLyricDicM;
@property (nonatomic , strong) NSMutableData *lyricDataM;

@end

@implementation DataSocket

- (instancetype)init {
    self = [super init];
    if (self) {
        self.descPcmDicM = NSMutableDictionary.new;
        self.pcmDataM = NSMutableData.new;
        self.descPicDicM = NSMutableDictionary.new;
        self.picDataM = NSMutableData.new;
        self.descLyricDicM = NSMutableDictionary.new;
        self.lyricDataM = NSMutableData.new;
    }
    return self;
}

- (void)start
{
    if(self.tcpSocket!=nil)
    {
        return;
    }
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    //    [self.tcpSocket setAutoDisconnectOnClosedReadStream:NO];
    NSError *error = nil;
    if (![self.tcpSocket acceptOnPort:LocalDataPort error:&error])
    {
        //NSLog(@"Error acceptOnPort: %@", error);
        return;
    }
}

- (void)stop
{
    if(self.qmSocket!=nil)
    {
        if(self.qmSocket.isConnected)
            [self.qmSocket disconnect];
        self.qmSocket = nil;
    }
    if(self.tcpSocket!=nil)
    {
        if(self.tcpSocket.isConnected)
            [self.tcpSocket disconnect];
        self.tcpSocket = nil;
    }
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
//    //NSLog(@"******************didAcceptNewSocket");
    if(newSocket==nil)
        return;
    if(self.qmSocket!=nil)
    {
//        //NSLog(@"dataSocket cliet socket is exist already. new:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
        return;
    }
    self.qmSocket = newSocket;
    [self.qmSocket readDataWithTimeout:-1 tag:0];
//    //NSLog(@"dataSocket didAcceptNewSocket:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
    
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
//    //NSLog(@"******************socketDidDisconnect:%@",err);
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    //NSLog(@"\n\n\n\n\n");
    //NSLog(@"***********************");
    //NSLog(@"data length: %ld", (long)data.length);

    // 解析 JSON 头
    // 同步接口
    [self parseData:data callback:^(NSDictionary *descDic, NSData *partData, NSString *errDes) {
        // 出现错误
        if (errDes) {
            [self flushData];
            [self.qmSocket readDataWithTimeout:-1 tag:0];
            return;
        }

        if ([[descDic allKeys] containsObject:@"PCMData"]) {
            // 请求到 JSON header
            [self flushPcmData];
            self.descPcmDicM = [descDic mutableCopy];
        }
        if ([[self.descPcmDicM allKeys] containsObject:@"PCMData"]) {
            [self.pcmDataM appendData:partData];
        }

        if ([[descDic allKeys] containsObject:@"PICData"]) {
            // 请求到 JSON header
            [self flushPicData];
            self.descPicDicM = [descDic mutableCopy];
        }
        if ([[self.descPicDicM allKeys] containsObject:@"PICData"]) {
            [self.picDataM appendData:partData];
        }

        if ([[descDic allKeys] containsObject:@"LyricData"]) {
            // 请求到 JSON header
            [self flushLyricData];
            self.descLyricDicM = [descDic mutableCopy];
        }
        if ([[self.descLyricDicM allKeys] containsObject:@"LyricData"]) {
            [self.lyricDataM appendData:partData];
        }

    }];

    // PCM
    if ([self.descPcmDicM.allKeys containsObject:@"PCMData"]) {
        if (self.pcmDataM.length >= ((NSNumber *)self.descPcmDicM[@"PCMData"][@"Length"]).integerValue && self.onPcmDataCallback) {
            //NSLog(@"\ndesc: %@",self.descPcmDicM);
            //NSLog(@"pcm return size: %ld",(long)self.pcmDataM.length);
            self.onPcmDataCallback(self.descPcmDicM, self.pcmDataM);
            [self flushPcmData];
        }
    }

    // PIC
    if ([self.descPicDicM.allKeys containsObject:@"PICData"]) {

        if (self.picDataM.length >= ((NSNumber *)self.descPicDicM[@"PICData"][@"Length"]).integerValue && self.onPicDataCallback) {
            //NSLog(@"\ndesc: %@",self.descPicDicM);
            //NSLog(@"pic return size: %ld",(long)self.picDataM.length);
            self.onPicDataCallback(self.descPicDicM, self.picDataM);
            [self flushPicData];
        }
    }

    // Lyric
    if ([self.descLyricDicM.allKeys containsObject:@"LyricData"]) {

        if (self.lyricDataM.length >= ((NSNumber *)self.descLyricDicM[@"LyricData"][@"Length"]).integerValue && self.onLyricDataCallback) {
            //NSLog(@"\ndesc: %@",self.descLyricDicM);
            //NSLog(@"lyric return size: %ld",(long)self.lyricDataM.length);
            self.onLyricDataCallback(self.descLyricDicM, self.lyricDataM);
            [self flushLyricData];
        }
    }

    //NSLog(@"***********************\n\n\n\n\n");
    [self.qmSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - private methods
- (void) parseData:(NSData *)data callback:(void (^)(NSDictionary *descDic, NSData *partData, NSString *errDes))callback {
    if (data.length <= 0) {
        //NSLog(@"【ERROR】: data socket 返回数据异常！！！");
        if (callback) callback(nil, nil, @"data socket 返回数据异常");
    }

    // 已经有了 JSON header，data 为纯数据
    if ([self.descPcmDicM.allKeys containsObject:@"PCMData"] ||
        [self.descPicDicM.allKeys containsObject:@"PICData"] ||
        [self.descLyricDicM.allKeys containsObject:@"LyricData"]) {
        if (callback) callback(nil, data, nil);
        return;
    }

    NSData *sData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *searchData = [data subdataWithRange:NSMakeRange(0, data.length)];
    NSRange sRange = [searchData rangeOfData:sData options:NSDataSearchBackwards range:NSMakeRange(0, searchData.length)];
    NSRange searchRange = [searchData rangeOfData:sData options:NSDataSearchBackwards range:NSMakeRange(0, sRange.location)];
    while (searchRange.length != 0) {
        searchRange = [searchData rangeOfData:sData options:NSDataSearchBackwards range:NSMakeRange(0, sRange.location)];
        if (searchRange.length != 0) {
            sRange = searchRange;
        }
    }

    //    //NSLog(@"**************************************************************header: %ld",(long)(sRange.location + 2));

    // 未找到，是纯数据
    if (sRange.length == 0) {
        if (callback) callback(nil, data, nil);
    }
    else {
        NSData *descData = [data subdataWithRange:NSMakeRange(0, sRange.location)];
        NSUInteger startIndex = sRange.location+sRange.length;
        NSData *pData = [data subdataWithRange:NSMakeRange(startIndex, data.length - startIndex)];
        NSError *error = nil;
        NSDictionary *descDic = [NSJSONSerialization JSONObjectWithData:descData options:0 error:&error];
        if (error) {
            if (callback) callback(nil, nil, @"JSON 头解析失败");
            return;
        }
        if (callback) callback(descDic, pData, nil);
    }
}

- (void) flushData {
    self.descPcmDicM = NSMutableDictionary.new;
    self.pcmDataM = NSMutableData.new;
    self.descPicDicM = NSMutableDictionary.new;
    self.picDataM = NSMutableData.new;
    self.descLyricDicM = NSMutableDictionary.new;
    self.lyricDataM = NSMutableData.new;
}

- (void) flushPcmData {
    self.descPcmDicM = NSMutableDictionary.new;
    self.pcmDataM = NSMutableData.new;
}

- (void) flushPicData {
    self.descPicDicM = NSMutableDictionary.new;
    self.picDataM = NSMutableData.new;
}

- (void) flushLyricData {
    self.descLyricDicM = NSMutableDictionary.new;
    self.lyricDataM = NSMutableData.new;
}
@end

