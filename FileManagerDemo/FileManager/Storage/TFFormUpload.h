//
//  TFFormUpload.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFFileUploaderManager.h"
#import "TFNetWorkDelegate.h"

@class TFHttpManager;

@interface TFFormUpload : NSObject

- (instancetype)initWithData:(NSData *)data
                     withKey:(NSString *)key
                   withToken:(NSString *)token
       withCompletionHandler:(TFUpCompletionHandler)block
                  withOption:(TFUploadOption *)option
             withHttpManager:(id <TFNetWorkDelegate> )http;

- (void)put;

@end
