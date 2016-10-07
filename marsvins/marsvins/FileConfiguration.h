//
//  FileConfiguration.h
//  marsvins
//
//  Created by Christopher Cobar on 10/5/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileConfiguration : NSObject

@property (nonatomic) bool is640;

@property (nonatomic) NSString *dataPathImages;
@property (nonatomic) NSString *dataPathImagesTimeStamps;

//@property (nonatomic) NSString *dataPathImagesFront;
//@property (nonatomic) NSString *dataPathImagesFrontTimestamps;

@property (nonatomic) NSString *dataPathIMU;
@property (nonatomic) NSString *dataPathIMUTimeStamps;
@property (nonatomic) NSString *dataPathIMUATimeStamps;
@property (nonatomic) NSString *dataPathIMUGTimeStamps;

@property (nonatomic) NSString *dataPathImages1280;
@property (nonatomic) NSString *dataPathImagesTimeStamps1280;

@property (nonatomic) NSFileHandle *fileHandlerImages;
@property (nonatomic) NSFileHandle *fileHandlerImagesTimeStamps;

//@property (nonatomic) NSFileHandle *fileHandlerImagesFront;
//@property (nonatomic) NSFileHandle *fileHandlerImagesFrontTimestamps;

@property (nonatomic) NSFileHandle *fileHandlerIMUTimeStamps;
@property (nonatomic) NSFileHandle *fileHandlerIMUATimeStamps;
@property (nonatomic) NSFileHandle *fileHandlerIMUGTimeStamps;

@property (nonatomic) NSFileHandle *fileHandlerImages1280;
@property (nonatomic) NSFileHandle *fileHandlerImagesTimeStamps1280;

//from documents directory
- (instancetype)init: (bool) is640;

- (void)setupSubdirectoryFileWriting;

@end
