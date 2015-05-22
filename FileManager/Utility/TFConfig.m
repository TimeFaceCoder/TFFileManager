//
//  TFConfig.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFConfig.h"

NSString *const kTFUpHost = @"http://192.168.10.100:8082/tfupload/upload";

NSString *const kTFUpHostBackup = @"http://192.168.10.100:8082/tfupload/upload";

NSString *const kUploadManagerKey = @"TIMEFACE_UPLOAD_KEY";

const UInt32 kTFChunkSize = 256 * 1024;

const UInt32 kTFBlockSize = 4 * 1024 * 1024;

const UInt32 kTFPutThreshold = 512 * 1024;

const UInt32 kTFRetryMax = 3;

const float kTFTimeoutInterval = 60.0;

