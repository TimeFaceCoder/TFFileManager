//
//  TFFormUpload.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFFormUpload.h"
#import "TFFileUploaderManager.h"
#import "TFFileManagerUtility.h"
#import "TFConfig.h"
#import "TFResponseInfo.h"
#import "TFUploadOption+Private.h"
#import "TFRecorderDelegate.h"

@interface TFFormUpload ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) id <TFNetWorkDelegate> httpManager;
@property (nonatomic) int retryTimes;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) TFUploadOption *option;
@property (nonatomic, strong) TFUpCompletionHandler complete;


@end

@implementation TFFormUpload

- (instancetype)initWithData:(NSData *)data
                     withKey:(NSString *)key
                   withToken:(NSString *)token
       withCompletionHandler:(TFUpCompletionHandler)block
                  withOption:(TFUploadOption *)option
             withHttpManager:(id <TFNetWorkDelegate> )http {
    if (self = [super init]) {
        _data = data;
        _key = key;
        _token = token;
        _option = option != nil ? option : [TFUploadOption defaultOptions];
        _complete = block;
        _httpManager = http;
    }
    return self;
}

- (void)put {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *fileName = _key;
    if (_key) {
        parameters[@"key"] = _key;
    }
    else {
        fileName = @"?";
    }
    
    parameters[@"token"] = _token;
    
    [parameters addEntriesFromDictionary:_option.params];
    
    if (_option.checkMd5) {
        parameters[@"md5"] = [NSString stringWithFormat:@"%u", (unsigned int)[TFFileManagerUtility getMD5StringFromNSData:_data]];
    }
    
    TFInternalProgressBlock p = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        if (percent > 0.95) {
            percent = 0.95;
        }
        _option.progressHandler(_key, percent);
    };
    
    
    TFCompleteBlock complete = ^(TFResponseInfo *info, NSDictionary *resp)
    {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
        if (info.isOK || !info.couldRetry) {
            _complete(info, _key, resp);
            return;
        }
        NSString *nextHost = kTFUpHost;
        if (info.isConnectionBroken || info.needSwitchServer) {
            nextHost = kTFUpHostBackup;
        }
        
        TFCompleteBlock retriedComplete = ^(TFResponseInfo *info, NSDictionary *resp) {
            if (info.isOK) {
                _option.progressHandler(_key, 1.0);
            }
            _complete(info, _key, resp);
        };
        
        [_httpManager multipartPost:nextHost
                           withData:_data
                         withParams:parameters
                       withFileName:fileName
                       withMimeType:_option.mimeType
                  withCompleteBlock:retriedComplete
                  withProgressBlock:p
                    withCancelBlock:nil];
    };
    
    [_httpManager multipartPost:kTFUpHost
                       withData:_data
                     withParams:parameters
                   withFileName:fileName
                   withMimeType:_option.mimeType
              withCompleteBlock:complete
              withProgressBlock:p
                withCancelBlock:nil];
}

@end
