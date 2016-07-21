//
//  VinsViewController.h
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VinsViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (strong,nonatomic) CMMotionManager *manager; //IMU

@property (strong,nonatomic) AVCaptureSession *imageCaptureSession; //camera in

@property (strong, nonatomic) AVCaptureVideoDataOutput *imageOutput; //camera out

- (void)startCameraSession;

- (void)showIMULabels:(BOOL)areShowing;

- (void)getIMUValues:(NSTimer *)timer;

@end
