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
#import "GyroData.h"
#import "AccelData.h"
#import "Interpolator.h"
#import "IMUMeasurement.h"

//#define TIMESTAMP [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]
#define GRAVITY ((double) 9.80781) //minneapolis specific, working on implementing CoreLocation for dynamics
#define IMU_COLLECTION_INTERVAL 0.01f // 100Hz
#define PGM_HEADING640x480 @"P5\n640 480\n255\n"
#define PGM_HEADING1280x720 @"P5\n1280 720\n255\n"

@interface VinsViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureVideoPreviewLayer *previewInputLayer;
//dynamic variable to track orientaion output view of camera
@property (nonatomic) UIDeviceOrientation orientation;

@end

@implementation VinsViewController

//UI/timing global setup
double uptime;
int frameCounter;

//directories to be used
NSArray *paths;
NSString *documentsDirectory;
NSString *dataPathImages;
NSString *dataPathImagesTimeStamps;
NSString *dataPathIMU;
NSString *dataPathIMUTimeStamps;
NSString *dataPathIMUATimeStamps;
NSString *dataPathIMUGTimeStamps;

NSString *dataPathImages1280;
NSString *dataPathImagesTimeStamps1280;

NSFileHandle *fileHandlerImages;
NSFileHandle *fileHandlerImagesTimeStamps;
NSFileHandle *fileHandlerIMUTimeStamps;
NSFileHandle *fileHandlerIMUATimeStamps;
NSFileHandle *fileHandlerIMUGTimeStamps;

NSFileHandle *fileHandlerImages1280;
NSFileHandle *fileHandlerImagesTimeStamps1280;

NSOperationQueue *cameraQueue;
NSOperationQueue *interpolatorQueue;

Interpolator *interpolator;
bool run_interpolator;

//frame buffer size
size_t bufferSize;

//app delegate
AppDelegate *appDelegate;

-(NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = true;
    
    
    //class global setup
    uptime = [[NSProcessInfo processInfo] systemUptime]; //get uptime
    run_interpolator = true;
    frameCounter = 0;
    
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    dataPathImages = [documentsDirectory stringByAppendingPathComponent:@"/Images"];
    dataPathImagesTimeStamps = [dataPathImages stringByAppendingPathComponent:@"/timestamps.txt"];
    dataPathIMU = [documentsDirectory stringByAppendingPathComponent:@"/IMU"];
    dataPathIMUTimeStamps = [dataPathIMU stringByAppendingString:@"/imu.txt"];
    dataPathIMUATimeStamps = [dataPathIMU stringByAppendingPathComponent:@"/imuAccelTimestamps.txt"];
    dataPathIMUGTimeStamps = [dataPathIMU stringByAppendingPathComponent:@"/imuGyroTimestamps.txt"];
    
    dataPathImages1280 = [documentsDirectory stringByAppendingPathComponent:@"/Images1280"];
    dataPathImagesTimeStamps1280 = [dataPathImages1280 stringByAppendingPathComponent:@"/timestamps.txt"];
    
    //create necessary subdirectories if not already present
    [self subDirectorySetup];

    //set orientation
    self.orientation = [[UIDevice currentDevice] orientation];
    
    //IMU data set up
    self.manager = [[CMMotionManager alloc] init];
    
    //setup Qs
    cameraQueue = [[NSOperationQueue alloc] init];
    interpolatorQueue = [[NSOperationQueue alloc] init];
    interpolator = [[Interpolator alloc] init];
    
    if (self.manager.gyroAvailable) {
        
        self.manager.gyroUpdateInterval = IMU_COLLECTION_INTERVAL;
        
        [self.manager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
            
            GyroData *gyroDataLog = [[GyroData alloc] init:gyroData.timestamp - uptime
                                                        X:gyroData.rotationRate.x
                                                        Y:gyroData.rotationRate.y
                                                        Z:gyroData.rotationRate.z];
            
            
            [interpolator GiveGyro:gyroDataLog];


            NSData *textToFileGyro = [[NSString stringWithFormat:@"%@\n", gyroDataLog.toString] dataUsingEncoding:NSUTF8StringEncoding];

            [fileHandlerIMUGTimeStamps writeData:textToFileGyro];
            
            
        }];
            
    }
    
    if (self.manager.accelerometerAvailable) {
        
        self.manager.accelerometerUpdateInterval = IMU_COLLECTION_INTERVAL;
        
        [self.manager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
            
            AccelData *accelDataLog = [[AccelData alloc] init:accelerometerData.timestamp - uptime
                                                            X:accelerometerData.acceleration.x * GRAVITY
                                                            Y:accelerometerData.acceleration.y * GRAVITY
                                                            Z:accelerometerData.acceleration.z * GRAVITY];
            
            [interpolator GiveAccel:accelDataLog];
            
            NSData *textToFileAccel = [[NSString stringWithFormat:@"%@\n", accelDataLog.toString] dataUsingEncoding:NSUTF8StringEncoding];
            
            [fileHandlerIMUATimeStamps writeData:textToFileAccel];
                                    
        }];
    }
    
    [interpolatorQueue addOperationWithBlock:^{
        
        while (run_interpolator) {
            IMUMeasurement *imu = [interpolator interpolate];
            //NSLog(@"%@", imu);
            if (imu != nil) {
                NSData *textToFileIMU = [[NSString stringWithFormat:@"%@\n", imu.toString] dataUsingEncoding:NSUTF8StringEncoding];
                [fileHandlerIMUTimeStamps writeData:textToFileIMU];
            }
        }
    }];
    
    //disable extra camera features (see function for more detail)
    //[self disableAutoFocus];
    
    //begin camera session
    [self startCameraSession];
    [self setupPreviewLayer];
    
    //set landscape left as output normal
    if ([[self captureConnection] isVideoOrientationSupported]) {
        [[self captureConnection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    
    [self setupResLabel];
    
    //monitor orientation changes i.e. portrait vs landscape
    /*
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
     */
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [self.imageCaptureSession stopRunning];
    run_interpolator = false;
    [[self manager] stopAccelerometerUpdates];
    [[self manager] stopGyroUpdates];
    [UIApplication sharedApplication].idleTimerDisabled = false;
    
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
    
}

- (void)setupResLabel {
    
    UILabel *switchLabel = [[UILabel alloc] init];
    if ([self is640]) {
        
        switchLabel.text = @"640x480 30 fps";
        
    } else {
        
        switchLabel.text = @"1280x720 240 fps";
        
    }
    switchLabel.numberOfLines = 2;
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.translatesAutoresizingMaskIntoConstraints = false;
    switchLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:switchLabel];
    
    //[fpsSwitch.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [switchLabel.centerXAnchor constraintEqualToAnchor:self.cameraView.centerXAnchor].active = true;
    [switchLabel.topAnchor constraintEqualToAnchor:self.cameraView.topAnchor constant:80.0].active = true;
    [switchLabel.widthAnchor constraintEqualToAnchor:self.cameraView.widthAnchor constant:-50.0].active = true;
    [switchLabel.heightAnchor constraintEqualToConstant:60].active = true;
    
}

//conform to UIGesturerecognizerDelegate for back swipe and no nav
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

//ala 240 fps, but only with >= 720x1280def
- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
{
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [device formats]) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    if (bestFormat) {
        if ([device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = bestFormat;
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }

}

- (void)startCameraSession {
    
    NSError *error = nil;
    
    // Create the session
    self.imageCaptureSession = [[AVCaptureSession alloc] init];
    
    // Configure the session resolution
    if ([self is640]) {
        
        [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset640x480];

    } else {
        
        [self.imageCaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];

    }
    
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
    
    // set frame rate
    if ([self is640]) {
        
        int fps = 30;
        [device lockForConfiguration:nil];
        [device setActiveVideoMinFrameDuration:CMTimeMake(1, fps)];
        [device setActiveVideoMaxFrameDuration:CMTimeMake(1, fps)];
        [device unlockForConfiguration];
        
    } else {
        
        //set frame rate to highest possible
        [self configureCameraForHighestFrameRate:device];

    }
    
    //diable auto focus
    [self disableAutoFocus];
    
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
    
    /* for various orientations
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

//handling orientation change, if we support it
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
    
    if ([self is640]) {
        //filename/path for buffer image
        NSString *filePath = [NSString stringWithFormat:@"%@/m%07d.pgm", dataPathImages, frameCounter];
        
        //initialize file with pgm formatting, 640x480
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
        
        //write to file, every frame
        [fileHandlerImages seekToEndOfFile];
        [fileHandlerImages writeData:data];
        [fileHandlerImages closeFile];
        
        //release address
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        //write to timestamp file
        double time = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer));
        double differenceTime = time - uptime;
        
        NSData *textToFile = [[NSString stringWithFormat:@"m%07d.pgm %f\n", frameCounter, differenceTime] dataUsingEncoding:NSUTF8StringEncoding];
        
        [cameraQueue addOperationWithBlock:^{
            
            [fileHandlerImagesTimeStamps writeData:textToFile];
            
        }];
        
        //frameCounter += 1;
    
    } else {
        
        //1280x720
        if ((frameCounter % 7) == 0) {
            //filename/path for buffer image
            NSString *filePath = [NSString stringWithFormat:@"%@/m%07d.pgm", dataPathImages1280, frameCounter/7];
            
            //initialize file with pgm formatting, 1280x720
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:[PGM_HEADING1280x720 dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
            
            
            //set destination of output buffer to created file path
            fileHandlerImages1280 = [NSFileHandle fileHandleForWritingAtPath:filePath];
            
            //process captured buffer data
            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            CVPixelBufferLockBaseAddress(pixelBuffer, 0); //lock buffer address for recording
            
            size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
            bufferSize = bufferHeight * bytesPerRow;
            
            unsigned char *rowBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            
            //write organized buffer data to NSData for file
            NSData *data = [NSData dataWithBytes:rowBase length:bufferSize];
            
            //write to file, every frame
            [fileHandlerImages1280 seekToEndOfFile];
            [fileHandlerImages1280 writeData:data];
            [fileHandlerImages1280 closeFile];
            
            //release address
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            
            //write to timestamp file
            double time = CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer));
            double differenceTime = time - uptime;
            
            NSData *textToFile = [[NSString stringWithFormat:@"m%07d.pgm %f\n", frameCounter/7, differenceTime] dataUsingEncoding:NSUTF8StringEncoding];
            
            [cameraQueue addOperationWithBlock:^{
                
                [fileHandlerImagesTimeStamps1280 writeData:textToFile];
                
            }];
            
        }
    
    }
    
    frameCounter += 1;
    
}

//create subdirectories in Documents, Documents/Images && Documents/IMU && Documents/Images/ImagesTimeStamps, to hold captured images and imu
- (void)subDirectorySetup {
    
    NSError *error;
    
    //use these declarations to create folders at each viewDidLoad, essentially starting over each time
    
    //delete contents each time for testing sake
    if ([self is640]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:dataPathImages error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:dataPathImagesTimeStamps error:nil];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImages withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images folder
        [[NSFileManager defaultManager] createFileAtPath:dataPathImagesTimeStamps contents:nil attributes:nil]; //Create Images/timestamps.txt
        
        fileHandlerImagesTimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathImagesTimeStamps];

    } else {
        
        [[NSFileManager defaultManager] removeItemAtPath:dataPathImages1280 error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:dataPathImagesTimeStamps1280 error:nil];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPathImages1280 withIntermediateDirectories:NO attributes:nil error:&error];
        [[NSFileManager defaultManager] createFileAtPath:dataPathImagesTimeStamps1280 contents:nil attributes:nil];
        
        fileHandlerImagesTimeStamps1280 = [NSFileHandle fileHandleForWritingAtPath:dataPathImagesTimeStamps1280];
        
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMU error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMUTimeStamps error:nil]; //for combo
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMUATimeStamps error:nil]; //for seperate
    [[NSFileManager defaultManager] removeItemAtPath:dataPathIMUGTimeStamps error:nil]; //
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPathIMU withIntermediateDirectories:NO attributes:nil error:&error]; //Create IMU folder
    [[NSFileManager defaultManager] createFileAtPath:dataPathIMUTimeStamps contents:nil attributes:nil]; //Create IMU/imuTimestamps
    [[NSFileManager defaultManager] createFileAtPath:dataPathIMUATimeStamps contents:nil attributes:nil]; //Create IMU/acceltimestamps.txt
    [[NSFileManager defaultManager] createFileAtPath:dataPathIMUGTimeStamps contents:nil attributes:nil]; //Create IMU/gyrotimestamps.txt
    
    
    fileHandlerIMUTimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathIMUTimeStamps];
    fileHandlerIMUATimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathIMUATimeStamps];
    fileHandlerIMUGTimeStamps = [NSFileHandle fileHandleForWritingAtPath:dataPathIMUGTimeStamps];
    
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

//disabling extra camera capabilities (autofocus, flash, and torch)
-(void)disableAutoFocus {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    //[device setTorchMode:AVCaptureTorchModeOff];
    //[device setFlashMode:AVCaptureFlashModeOff];
    
    
    NSArray *devices = [AVCaptureDevice devices];
    NSError *error;
    for (AVCaptureDevice *device in devices) {
        
        if (([device hasMediaType:AVMediaTypeVideo]) && ([device position] == AVCaptureDevicePositionBack) ) {
            
            [device lockForConfiguration:&error];
            /*
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device setExposureMode:AVCaptureExposureModeLocked];
            }
            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
            }
            if ([device isLowLightBoostSupported]) {
                [device setAutomaticallyEnablesLowLightBoostWhenAvailable:false];
            }
            */
            if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
                device.focusMode = AVCaptureFocusModeLocked;
            }
            
        }
        
    }
    
    [device unlockForConfiguration];
    
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