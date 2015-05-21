//
//  TFFileUploaderManager.m
//  FileManagerDemo
//
//  Created by Melvin on 4/23/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFFileUploaderManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import "TFConfig.h"
#import "TFSessionManager.h"
#import "TFResponseInfo.h"
#import "TFResumeUpload.h"
#import "TFFormUpload.h"
#import "TFUploadOption+Private.h"
#import "TFFileManagerUtility.h"


@interface TFFileUploaderManager ()
@property (nonatomic) id <TFNetWorkDelegate> httpManager;
@property (nonatomic) id <TFRecorderDelegate> recorder;
@end

@implementation TFFileUploaderManager

- (instancetype)init {
    return [self initWithRecorder:nil];
}

- (instancetype)initWithRecorder:(id <TFRecorderDelegate> )recorder {
    if (self = [super init]) {
        _httpManager = [[TFSessionManager alloc] initWithProxy:nil];
        
        _recorder = recorder;
    }
    return self;
}


+ (instancetype)sharedInstanceWithRecorder:(id <TFRecorderDelegate> )recorder {
    static TFFileUploaderManager *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithRecorder:recorder];
    });
    
    return sharedInstance;
}

+ (BOOL)checkAndNotifyError:(NSString *)key
                      token:(NSString *)token
                       data:(NSData *)data
                       file:(NSString *)file
                   complete:(TFUpCompletionHandler)completionHandler {
    NSString *desc = nil;
    if (completionHandler == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"no completionHandler" userInfo:nil];
        return YES;
    }
    if (data == nil && file == nil) {
        desc = @"no input data";
    }
    else if (token == nil || [token isEqualToString:@""]) {
        desc = @"no token";
    }
    if (desc != nil) {
        TFAsyncRun( ^{
            completionHandler([TFResponseInfo responseInfoWithInvalidArgument:desc], key, nil);
        });
        return YES;
    }
    return NO;
}

+ (BOOL)checkAndNotifyError:(NSString *)key
                      token:(NSString *)token
                       file:(NSString *)file
                   complete:(TFCheckFileCompletionHandler)completionHandler {
    NSString *desc = nil;
    if (completionHandler == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"no completionHandler" userInfo:nil];
        return YES;
    }
    else if (token == nil || [token isEqualToString:@""]) {
        desc = @"no token";
    }
    if (desc != nil) {
        TFAsyncRun( ^{
            completionHandler(nil);
        });
        return YES;
    }
    return NO;
}

- (void)uploadData:(NSData *)data
          token:(NSString *)token
       complete:(TFUpCompletionHandler)completionHandler
         option:(TFUploadOption *)option {
    if ([TFFileUploaderManager checkAndNotifyError:kUploadManagerKey token:token data:data file:nil complete:completionHandler]) {
        return;
    }
    TFFormUpload *up = [[TFFormUpload alloc]
                        initWithData:data
                        withKey:kUploadManagerKey
                        withToken:token
                        withCompletionHandler:completionHandler
                        withOption:option
                        withHttpManager:_httpManager];
    TFAsyncRun( ^{
        [up put];
    });
}

- (void)uploadFile:(NSString *)filePath
          token:(NSString *)token
       complete:(TFUpCompletionHandler)completionHandler
         option:(TFUploadOption *)option {
    if ([TFFileUploaderManager checkAndNotifyError:kUploadManagerKey token:token data:nil file:filePath complete:completionHandler]) {
        return;
    }
    
    @autoreleasepool {
        NSError *error = nil;
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        
        if (error) {
            TFAsyncRun( ^{
                TFResponseInfo *info = [TFResponseInfo responseInfoWithFileError:error];
                completionHandler(info, kUploadManagerKey, nil);
            });
            return;
        }
        
        NSNumber *fileSizeNumber = fileAttr[NSFileSize];
        UInt32 fileSize = [fileSizeNumber intValue];
        NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            TFAsyncRun( ^{
                TFResponseInfo *info = [TFResponseInfo responseInfoWithFileError:error];
                completionHandler(info, kUploadManagerKey, nil);
            });
            return;
        }
        if (fileSize <= kTFPutThreshold) {
            [self uploadData:data token:token complete:completionHandler option:option];
            return;
        }
        
        TFUpCompletionHandler complete = ^(TFResponseInfo *info, NSString *key, NSDictionary *resp)
        {
            completionHandler(info, key, resp);
        };
        
        NSDate *modifyTime = fileAttr[NSFileModificationDate];
        NSString *recorderKey = [TFFileManagerUtility getMD5StringFromNSString:[kUploadManagerKey stringByAppendingString:[filePath lastPathComponent]]];
        NSLog(@"recorderKey:%@",recorderKey);
        TFResumeUpload *up = [[TFResumeUpload alloc]
                              initWithData:data
                              withSize:fileSize
                              withKey:kUploadManagerKey
		                            withToken:token
                              withCompletionHandler:complete
                              withOption:option
                              withModifyTime:modifyTime
                              withRecorder:_recorder
                              withRecorderKey:recorderKey
                              withHttpManager:_httpManager];
        TFAsyncRun( ^{
            [up run];
        });
    }
}


- (void)checkFile:(NSArray *)md5List
         sizeList:(NSArray *)sizeList
            token:(NSString *)token
         complete:(TFCheckFileCompletionHandler)completionHandler {
    if ([TFFileUploaderManager checkAndNotifyError:kUploadManagerKey token:token  file:nil complete:completionHandler]) {
        return;
    }
    __block NSString *url = [[NSString alloc] initWithFormat:@"%@/check/", kTFUpHost];
    
    NSString *sizeListString = [sizeList componentsJoinedByString:@","];
    NSString *md5ListString = [md5List componentsJoinedByString:@","];
    
    
    [_httpManager post:url
              withData:nil
            withParams:@{@"sizeList":sizeListString,@"md5List":md5ListString}
           withHeaders:nil
     withCompleteBlock:^(TFResponseInfo *info, NSDictionary *resp) {
         NSArray *checksum = resp[@"checksum"];
         completionHandler(checksum);
    } withProgressBlock:NULL
       withCancelBlock:NULL];
}

@end
