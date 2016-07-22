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

#define TIMESTAMP [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]
#define GRAVITY ((double) 9.80781) //minneapolis specific, working on implementing CoreLocation for dynamics
#define IMU_COLLECTION_INTERVAL ((double) 0.01) //100Hz

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
Boolean dataPresenting;
NSTimer *collectionInterval; //IMU time collection interval
int frameCounter;

    

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    dataPresenting = false;
    
    //create necessary subdirectories if not already present
    [self subDirectorySetup];
    
    //set orientation
    self.orientation = [[UIDevice currentDevice] orientation];
    
    //IMU data set up
    self.manager = [[CMMotionManager alloc] init];
    dataPresenting = false;
    [self showIMULabels:dataPresenting];
    
    //set up IMU collection intervals
    self.manager.accelerometerUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
    [self.manager startAccelerometerUpdates];
    
    self.manager.gyroUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
    [self.manager startGyroUpdates];
    
    //CMMotionManager initiation
    collectionInterval = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getIMUValues:) userInfo:nil repeats:true];
    
    //begin camera session
    [self startCameraSession];
    
    [self setupPreviewLayer];
    
    //monitor orientation changes i.e. portrait vs landscape
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [self.imageCaptureSession stopRunning];
    [collectionInterval invalidate];
    collectionInterval = nil;
    
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
        
        dataPresenting = true;
        
    } else {
        
        [self.showDataButtonOutlet setTitle:@"Show IMU data" forState:UIControlStateNormal];
        
        dataPresenting = false;
        
    }
    
    [self showIMULabels:dataPresenting];
    
}

- (void)startCameraSession {
    
    NSError *error = nil;
    
    // Create the session
    self.imageCaptureSession = [[AVCaptureSession alloc] init];
    
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (!input) {
        // Handling the error appropriately.
    }
    
    [self.imageCaptureSession addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    self.imageOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.imageCaptureSession addOutput:self.imageOutput];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.imageOutput setSampleBufferDelegate:self queue:queue];
    
    // Specify the pixel format
    self.imageOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // If you wish to cap the frame rate to a known value, such as 15 fps, set
    // minFrameDuration.
    [device lockForConfiguration:nil];
    device.activeVideoMinFrameDuration = CMTimeMake(1, 15);
    [device unlockForConfiguration];
    
    //discard frames if processor running behind
    [self.imageOutput setAlwaysDiscardsLateVideoFrames:true];
    
    // Start the session running to start the flow of data
    [self.imageCaptureSession startRunning];

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

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    // Create a UIImage from the sample buffer data
    //UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    //NSLog(@"image processed %@", image.description);
    //Get a CMSampleBuffer's core video image buffer forthe media data
    
    frameCounter += 1;
    
    //NSLog(@"m%@ - %@", [NSString stringWithFormat:@"%07d", frameCounter], TIMESTAMP);
    
}

NSData* imageToBuffer(CMSampleBufferRef source) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(source);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    //size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return data;
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

- (void)subDirectorySetup {
    
    //create subdirectories in Documents, Documents/Images && Documents/IMU && Documents/Images/ImagesTimeStamps, to hold captured images and imu
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPathImages = [documentsDirectory stringByAppendingPathComponent:@"/Images"];
    NSString *dataPathImagesTimeStamps = [documentsDirectory stringByAppendingPathComponent:@"/Images/Timestamps"];
    NSString *dataPathIMU = [documentsDirectory stringByAppendingPathComponent:@"/IMU"];
    
    //use these three declarations to create folders at each viewDidLoad, essentially starting over each time
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImages withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images folder
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImagesTimeStamps withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images/ImagesTimeStamps folder
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathIMU withIntermediateDirectories:NO attributes:nil error:&error]; //Create IMU folder
    
    /* when saving files for multiple sessions
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPathImages]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImages withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images folder
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPathImagesTimeStamps]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImagesTimeStamps withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images/ImagesTimeStamps folder
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPathIMU]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPathIMU withIntermediateDirectories:NO attributes:nil error:&error]; //Create IMU folder
    }
    */
    
}

- (void)getIMUValues:(NSTimer *)timer {
    
    double accelDatax = self.manager.accelerometerData.acceleration.x * GRAVITY;
    double accelDatay = self.manager.accelerometerData.acceleration.y * GRAVITY;
    double accelDataz = self.manager.accelerometerData.acceleration.z * GRAVITY;
    
    double gyroDatax = self.manager.gyroData.rotationRate.x;
    double gyroDatay = self.manager.gyroData.rotationRate.y;
    double gyroDataz = self.manager.gyroData.rotationRate.z;
    
    //accelerometer to two decimal points
    self.xPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDatax];
    self.yPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDatay];
    self.zPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDataz];
    
    //gyroscope to two decimal points
    self.xPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDatax];
    self.yPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDatay];
    self.zPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDataz];
    
    NSLog(@"%@ - gyro %f %f %f accel %f %f %f", TIMESTAMP, gyroDatax, gyroDatay, gyroDataz, accelDatax, accelDatay, accelDataz);
    
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