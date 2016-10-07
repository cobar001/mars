//
//  FileConfiguration.m
//  marsvins
//
//  Created by Christopher Cobar on 10/5/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import "FileConfiguration.h"

@implementation FileConfiguration


- (instancetype)init: (bool)is640 {
    
    self = [super init];
    
    if (self) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        self.is640 = is640;
        
        self.dataPathImages = [documentsDirectory stringByAppendingPathComponent:@"/Images"];
        self.dataPathImagesTimeStamps = [self.dataPathImages stringByAppendingPathComponent:@"/timestamps.txt"];
        
        self.dataPathIMU = [documentsDirectory stringByAppendingPathComponent:@"/IMU"];
        self.dataPathIMUTimeStamps = [self.dataPathIMU stringByAppendingPathComponent:@"/imu.txt"];
        self.dataPathIMUATimeStamps = [self.dataPathIMU stringByAppendingPathComponent:@"/imuAccelTimestamps.txt"];
        self.dataPathIMUGTimeStamps = [self.dataPathIMU stringByAppendingPathComponent:@"/imuGyroTimestamps.txt"];
        
        self.dataPathImages1280 = [documentsDirectory stringByAppendingPathComponent:@"/Images1280"];
        self.dataPathImagesTimeStamps1280 = [self.dataPathImages1280 stringByAppendingPathComponent:@"/timestamps.txt"];
        
        //self.fileHandlerImagesTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathImagesTimeStamps];
        //self.fileHandlerImagesTimeStamps1280 = [NSFileHandle fileHandleForWritingAtPath:self.dataPathImagesTimeStamps1280];
        
        //self.fileHandlerIMUTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUTimeStamps];
        //self.fileHandlerIMUATimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUATimeStamps];
        //self.fileHandlerIMUGTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUGTimeStamps];
        
    } else {
        
        self = nil;
        
    }
    
    return self;
    
}

- (void)setupSubdirectoryFileWriting {
    
    NSError *error;
    
    //use these declarations to create folders at each viewDidLoad, essentially starting over each time
    
    //delete contents each time for testing sake
    if ([self is640]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:self.dataPathImages error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:self.dataPathImagesTimeStamps error:nil];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:self.dataPathImages withIntermediateDirectories:NO attributes:nil error:&error]; //Create Images folder
        [[NSFileManager defaultManager] createFileAtPath:self.dataPathImagesTimeStamps contents:nil attributes:nil]; //Create Images/timestamps.txt

        self.fileHandlerImagesTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathImagesTimeStamps];
        
    } else {
        
        [[NSFileManager defaultManager] removeItemAtPath:self.dataPathImages1280 error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:self.dataPathImagesTimeStamps1280 error:nil];

        [[NSFileManager defaultManager] createDirectoryAtPath:self.dataPathImages1280 withIntermediateDirectories:NO attributes:nil error:&error];
        [[NSFileManager defaultManager] createFileAtPath:self.dataPathImagesTimeStamps1280 contents:nil attributes:nil];
        
        self.fileHandlerImagesTimeStamps1280 = [NSFileHandle fileHandleForWritingAtPath:self.dataPathImagesTimeStamps1280];
        
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:self.dataPathIMU error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.dataPathIMUTimeStamps error:nil]; //for combo
    [[NSFileManager defaultManager] removeItemAtPath:self.dataPathIMUATimeStamps error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.dataPathIMUGTimeStamps error:nil];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:self.dataPathIMU withIntermediateDirectories:NO attributes:nil error:&error]; //Create IMU folder
    [[NSFileManager defaultManager] createFileAtPath:self.dataPathIMUTimeStamps contents:nil attributes:nil]; //Create IMU/imuTimestamps
    [[NSFileManager defaultManager] createFileAtPath:self.dataPathIMUATimeStamps contents:nil attributes:nil]; //Create IMU/acceltimestamps.txt
    [[NSFileManager defaultManager] createFileAtPath:self.dataPathIMUGTimeStamps contents:nil attributes:nil]; //Create IMU/gyrotimestamps.txt
    
    self.fileHandlerIMUTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUTimeStamps];
    self.fileHandlerIMUGTimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUGTimeStamps];
    self.fileHandlerIMUATimeStamps = [NSFileHandle fileHandleForWritingAtPath:self.dataPathIMUATimeStamps];
    
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

- (void)writeToPath: (NSFileHandle *)fileHandle data: (NSString *) data {
    
}

@end
