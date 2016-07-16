//
//  VinsViewController.m
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VinsViewController.h"

@interface VinsViewController ()

@end

@implementation VinsViewController

AVCaptureSession *imageCaptureSession;
AVCaptureStillImageOutput *imageOutput;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:true];
    
    //hide navbar
    [[self navigationController] setNavigationBarHidden:true animated:true];
    
    //retain back gesture capability
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    //setup camera feed
    imageCaptureSession = [[AVCaptureSession alloc] init];
    [imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //set up camera
    AVCaptureDevice *capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:capDevice error:&error];
    
    //making sure device is available
    if ([imageCaptureSession canAddInput:deviceInput]) {
        
        [imageCaptureSession addInput:deviceInput];
        
    }
    
    // later probabaly use this for raw data frame : AVCaptureVideoDataOutput
    //setup display of image input
    AVCaptureVideoPreviewLayer *previewInputLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:imageCaptureSession];
    [previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *root = [self.cameraView layer];
    [root setMasksToBounds:true];
    CGRect frame = [self.view frame];
    [previewInputLayer setFrame:frame];
    [root insertSublayer:previewInputLayer atIndex:0];
    
    //setup output from camera input
    imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [imageOutput setOutputSettings:outputSettings];
    
    [imageCaptureSession addOutput:imageOutput];
    
    //begin session
    [imageCaptureSession startRunning];
    
}

//conform to UIGesturerecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
