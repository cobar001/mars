//
//  AccelGyroMeasurement.m
//  marsvins
//
//  Created by Christopher Cobar on 8/4/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import "IMUMeasurement.h"

@implementation IMUMeasurement

- (instancetype)init: (double) timeStamp
                gyro: (GyroData *) gyroMeasurement
               accel: (AccelData *) accelMeasurement {
    
    self = [super init];
    
    if (self) {
        
        self.timeStamp = timeStamp;
        self.gyroMeasurement = gyroMeasurement;
        self.accelMeasurement = accelMeasurement;
        
    } else {
        
        self = nil;
        
    }
    
    return self;
    
}

- (NSString *)toString {
    
    return [NSString stringWithFormat:@"%f 0 %f %f %f %f %f %f 0 0 0",
            self.timeStamp,
            self.gyroMeasurement.rotationX,
            self.gyroMeasurement.rotationY,
            self.gyroMeasurement.rotationZ,
            self.accelMeasurement.accelerationX,
            self.accelMeasurement.accelerationY,
            self.accelMeasurement.accelerationZ];
    
}

@end
