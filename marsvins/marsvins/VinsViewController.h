//
//  VinsViewController.h
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>

@interface VinsViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (nonatomic) CMMotionManager *manager; //IMU

@property (nonatomic) AVCaptureSession *imageCaptureSession; //camera in

@property (nonatomic) AVCaptureVideoDataOutput *imageOutput; //camera out

@property (nonatomic) AVCaptureConnection *captureConnection; //connection

@property (nonatomic) NSLock *gyroLock;

@property (nonatomic) NSLock *accelLock;

@property (nonatomic, readwrite) bool is640;

- (void)startCameraSession;

@end
