//
//  ELTcpManager.m
//  ELUdpTcp
//
//  Created by elite-kai on 2018/5/21.
//  Copyright © 2018年 udp/tcp. All rights reserved.
//

#import "ELTcpManager.h"

@interface ELTcpManager() <GCDAsyncSocketDelegate>

@end

static ELTcpManager *manager = nil;

@implementation ELTcpManager

+ (ELTcpManager *)shareInstance
{
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        
        manager = [[ELTcpManager alloc] init];
        manager.socketDic = [NSMutableDictionary dictionary];
    
    });
    return manager;
    
}

+ (void)destroyInstance
{
    manager = nil;
}


- (void)initAsyncSocketWithHost:(NSString *)host port:(uint16_t)port udpMessage:(NSDictionary *)udpMessage
{
    
    /*
     **这个地方用到了全局队列，用了异步线程，在代理方法中处理一些事情的时候回到主线程
     **这里进行了多次尝试然后才选择了这样写，具体为什么我还不太清楚，大家如果有更好的解决办法可以指出
     */
    dispatch_queue_t queue = dispatch_queue_create("ELTcpManager", NULL);
    dispatch_async(queue, ^{
        
        NSLog(@"host *****  %@,  port ********  %hu", host, port);
        GCDAsyncSocket *asyncsocket = [[GCDAsyncSocket alloc] init];
        asyncsocket.delegate = self;
        asyncsocket.delegateQueue = dispatch_get_main_queue();
        
        //如果不写这行代码就不会走下面这个代理方法，所以先暂时这么解决
        //- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
    
        self.asyncsocket = asyncsocket;
        
        //这里将host作为key，因为host就是硬件的ip地址，它们每个都不一样
        [manager.socketDic setValue:udpMessage forKey:host];
        
        NSError *error = nil;
        
        BOOL isConnect = [asyncsocket connectToHost:host onPort:port withTimeout:-1 error:&error];
        if (!isConnect)
        {
            
            NSLog(@"连接失败");
        }
        else
        {
            NSLog(@"连接成功");
            
        }
        
    });
}



- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    
    NSLog(@"didConnectToHosthost *********  %@", host);
    
    //连接成功以后开始发送数据，给设备发送数据
    NSDictionary *udpMessage = manager.socketDic[sock.connectedHost];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"app" forKey:@"app"];
    NSString *pem = [self dictionaryToJson:[params copy]];
    NSData *data = [pem dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:data withTimeout:-1 tag:[udpMessage[@"tcpTag"] intValue]];
    
    if ([self.delegate respondsToSelector:@selector(socket:didConnectToHost:port:)]) {
        [self.delegate socket:sock didConnectToHost:host port:port];
    }
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    NSLog(@"_asyncsocket地址 error ********** %@", error);

    
    NSDictionary *udpMessage = manager.socketDic[sock.connectedHost];
    // 等待数据来啊
    [sock readDataWithTimeout:-1 tag:[udpMessage[@"tcpTag"] intValue]];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSDictionary *udpMessage = manager.socketDic[sock.connectedHost];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    NSLog(@"tcp 应答jsonDict  ===========> %@",jsonDict);
    
    //收到tcp应答，进行处理，这里是由嵌入式工程师对设备写的代码
    if ([jsonDict[@"ack"] isEqual:@"ok"])
    {
        NSLog(@"socketDic  *******  %@", manager.socketDic);
        
        if ([self.delegate respondsToSelector:@selector(socket:didReadData:withTag:)]) {
            [self.delegate socket:sock didReadData:data withTag:tag];
        }
    }
    
    // 等待数据来啊
    [sock readDataWithTimeout:-1 tag:[udpMessage[@"tcpTag"] intValue]];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"didWriteDataWithTag");

    NSDictionary *udpMessage = manager.socketDic[sock.connectedHost];
    // 等待数据来啊
    [sock readDataWithTimeout:-1 tag:[udpMessage[@"tcpTag"] intValue]];

    
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    NSLog(@"timeout");
    return 0;
}


- (void)destroy
{
    NSLog(@"tcp  destroy");
    [manager.socketDic removeAllObjects];

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
