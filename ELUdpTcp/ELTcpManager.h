//
//  ELTcpManager.h
//  ELUdpTcp
//
//  Created by elite-kai on 2018/5/21.
//  Copyright © 2018年 udp/tcp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol ELTcpManagerDelegate <NSObject>

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error;
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag;

@end

@interface ELTcpManager : NSObject

@property(strong,nonatomic) GCDAsyncSocket *asyncsocket;
//存储收到的广播信息
@property (nonatomic, strong) NSMutableDictionary *socketDic;
@property (nonatomic, strong) NSMutableArray *connectedSocketArray;


@property(nonatomic,strong)id<ELTcpManagerDelegate>delegate;

+ (ELTcpManager *)shareInstance;

+ (void)destroyInstance;

- (void)initAsyncSocketWithHost:(NSString *)host port:(uint16_t)port udpMessage:(NSDictionary *)udpMessage;


- (void)destroy;


@end
