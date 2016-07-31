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
#import "AppDelegate.h"

//#define TIMESTAMP [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]
#define GRAVITY ((double) 9.80781) //minneapolis specific, working on implementing CoreLocation for dynamics
#define IMU_COLLECTION_INTERVAL ((double) 0.01) //10Hz
#define PGM_HEADING640x480 @"P5\n640 480\n255\n"

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
NSDate *zeroTime;
int frameCounter;

double accelx;
double accely;
double accelz;
double gyrox;
double gyroy;
double gyroz;

//directories to be used
NSArray *paths;
NSString *documentsDirectory;
NSString *dataPathImages;
NSString *dataPathImagesTimeStamps;
NSString *dataPathIMU;
NSString *dataPathIMUTimeStamps;
NSFileHandle *fileHandlerImages;
NSFileHandle *fileHandlerImagesTimeStamps;
//NSFileHandle *fileHandlerIMU; not necessary at the moment
NSFileHandle *fileHandlerIMUTimeStamps;

//frame buffer size
size_t bufferSize;

//app delegate
AppDelegate *appDelegate;

-(NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //class global setup
    
    dataPresenting = false;
    frameCounter = 0;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    dataPathImages = [documentsDirectory stringByAppendingPathComponent:@"/Images"];
    dataPathImagesTimeStamps = [dataPathImages stringByAppendingPathComponent:@"/imageTimestamps.txt"];
    dataPathIMU = [documentsDirectory stringByAppendingPathComponent:@"/IMU"];
    dataPathIMUTimeStamps = [dataPathIMU stringByAppendingPathComponent:@"/imuTimestamps.txt"];
    
    //create necessary subdirectories if not already present
    [self subDirectorySetup];

    //set orientation
    self.orientation = [[UIDevice currentDevice] orientation];
    
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        //IMU data set up
        self.manager = [[CMMotionManager alloc] init];
        dataPresenting = false;
        [self showIMULabels:dataPresenting];
        
        //set up IMU collection intervals
        self.manager.accelerometerUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
        [self.manager startAccelerometerUpdates];
        
        self.manager.gyroUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
        [self.manager startGyroUpdates];
        
        //[self getIMUValues];
        
        //CMMotionManager initiation
        collectionInterval = [NSTimer scheduledTimerWithTimeInterval:IMU_COLLECTION_INTERVAL target:self selector:@selector(getIMUValues) userInfo:nil repeats:true]; //100 Hz
        
    });
     */
    
    //IMU data set up
    self.manager = [[CMMotionManager alloc] init];
    dataPresenting = false;
    [self showIMULabels:dataPresenting];
    
    
    //set up IMU collection intervals
    self.manager.accelerometerUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
    [self.manager startAccelerometerUpdates];
    
    self.manager.gyroUpdateInterval = IMU_COLLECTION_INTERVAL;  // 100 Hz
    [self.manager startGyroUpdates];
    
    [self getIMUValues];
    
    //CMMotionManager initiation
    collectionInterval = [NSTimer scheduledTimerWithTimeInterval:IMU_COLLECTION_INTERVAL target:self selector:@selector(getIMUValues) userInfo:nil repeats:true]; //100 Hz
    
    
    /*
    NSOperationQueue *accelQueue = [[NSOperationQueue alloc] init];
    
    [[self manager] setGyroUpdateInterval:IMU_COLLECTION_INTERVAL];
    [[self manager] setAccelerometerUpdateInterval:IMU_COLLECTION_INTERVAL];
    
    [[self manager] startAccelerometerUpdatesToQueue:accelQueue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        
        accelx = self.manager.accelerometerData.acceleration.x;
        accely = self.manager.accelerometerData.acceleration.y;
        accelz = self.manager.accelerometerData.acceleration.z;
        
    }];
    
    NSOperationQueue *gyroQueue = [[NSOperationQueue alloc] init];
    
    [[self manager] setGyroUpdateInterval:IMU_COLLECTION_INTERVAL];
    [[self manager] setAccelerometerUpdateInterval:IMU_COLLECTION_INTERVAL];
    
    [[self manager] startGyroUpdatesToQueue:gyroQueue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        
        gyrox = self.manager.gyroData.rotationRate.x;
        gyroy = self.manager.gyroData.rotationRate.y;
        gyroz = self.manager.gyroData.rotationRate.z;
        
    }];
    */
    
    
    //disable extra camera features (see function for more detail)
    [self disableAutoFocus];
    
    //begin camera session
    [self startCameraSession];
    [self setupPreviewLayer];
    
    //set landscape left as output normal
    if ([[self captureConnection] isVideoOrientationSupported]) {
        ///test
        [[self captureConnection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        
    }
    
    //monitor orientation changes i.e. portrait vs landscape
    /*
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
     */
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [self.imageCaptureSession stopRunning];
    [collectionInterval invalidate];
    [[self manager] stopAccelerometerUpdates];
    [[self manager] stopGyroUpdates];
    
    collectionInterval = nil;
    zeroTime = nil;
        
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
        NSLog(@"%@", error);
    }
    
    [self.imageCaptureSession addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    self.imageOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.imageCaptureSession addOutput:self.imageOutput];
    
    //set up connection and proper output orientation
    self.captureConnection = [[self imageOutput] connectionWithMediaType:AVMediaTypeVideo];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.imageOutput setSampleBufferDelegate:self queue:queue];
    
    // Specify the pixel format
    self.imageOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // set frame rate to ~30fps
    /*
    [device lockForConfiguration:nil];
    device.activeVideoMinFrameDuration = CMTimeMake(1, 30);
    [device unlockForConfiguration];
     */
    int fps = 30;  // 30 fps
    [device lockForConfiguration:nil];
    [device setActiveVideoMinFrameDuration:CMTimeMake(1, fps)];
    [device setActiveVideoMaxFrameDuration:CMTimeMake(1, fps)];
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

    [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    self.previewInputLayer.frame = self.view.bounds;
    
    /*
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
     */
    
    [self.previewInputLayer setFrame:frame];
    [root insertSublayer:self.previewInputLayer atIndex:0];
    
}

//handling orientation change
- (void)orientationChanged {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    self.orientation = orientation;
    
    if (self.orientation == UIInterfaceOrientationPortrait) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        self.previewInputLayer.frame = self.cameraView.bounds;
        [self.previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeLeft) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        self.previewInputLayer.frame = self.cameraView.bounds;
        [self.previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
    } else if (self.orientation == UIInterfaceOrientationLandscapeRight) {
        
        [self.previewInputLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        self.previewInputLayer.frame = self.cameraView.bounds;
        [self.previewInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    }
    
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    //filename/path for buffer image
    NSString *filePath = [NSString stringWithFormat:@"%@/m%07d.pgm", dataPathImages, frameCounter];
    
    //initialize file with pgm formatting
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:[PGM_HEADING640x480 dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    //set destination of output buffer to created file path
    fileHandlerImages = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    //process captured buffer data
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0); //lock buffer address for recording
    
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    bufferSize = bufferHeight * bytesPerRow;
    
    unsigned char *rowBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    //write organized buffer data to NSData for file
    NSData *data = [NSData dataWithBytes:rowBase length:bufferSize];
    
    //write to file
    [fileHandlerImages seekToEndOfFile];
    [fileHandlerImages writeData:data];
    [fileHandlerImages closeFile];
    
    //release address
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    //write to timestamp file
    NSDate *time = [NSDate date];
    NSTimeInterval differenceTime = [time timeIntervalSinceDate:zeroTime];
    NSData *textToFIle = [[NSString stringWithFormat:@"m%07d.pgm %f\n", frameCounter, differenceTime] dataUsingEncoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [fileHandlerImagesTimeStamps writeData:textToFIle];
        
    });
    
    frameCounter += 1;
    
}

//create subdirectories in Documents, Documents/Images && Documents/IMU && Documents/Images/ImagesTimeStamps, to hold captured images and imu
- (void)subDirectorySetup {
    
    NSError *error;
    
    //use these declarations to create folders at each viewDidLoad, essentially starting over each time
    
    //delete contents each time for testing sake
    [[NSFileManager defaultManager] removeItemAtPath:dataPathImages error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMU error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dataPathImagesTimeStamps error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMUTimeStamps error:nil];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImages withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images folder
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathIMU withIntermediateDirectories:NO attributes:nil error:&error]; //Create IMU folder
    
    [[NSFileManager defaultManager] createFileAtPath:dataPathImagesTimeStamps contents:nil attributes:nil]; //Create Images/timestamps.txt textfile
    
    [[NSFileManager defaultManager] createFileAtPath:dataPathIMUTimeStamps contents:nil attributes:nil]; //Create IMU/timestamps.txt textfile
    
    fileHandlerImagesTimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathImagesTimeStamps];
    //fileHandlerIMU = [NSFileHandle fileHandleForWritingAtPath:dataPathIMU];
    fileHandlerIMUTimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathIMUTimeStamps];
    
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

- (void)getIMUValues {
    
    double accelDatax = self.manager.accelerometerData.acceleration.x * GRAVITY;
    double accelDatay = self.manager.accelerometerData.acceleration.y * GRAVITY;
    double accelDataz = self.manager.accelerometerData.acceleration.z * GRAVITY;
    
    double gyroDatax = self.manager.gyroData.rotationRate.x;
    double gyroDatay = self.manager.gyroData.rotationRate.y;
    double gyroDataz = self.manager.gyroData.rotationRate.z;

    
    //accelerometer labels to 4 decimal points
    
    self.xPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDatax];
    self.yPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDatay];
    self.zPositionAcc.text = [NSString stringWithFormat:@"%.4f", accelDataz];
    
    //gyroscope to two decimal points
    self.xPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDatax];
    self.yPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDatay];
    self.zPositionGyro.text = [NSString stringWithFormat:@"%.4f", gyroDataz];
     
    
    //writing data to file more efficiently
    NSDate *time = [NSDate date];
    
    if (zeroTime == nil) {
        
        zeroTime = time;
    
    }
    
    NSTimeInterval differenceTime = [time timeIntervalSinceDate:zeroTime];
    NSData *textToFIle = [[NSString stringWithFormat:@"%f - gyro %f %f %f accel %f %f %f\n", differenceTime, gyroDatax, gyroDatay, gyroDataz, accelDatax, accelDatay, accelDataz] dataUsingEncoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [fileHandlerIMUTimeStamps writeData:textToFIle];
        
    });
    
    
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

//disabling extra camera capabilities (autofocus, flash, and torch)
-(void)disableAutoFocus {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    [device setTorchMode:AVCaptureTorchModeOff];
    [device setFlashMode:AVCaptureFlashModeOff];
    
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        
        if (([device hasMediaType:AVMediaTypeVideo]) && ([device position] == AVCaptureDevicePositionBack) ) {
            
            [device lockForConfiguration:&error];
            if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                
                device.focusMode = AVCaptureFocusModeLocked;
                
            }
            
            [device unlockForConfiguration];
            
        }
        
    }
    
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