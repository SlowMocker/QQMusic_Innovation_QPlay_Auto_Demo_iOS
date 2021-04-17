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

/// 监听 socket
@property (nonatomic , strong) GCDAsyncSocket *tcpSocket;
/// 已连接 socket
@property (nonatomic , strong) GCDAsyncSocket *qmSocket;

@property (nonatomic , strong) NSMutableDictionary *pcmHeaderDicM;
@property (nonatomic , strong) NSMutableData *pcmDataM;

@property (nonatomic , strong) NSMutableDictionary *picHeaderDicM;
@property (nonatomic , strong) NSMutableData *picDataM;

@property (nonatomic , strong) NSMutableDictionary *lyricHeaderDicM;
@property (nonatomic , strong) NSMutableData *lyricDataM;

@end

@implementation DataSocket

- (instancetype) init {
    self = [super init];
    if (self) {
        self.pcmHeaderDicM = NSMutableDictionary.new;
        self.pcmDataM = NSMutableData.new;
        self.picHeaderDicM = NSMutableDictionary.new;
        self.picDataM = NSMutableData.new;
        self.lyricHeaderDicM = NSMutableDictionary.new;
        self.lyricDataM = NSMutableData.new;
    }
    return self;
}

- (void) start {
    if (self.tcpSocket != nil) {
        return;
    }
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    //    [self.tcpSocket setAutoDisconnectOnClosedReadStream:NO];
    NSError *error = nil;
    if (![self.tcpSocket acceptOnPort:LocalDataPort error:&error]) {
        //NSLog(@"Error acceptOnPort: %@", error);
        return;
    }
}

- (void) stop {
    if (self.qmSocket != nil) {
        if (self.qmSocket.isConnected) [self.qmSocket disconnect];
        self.qmSocket = nil;
    }
    if (self.tcpSocket != nil) {
        if(self.tcpSocket.isConnected) [self.tcpSocket disconnect];
        self.tcpSocket = nil;
    }
}

#pragma mark GCDAsyncSocketDelegate

- (void) socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    if (newSocket == nil) {
        return;
    }
        
    if (self.qmSocket!=nil) {
        NSLog(@"【WARNNING】dataSocket cliet socket is exist already. new:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
        return;
    }
    self.qmSocket = newSocket;
    [self.qmSocket readDataWithTimeout:-1 tag:0];
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"【ERROR】data socket disconnect: %@",err);
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
            if (self.pcmDataM.length > 0) {
                NSLog(@"\nWARNNING】获取到异常的 PCM 数据\n");
            }
            self.pcmHeaderDicM = [descDic mutableCopy];
        }
        if ([[self.pcmHeaderDicM allKeys] containsObject:@"PCMData"]) {
            [self.pcmDataM appendData:partData];
        }

        if ([[descDic allKeys] containsObject:@"PICData"]) {
            // 请求到 JSON header
            [self flushPicData];
            if (self.picDataM.length > 0) {
                NSLog(@"\n【WARNNING】获取到异常的 PIC 数据\n");
            }
            self.picHeaderDicM = [descDic mutableCopy];
        }
        if ([[self.picHeaderDicM allKeys] containsObject:@"PICData"]) {
            [self.picDataM appendData:partData];
        }

        if ([[descDic allKeys] containsObject:@"LyricData"]) {
            // 请求到 JSON header
            [self flushLyricData];
            if (self.picDataM.length > 0) {
                NSLog(@"\n【WARNNING】获取到异常的 LYRIC 数据\n");
            }
            self.lyricHeaderDicM = [descDic mutableCopy];
        }
        if ([[self.lyricHeaderDicM allKeys] containsObject:@"LyricData"]) {
            [self.lyricDataM appendData:partData];
        }

    }];

    // PCM
    if ([self.pcmHeaderDicM.allKeys containsObject:@"PCMData"]) {
        if (self.pcmDataM.length >= ((NSNumber *)self.pcmHeaderDicM[@"PCMData"][@"Length"]).integerValue && self.onPcmDataCallback) {
            //NSLog(@"\ndesc: %@",self.descPcmDicM);
            //NSLog(@"pcm return size: %ld",(long)self.pcmDataM.length);
            self.onPcmDataCallback(self.pcmHeaderDicM, self.pcmDataM);
            [self flushPcmData];
        }
    }

    // PIC
    if ([self.picHeaderDicM.allKeys containsObject:@"PICData"]) {

        if (self.picDataM.length >= ((NSNumber *)self.picHeaderDicM[@"PICData"][@"Length"]).integerValue && self.onPicDataCallback) {
            //NSLog(@"\ndesc: %@",self.descPicDicM);
            //NSLog(@"pic return size: %ld",(long)self.picDataM.length);
            self.onPicDataCallback(self.picHeaderDicM, self.picDataM);
            [self flushPicData];
        }
    }

    // Lyric
    if ([self.lyricHeaderDicM.allKeys containsObject:@"LyricData"]) {

        if (self.lyricDataM.length >= ((NSNumber *)self.lyricHeaderDicM[@"LyricData"][@"Length"]).integerValue && self.onLyricDataCallback) {
            //NSLog(@"\ndesc: %@",self.descLyricDicM);
            //NSLog(@"lyric return size: %ld",(long)self.lyricDataM.length);
            self.onLyricDataCallback(self.lyricHeaderDicM, self.lyricDataM);
            [self flushLyricData];
        }
    }

    //NSLog(@"***********************\n\n\n\n\n");
    [self.qmSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - private methods
- (void) parseData:(NSData *)data callback:(void (^)(NSDictionary *descDic, NSData *partData, NSString *errDes))callback {
    if (data.length <= 0) {
        NSLog(@"【ERROR】: data socket 返回数据异常！！！");
        if (callback) callback(nil, nil, @"data socket 返回数据异常");
    }

    // 已经有了 JSON header，data 是纯数据
    if ([self.pcmHeaderDicM.allKeys containsObject:@"PCMData"] ||
        [self.picHeaderDicM.allKeys containsObject:@"PICData"] ||
        [self.lyricHeaderDicM.allKeys containsObject:@"LyricData"]) {
        if (callback) callback(nil, data, nil);
        return;
    }

    // 查找分隔符
    NSData *breakData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *copyData = [data subdataWithRange:NSMakeRange(0, data.length)];
    
    // first break range
    // iOS API 只支持后序查找
    NSRange firstBreakRange = [copyData rangeOfData:breakData options:NSDataSearchBackwards range:NSMakeRange(0, copyData.length)];
    // 未找到分隔符，data 是纯数据
    if (firstBreakRange.length == 0) {
        if (callback) callback(nil, data, nil);
        return;
    }
    
    // 尝试去找下一个 break range
    NSRange nextBreakRange = [copyData rangeOfData:breakData options:NSDataSearchBackwards range:NSMakeRange(0, firstBreakRange.location)];
    while (nextBreakRange.length != 0) {
        nextBreakRange = [copyData rangeOfData:breakData options:NSDataSearchBackwards range:NSMakeRange(0, firstBreakRange.location)];
        if (nextBreakRange.length != 0) {
            firstBreakRange = nextBreakRange;
        }
    }

    // data 描述信息
    NSData *headerData = [data subdataWithRange:NSMakeRange(0, firstBreakRange.location)];
    NSUInteger startIndex = firstBreakRange.location + firstBreakRange.length;
    // 截取的 PCM data
    NSData *pcmData = [data subdataWithRange:NSMakeRange(startIndex, data.length - startIndex)];
    NSError *error = nil;
    NSDictionary *descDic = [NSJSONSerialization JSONObjectWithData:headerData options:0 error:&error];
    if (error) {
        if (callback) callback(nil, nil, @"JSON 头解析失败");
        return;
    }
    if (callback) callback(descDic, pcmData, nil);
}

- (void) flushData {
    self.pcmHeaderDicM = NSMutableDictionary.new;
    self.pcmDataM = NSMutableData.new;
    self.picHeaderDicM = NSMutableDictionary.new;
    self.picDataM = NSMutableData.new;
    self.lyricHeaderDicM = NSMutableDictionary.new;
    self.lyricDataM = NSMutableData.new;
}

- (void) flushPcmData {
    self.pcmHeaderDicM = NSMutableDictionary.new;
    self.pcmDataM = NSMutableData.new;
}

- (void) flushPicData {
    self.picHeaderDicM = NSMutableDictionary.new;
    self.picDataM = NSMutableData.new;
}

- (void) flushLyricData {
    self.lyricHeaderDicM = NSMutableDictionary.new;
    self.lyricDataM = NSMutableData.new;
}
@end

