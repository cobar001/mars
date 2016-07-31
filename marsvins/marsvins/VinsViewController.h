//
//  VinsViewController.h
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface VinsViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (nonatomic) CMMotionManager *manager; //IMU

@property (nonatomic) AVCaptureSession *imageCaptureSession; //camera in

@property (nonatomic) AVCaptureVideoDataOutput *imageOutput; //camera out

@property (nonatomic) AVCaptureConnection *captureConnection; //connection

- (void)startCameraSession;

- (void)showIMULabels:(BOOL)areShowing;

- (void)getIMUValues;

@end
