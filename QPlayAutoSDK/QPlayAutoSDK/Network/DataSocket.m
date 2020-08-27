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

@property (nonatomic , strong) NSMutableDictionary *descDicM;
@property (nonatomic , strong) NSMutableData *pcmDataM;

@end

@implementation DataSocket

- (instancetype)init {
    self = [super init];
    if (self) {
        self.descDicM = NSMutableDictionary.new;
        self.pcmDataM = NSMutableData.new;
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
        NSLog(@"Error acceptOnPort: %@", error);
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
    NSLog(@"******************didAcceptNewSocket");
    if(newSocket==nil)
        return;
    if(self.qmSocket!=nil)
    {
        NSLog(@"dataSocket cliet socket is exist already. new:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
        return;
    }
    self.qmSocket = newSocket;
    [self.qmSocket readDataWithTimeout:-1 tag:0];
    NSLog(@"dataSocket didAcceptNewSocket:%@ %d",newSocket.connectedHost,newSocket.connectedPort);
    
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"******************socketDidDisconnect:%@",err);
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    dispatch_async(dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL), ^{
        NSLog(@"\n\n\n\n\n");
        NSLog(@"***********************");
        NSLog(@"data length: %ld", (long)data.length);

        if (data.length == 1024) {
            NSLog(@"");
        }

        // 解析 JSON 头
        // 同步接口
        [DataSocket parsePcmData:data callback:^(NSDictionary *descDic, NSData *pcmPartData, NSString *errDes) {
            // 出现错误
            if (errDes) {
                [self flushData];
                [self.qmSocket readDataWithTimeout:-1 tag:0];
                return;
            }

            if (descDic) {
                // 请求到 JSON header
                [self flushData];
                self.descDicM = [descDic mutableCopy];
            }
            [self.pcmDataM appendData:pcmPartData];
        }];

        // PCM
        if ([self.descDicM.allKeys containsObject:@"PCMData"]) {

            if (self.pcmDataM.length >= PCMBufSize && self.onPcmDataCallback) {
                NSLog(@"\ndesc: %@",self.descDicM);
                NSLog(@"pcm return size: %ld",(long)self.pcmDataM.length);
                self.onPcmDataCallback(self.descDicM, self.pcmDataM);
                [self flushData];
            }
        }

        NSLog(@"***********************\n\n\n\n\n");
        [self.qmSocket readDataWithTimeout:-1 tag:0];
    });
}

#pragma mark - private methods
+ (void) parsePcmData:(NSData *)data callback:(void (^)(NSDictionary *descDic, NSData *pcmPartData, NSString *errDes))callback {
    if (data.length <= 0) {
        NSLog(@"【ERROR】: data socket 返回数据异常！！！");
        if (callback) callback(nil, nil, @"data socket 返回数据异常");
    }

    NSData *sData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSRange sRange = [data rangeOfData:sData options:NSDataSearchBackwards range:NSMakeRange(0, data.length)];
    // 未找到，是纯数据
    if (sRange.length == 0) {
        if (callback) callback(nil, data, nil);
    }
    else {
        NSData *descData = [data subdataWithRange:NSMakeRange(0, sRange.location)];
        NSUInteger startIndex = sRange.location+sRange.length;
        NSData *ppData = [data subdataWithRange:NSMakeRange(startIndex, data.length - startIndex)];
        NSError *error = nil;
        NSDictionary *descDic = [NSJSONSerialization JSONObjectWithData:descData options:0 error:&error];
        if (error) {
            if (callback) callback(nil, nil, @"JSON 头解析失败");
            return;
        }
        if (callback) callback(descDic, ppData, nil);
    }
}

- (void) flushData {
    self.descDicM = NSMutableDictionary.new;
    self.pcmDataM = NSMutableData.new;
}

@end

