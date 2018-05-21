//
//  ViewController.m
//  ELUdpTcp
//
//  Created by elite-kai on 2018/5/21.
//  Copyright © 2018年 udp/tcp. All rights reserved.
//

#import "ViewController.h"

#import "ELTcpManager.h"
#import "ELUdpManager.h"

@interface ViewController ()<ELTcpManagerDelegate, ELUdpManagerDelegate>

@property (nonatomic, strong) ELUdpManager *udpManager;
@property (nonatomic, strong) ELTcpManager *tcpManager;
@property (atomic, strong) NSMutableArray *deviceIdArray;

@property (nonatomic, assign) long tcpTag;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _deviceIdArray = [NSMutableArray array];
    
    _tcpTag = 100;
    
    self.udpManager = [[ELUdpManager alloc] init];
    self.udpManager.delegate = self;
    [self.udpManager bindToPort:8200];

}

#pragma mark -- ELUdpManager delegate
- (void)clientSocketDidReceiveMessage:(NSDictionary *)message andPort:(uint16_t)port withHost:(NSString *)hostIP
{
    //message是嵌入式工程师传给你的信息
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"message  *********  %@", message);
        
        /*
         **针对多个设备连接时，因为不能同时收到设备发出的广播，所以要一直不停的接收广播
         **将设备的id存入数组，如果数组中存在了则不需要再对此设备进行tcp连接
         */
        if (![self.deviceIdArray containsObject:message[@"clientid"]] &&
            message[@"clientid"] != nil &&
            ![message[@"clientid"] isEqual:[NSNull null]])
        {
            NSLog(@"udpMessageModel.clientid  ****** %@", message[@"clientid"]);
            
            if ([self.deviceIdArray containsObject:message[@"clientid"]]) return;
            
            NSMutableDictionary *udpMessage = [[NSMutableDictionary alloc] initWithDictionary:message];
            //设置每个tcp需要的tag值
            self.tcpTag++;
            
            [udpMessage setValue:@(self.tcpTag) forKey:@"clientid"];
            
            [[ELTcpManager shareInstance] initAsyncSocketWithHost:message[@"host"] port:[message[@"port"] integerValue] udpMessage:udpMessage];
            [ELTcpManager shareInstance].delegate = self;
            
            [self.deviceIdArray addObject:message[@"clientid"]];
        }
    });
    
}

#pragma mark -- ELTcpManager delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"tcp读取到数据");
    //    tcp在异步线程发消息，返回的时候需要在主线程
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self invalidate];
    });
    
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

}


- (void)dealloc
{
    
    [self invalidate];
}


- (void)invalidate
{
    [_deviceIdArray removeAllObjects];
    [self.udpManager disconnect];
    [ELTcpManager shareInstance].delegate = nil;
    [[ELTcpManager shareInstance] destroy];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
