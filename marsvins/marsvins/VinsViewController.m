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

@interface VinsViewController ()

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

@end

@implementation VinsViewController

//UI/timing global setup
Boolean dataPresenting = false;
NSTimer *collectionInterval; //IMU time collection interval

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    self.manager = [[CMMotionManager alloc] init];
    dataPresenting = false;
    [self showIMULabels:dataPresenting];
    
    //begin camera session
    [self startCameraSession];

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
    
    //setup camera feed
    self.imageCaptureSession = [[AVCaptureSession alloc] init];
    [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //set up camera
    AVCaptureDevice *capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:capDevice error:&error];
    
    //making sure device is available
    if ([self.imageCaptureSession canAddInput:deviceInput]) {
        
        [self.imageCaptureSession addInput:deviceInput];
        
    }
    
    // later probabaly use this for raw data frame : AVCaptureVideoDataOutput
    //setup display of image input
    AVCaptureVideoPreviewLayer *previewInputLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.imageCaptureSession];
    [previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *root = [self.cameraView layer];
    [root setMasksToBounds:true];
    CGRect frame = [self.view frame];
    [previewInputLayer setFrame:frame];
    [root insertSublayer:previewInputLayer atIndex:0];
    
    //setup output from camera input
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.imageOutput setOutputSettings:outputSettings];
    
    [self.imageCaptureSession addOutput:self.imageOutput];
    
    //begin session
    [self.imageCaptureSession startRunning];
    
}

- (void)getIMUValues:(NSTimer *)timer {
    
    //accelerometer to two decimal points
    self.xPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.x];
    self.yPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.y];
    self.zPositionAcc.text = [NSString stringWithFormat:@"%.4f",self.manager.accelerometerData.acceleration.z];
    
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

