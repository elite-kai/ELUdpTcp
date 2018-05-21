//
//  ELUdpManager.m
//  ELUdpTcp
//
//  Created by elite-kai on 2018/5/21.
//  Copyright © 2018年 udp/tcp. All rights reserved.
//

#import "ELUdpManager.h"

@interface ELUdpManager ()


@end

@implementation ELUdpManager

- (void)bindToPort:(NSInteger)port;
{
    //这个地方用到了全局队列，用了异步线程，在代理方法中处理一些事情的时候回到主线程
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];

    
    NSError *error = nil;
    //绑定本地端口
    [self.udpSocket bindToPort:port error:&error];
    if (error)
    {
        NSLog(@"udp error 1  *******  %@", error);
        return;
    }
    //启用广播
    [self.udpSocket enableBroadcast:YES error:&error];
    if (error)
    {
        NSLog(@"udp error 2  *******  %@", error);
        return;
    }
    //开始接收数据(不然会收不到数据)
    [self.udpSocket beginReceiving:&error];
    if (error)
    {
        NSLog(@"udp error 3  *******  %@", error);
        return;
    }
    
}


- (void)sendMessageUdp:(GCDAsyncUdpSocket *)udpSocket port:(uint16_t)port
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"app" forKey:@"app"];

    NSString *pem = [self dictionaryToJson:[params copy]];
    NSData *data = [pem dataUsingEncoding:NSUTF8StringEncoding];

    //此处如果写成固定的IP就是对特定的server监测
    NSString *host = @"255.255.255.255";
    //发送数据（tag: 消息标记）
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:100];
    
}

- (void)sendMessageToHost:(NSString *)host WithPort:(uint16_t)port transData:(NSDictionary *)dataPackage
{
    NSLog(@"sendMessageToHost");
}

- (void)disconnect
{
    self.udpSocket.delegate = nil;
    [self.udpSocket closeAfterSending];
    self.udpSocket = nil;
}

#pragma mark - socket delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"didConnectToAddress");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
    NSLog(@"didNotConnect");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"didSendDataWithTag");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"didNotSendDataWithTag");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    //    NSLog(@"udp应答***********  %@", jsonDict);
    
    if ([self.delegate respondsToSelector:@selector(clientSocketDidReceiveMessage:andPort:withHost:)]) {
        [self.delegate clientSocketDidReceiveMessage:jsonDict andPort:port withHost:ip];
    }

}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{

    NSLog(@"udpSocketDidClose");
}

//字典转字符串
- (NSString *)dictionaryToJson:(NSDictionary *)dic

{
    NSError *parseError = nil;
    
    if (@available(iOS 11.0, *)) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingSortedKeys error:&parseError];
        
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        // Fallback on earlier versions
        //NSJSONWritingOptions  设置为0代表输出格式为一整行，设置1代表输出的是好看的json格式，换行了
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&parseError];
        
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

@end
