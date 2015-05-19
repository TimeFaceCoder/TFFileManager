//
//  TFResumeUpload.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFFileUploaderManager.h"
#import "TFNetWorkDelegate.h"

@class TFHttpManager;
@interface TFResumeUpload : NSObject

- (instancetype)initWithData:(NSData *)data
                    withSize:(UInt32)size
                     withKey:(NSString *)key
                   withToken:(NSString *)token
       withCompletionHandler:(TFUpCompletionHandler)block
                  withOption:(TFUploadOption *)option
              withModifyTime:(NSDate *)time
                withRecorder:(id <TFRecorderDelegate> )recorder
             withRecorderKey:(NSString *)recorderKey
             withHttpManager:(id <TFNetWorkDelegate> )http;

- (void)run;

@end
