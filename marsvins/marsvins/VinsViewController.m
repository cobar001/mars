//
//  VinsViewController.m
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import "VinsViewController.h"

@interface VinsViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

//strictly UI static labels
@property (weak, nonatomic) IBOutlet UIButton *showDataButtonOutlet;

@property (weak, nonatomic) IBOutlet UILabel *accelerometerTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *xposaLabel;

@property (weak, nonatomic) IBOutlet UILabel *yposaLabel;

@property (weak, nonatomic) IBOutlet UILabel *zposaLabel;

@property (weak, nonatomic) IBOutlet UILabel *gyroscopeTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *xposgLabel;

@property (weak, nonatomic) IBOutlet UILabel *yposgLabel;

@property (weak, nonatomic) IBOutlet UILabel *zposgLabel;


//strictly UI dynamic labels
@property (weak, nonatomic) IBOutlet UILabel *xPositionAcc;

@property (weak, nonatomic) IBOutlet UILabel *yPositionAcc;

@property (weak, nonatomic) IBOutlet UILabel *zPositionAcc;

@property (weak, nonatomic) IBOutlet UILabel *xPositionGyro;

@property (weak, nonatomic) IBOutlet UILabel *yPositionGyro;

@property (weak, nonatomic) IBOutlet UILabel *zPositionGyro;

//dynamic variable to track orientaion output view of camera
@property (nonatomic) AVCaptureVideoPreviewLayer *previewInputLayer;

@property (nonatomic) UIDeviceOrientation orientation;

@end

@implementation VinsViewController

//UI/timing global setup
Boolean dataPresenting = false;
NSTimer *collectionInterval; //IMU time collection interval

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //set orientation
    self.orientation = [[UIDevice currentDevice] orientation];
    
    //IMU data set up
    self.manager = [[CMMotionManager alloc] init];
    dataPresenting = false;
    [self showIMULabels:dataPresenting];
    
    //begin camera session
    self.imageCaptureSession = [[AVCaptureSession alloc] init];
    [self startCameraSession];
    
    
    //monitor orientation changes i.e. portrait vs landscape
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    //discontinue orientation notifications on view once view disbanded
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIDeviceOrientationDidChangeNotification object:nil];
    
    [self.imageCaptureSession stopRunning];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:true];
    
    //hide navbar
    [[self navigationController] setNavigationBarHidden:true animated:true];
    
    //retain navbar back gesture capability
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    //button styling
    [[self.showDataButtonOutlet layer] setBorderWidth:2.0f];
    [[self.showDataButtonOutlet layer] setCornerRadius:10.0];
    [[self.showDataButtonOutlet layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    
}

//conform to UIGesturerecognizerDelegate for back swipe and no nav
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (IBAction)showDataButtonPressed {
    
    if (!dataPresenting) {
        
        //UI button update
        [self.showDataButtonOutlet setTitle:@"Stop/Hide data" forState:UIControlStateNormal];
        
        //CMMotionManager initiation
        collectionInterval = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getIMUValues:) userInfo:nil repeats:true];
        
        self.manager.accelerometerUpdateInterval = 0.05;  // 20 Hz
        [self.manager startAccelerometerUpdates];
        
        self.manager.gyroUpdateInterval = 0.05;  // 20 Hz
        [self.manager startGyroUpdates];
        
        dataPresenting = true;
        
    } else {
        
        [collectionInterval invalidate];
        collectionInterval = nil;
        
        [self.showDataButtonOutlet setTitle:@"Show IMU data" forState:UIControlStateNormal];
        
        dataPresenting = false;
        
    }
    
    [self showIMULabels:dataPresenting];
    
}

- (void)startCameraSession {
    
    //UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //setup camera output res
    [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //set up camera
    AVCaptureDevice *capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:capDevice error:&error];
    
    //making sure device is available
    if ([self.imageCaptureSession canAddInput:deviceInput]) {
        
        [self.imageCaptureSession addInput:deviceInput];
        
    } else {
        
        NSLog(@"Couldn't add video input device");
        
    }
    
    //set framerate (currently 15fps ~ 30hz)
    [capDevice lockForConfiguration:&error];
    capDevice.activeVideoMinFrameDuration = CMTimeMake(1,30);
    [capDevice unlockForConfiguration];
    
    //setup display of image display to user
    self.previewInputLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.imageCaptureSession];
    [self.previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *root = [self.cameraView layer];
    [root setMasksToBounds:true];
    CGRect frame = [self.view frame];
    
    if (self.orientation == UIInterfaceOrientationPortrait) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        self.previewInputLayer.frame = self.view.bounds;
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeLeft) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        self.previewInputLayer.frame = self.view.bounds;
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeRight) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        self.previewInputLayer.frame = self.view.bounds;
        
    }
    
    [self.previewInputLayer setFrame:frame];
    [root insertSublayer:self.previewInputLayer atIndex:0];
    
    //setup output from camera input (need extra raw)
    //self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.imageOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // discard if the data output queue is blocked (as we process the still image)
    //[self.imageOutput setAlwaysDiscardsLateVideoFrames:true];
    
    //NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    
    NSDictionary *outputSettings = @{ (NSString *) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    self.imageOutput.videoSettings = outputSettings;
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    [self.imageOutput setSampleBufferDelegate:self queue:dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL)];
    
    if ([self.imageCaptureSession canAddOutput:self.imageOutput]) {
        
        [self.imageCaptureSession addOutput:self.imageOutput];
        
    } else {
        
        NSLog(@"Couldn't add video output");
        
    }
    
    //allow still image capturing
    AVCaptureStillImageOutput *stillImageOut = [[AVCaptureStillImageOutput alloc] init];
    
    if ([self.imageCaptureSession canAddOutput:stillImageOut]) {
        
        [self.imageCaptureSession addOutput:stillImageOut];
        
    } else {
        
        NSLog(@"Couldn't add still image output");

        
    }
    
    //begin session
    dispatch_queue_t sessionQueue = dispatch_queue_create("capsesh", DISPATCH_QUEUE_SERIAL);
    dispatch_async(sessionQueue, ^(void) {
       
        [self.imageCaptureSession startRunning];
        
    });
    //[self.imageCaptureSession startRunning];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    /*
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    GLubyte *rawImageBytes = CVPixelBufferGetBaseAddress(cameraFrame);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
    NSData *dataForRawBytes = [NSData dataWithBytes:rawImageBytes length:bytesPerRow * CVPixelBufferGetHeight(cameraFrame)];
    NSLog(@"%@", dataForRawBytes.description);
     */
    
}

//handling orientation change
//need to work on upsidedown capabilities (maybe)
- (void)orientationChanged {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    self.orientation = orientation;
    
    if (self.orientation == UIInterfaceOrientationPortrait) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        self.previewInputLayer.frame = self.cameraView.bounds;
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeLeft) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        self.previewInputLayer.frame = self.cameraView.bounds;
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeRight) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        self.previewInputLayer.frame = self.cameraView.bounds;
        
    }
    
}

- (void)getIMUValues:(NSTimer *)timer {
    
    //accelerometer to two decimal points
    self.xPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.x * 9.8];
    self.yPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.y * 9.8];
    self.zPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.z * 9.8];
    
    //gyroscope to two decimal points
    self.xPositionGyro.text = [NSString stringWithFormat:@"%.4f",self.manager.gyroData.rotationRate.x];
    self.yPositionGyro.text = [NSString stringWithFormat:@"%.4f",self.manager.gyroData.rotationRate.y];
    self.zPositionGyro.text = [NSString stringWithFormat:@"%.4f",self.manager.gyroData.rotationRate.z];
    
}


- (void)showIMULabels:(BOOL)areShowing {
    
    [self.accelerometerTitleLabel setHidden:!areShowing];
    [self.gyroscopeTitleLabel setHidden:!areShowing];
    
    [self.xposaLabel setHidden:!areShowing];
    [self.yposaLabel setHidden:!areShowing];
    [self.zposaLabel setHidden:!areShowing];
    [self.xposgLabel setHidden:!areShowing];
    [self.yposgLabel setHidden:!areShowing];
    [self.zposgLabel setHidden:!areShowing];
    
    
    [self.xPositionAcc setHidden:!areShowing];
    [self.yPositionAcc setHidden:!areShowing];
    [self.zPositionAcc setHidden:!areShowing];
    [self.xPositionGyro setHidden:!areShowing];
    [self.yPositionGyro setHidden:!areShowing];
    [self.zPositionGyro setHidden:!areShowing];
    
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