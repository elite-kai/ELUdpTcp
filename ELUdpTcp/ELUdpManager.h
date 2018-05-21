//
//  ELUdpManager.h
//  ELUdpTcp
//
//  Created by elite-kai on 2018/5/21.
//  Copyright © 2018年 udp/tcp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

@protocol ELUdpManagerDelegate <NSObject>

- (void)clientSocketDidReceiveMessage:(NSDictionary *)message andPort:(uint16_t)port withHost:(NSString *)hostIP;

@end

@interface ELUdpManager : NSObject<GCDAsyncUdpSocketDelegate>

@property (nonatomic,assign)NSInteger times;

@property (nonatomic, weak)id <ELUdpManagerDelegate>delegate;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

@property (nonatomic, copy) NSString *mHost;
@property (nonatomic, assign) int mPort;


- (void)bindToPort:(NSInteger)port;

- (void)sendMessageToHost:(NSString *)host WithPort:(uint16_t)port transData:(NSDictionary *)dataPackage;

- (void)disconnect;

@end
