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

@property (nonatomic) dispatch_queue_t queue;

@end

@implementation VinsViewController {

    //UI/timing global setup
    Boolean dataPresenting;
    NSTimer *collectionInterval; //IMU time collection interval
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    dataPresenting = false;
    
    //set orientation
    self.orientation = [[UIDevice currentDevice] orientation];
    
    //IMU data set up
    self.manager = [[CMMotionManager alloc] init];
    dataPresenting = false;
    [self showIMULabels:dataPresenting];
    
    //begin camera session
     self.imageCaptureSession = [AVCaptureSession new];
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
    
    //input
    [self setupInputDevice];
    
    //output
    [self setupOutputConfigurations];
    
    //view preview
    [self setupPreviewLayer];
    
    dispatch_async(self.queue, ^{
        NSLog(@"here");
        [self.imageCaptureSession startRunning];
    });

    NSLog(@"capture session inputs: %@", [self.imageCaptureSession inputs]);
    NSLog(@"capture session outputs: %@", [self.imageCaptureSession outputs]);

}

- (void)setupInputDevice {
    
    //setup camera output res
    [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //set up camera
    AVCaptureDevice *capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:capDevice error:&error];
    
    //set framerate (currently 15fps ~ 30hz)
    [capDevice lockForConfiguration:&error];
    capDevice.activeVideoMinFrameDuration = CMTimeMake(1,30);
    [capDevice unlockForConfiguration];
    
    //making sure device is available
    if ([self.imageCaptureSession canAddInput:deviceInput]) {
        
        [self.imageCaptureSession addInput:deviceInput];
        
    } else {
        
        NSLog(@"Couldn't add video input device");
        
    }
    
}

- (void)setupOutputConfigurations {
    
    //setup output from camera input (need extra raw)
    self.imageOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // discard if the data output queue is blocked (as we process the still image)
    [self.imageOutput setAlwaysDiscardsLateVideoFrames:true];
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    self.queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    [self.imageOutput setSampleBufferDelegate:self queue:self.queue];
    
    self.imageOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    if ([self.imageCaptureSession canAddOutput:self.imageOutput]) {
        
        [self.imageCaptureSession addOutput:self.imageOutput];
        
    } else {
        
        NSLog(@"Couldn't add video output");
        
    }
    
}

- (void)setupPreviewLayer {
    
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    NSLog(@"delegate method called");
    
}

//Create UIImage from sample buffer
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    
    //Get a CMSampleBuffer's core video image buffer forthe media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    //Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    //Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    //Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //Create device dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return image;
    
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