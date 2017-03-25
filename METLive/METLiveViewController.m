//
//  ViewController.m
//  METLive
//
//  Created by Metallic  on 17/3/25.
//  Copyright © 2017年 xiaowei. All rights reserved.
//

#import "METLiveViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface METLiveViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureConnection *videoCaptureConnection;
@property (nonatomic, strong) AVCaptureConnection *audioCaptureConnection;

@end

@implementation METLiveViewController

- (void)viewDidLoad
{
    [self setupCaptureSession];
}

- (void)setupCaptureSession
{
    //1.创建会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    //2.视频采集配置
    [self configureVideoCapture];
    
    //3.音频采集配置
    [self configureAudioCapture];
    
    //4.添加视频录制的预览图层
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    previewLayer.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:previewLayer];
    
    [_captureSession startRunning];
}

- (void)configureVideoCapture
{
    //1.获取摄像头设备，默认为后置摄像头
    AVCaptureDevice *videoDevice = [self videoDeviceForPosition:AVCaptureDevicePositionBack];
    
    //2.创建视频输入对象
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:NULL];
    
    //3.向会话中添加视频输入对象
    if ([_captureSession canAddInput:videoDeviceInput]) {
        [_captureSession addInput:videoDeviceInput];
    }
    
    //4.创建视频数据输出对象
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    //5.创建视频数据输出队列，必须为串行队列
    dispatch_queue_t videoSerialQueue = dispatch_queue_create("com.METLive.videoCapture.videoSerialQueue", NULL);
    
    //6.配置输出对象
    [videoDataOutput setSampleBufferDelegate:self queue:videoSerialQueue];
    
    //7.将输出对象添加到会话中
    if ([_captureSession canAddOutput:videoDataOutput]) {
        [_captureSession addOutput:videoDataOutput];
    }
    
    //8.获取输入与输出的连接
    _videoCaptureConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (AVCaptureDevice *)videoDeviceForPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *device = nil;
    
    NSArray *devicesArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *aDevice in devicesArray) {
        if (aDevice.position == position) {
            device = aDevice;
        }
    }
    
    return device;
}

- (void)configureAudioCapture
{
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == _videoCaptureConnection) {
        NSLog(@"采集到视频数据！");
    }
}

@end
