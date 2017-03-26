//
//  ViewController.m
//  METLive
//
//  Created by Metallic  on 17/3/25.
//  Copyright © 2017年 xiaowei. All rights reserved.
//

#import "METLiveViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface METLiveViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureConnection *videoCaptureConnection;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;

@end

@implementation METLiveViewController

- (void)viewDidLoad
{
    [self setupCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_captureSession stopRunning];
}

//开始和结束录制
- (IBAction)startButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (_captureSession.isRunning) {
        [_captureSession stopRunning];
        [button setTitle:@"开始" forState:UIControlStateNormal];
    } else {
        [_captureSession startRunning];
        [button setTitle:@"结束" forState:UIControlStateNormal];
    }
}

//切换相机方向
- (IBAction)switchCameraPosition:(id)sender
{
    if (!_captureSession.isRunning) return;
    
    //1.获取相机方向
    AVCaptureDevicePosition currentPosition = _videoDevice.position;
    
    //2.根据当前方向获取要切换的方向
    AVCaptureDevicePosition switchPosition = currentPosition == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    //3.获取切换后的设备
    AVCaptureDevice *newDevice = [self videoDeviceForPosition:switchPosition];
    
    //4.获取新的设备输入
    AVCaptureDeviceInput *newDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:NULL];
    
    //5.移除之前的设备输入
    [_captureSession removeInput:_videoDeviceInput];
    
    //6.添加新的设备输入
    if ([_captureSession canAddInput:newDeviceInput]) {
        [_captureSession addInput:newDeviceInput];
    }
    
    //7.替换设备和输入对象
    _videoDevice = newDevice;
    _videoDeviceInput = newDeviceInput;
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
    [self.view.layer insertSublayer:previewLayer atIndex:0];
}

- (void)configureVideoCapture
{
    //1.获取摄像头设备，默认为后置摄像头
    _videoDevice = [self videoDeviceForPosition:AVCaptureDevicePositionBack];
    
    //2.创建视频输入对象
    _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:NULL];
    
    //3.向会话中添加视频输入对象
    if ([_captureSession canAddInput:_videoDeviceInput]) {
        [_captureSession addInput:_videoDeviceInput];
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
    //1.创建音频输入设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //2.创建音频输入对象
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:NULL];
    
    //3.将输入对象加入到会话中
    if ([_captureSession canAddInput:audioDeviceInput]) {
        [_captureSession addInput:audioDeviceInput];
    }
    
    //4.创建音频数据输出对象
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    //5.创建音频数据输出队列
    dispatch_queue_t audioSerialQueue = dispatch_queue_create("com.METLive.audioCapture.audioSerialQueue", NULL);
    
    //6.配置音频数据输出对象
    [audioDataOutput setSampleBufferDelegate:self queue:audioSerialQueue];
    
    //7.将输出对象添加到会话中
    if ([_captureSession canAddOutput:audioDataOutput]) {
        [_captureSession addOutput:audioDataOutput];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == _videoCaptureConnection) {
        NSLog(@"采集到视频数据！");
    } else {
        NSLog(@"采集到音频数据！");
    }
}

@end
