//
//  TFUploadOption.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFUploadOption+Private.h"
#import "TFFileUploaderManager.h"

static NSString *mime(NSString *mimeType) {
    if (mimeType == nil || [mimeType isEqualToString:@""]) {
        return @"application/octet-stream";
    }
    return mimeType;
}

@implementation TFUploadOption

+ (NSDictionary *)filteParam:(NSDictionary *)params {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if (params == nil) {
        return ret;
    }
    
    [params enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *obj, BOOL *stop) {
        if ([key hasPrefix:@"t:"] && ![obj isEqualToString:@""]) {
            ret[key] = obj;
        }
    }];
    
    return ret;
}

- (instancetype)initWithProgessHandler:(TFUpProgressHandler)progress {
    return [self initWithMime:nil withFileName:nil progressHandler:progress params:nil checkMD5:NO cancellationSignal:nil];
}

- (instancetype)initWithMime:(NSString *)mimeType
                withFileName:(NSString *)fileName
             progressHandler:(TFUpProgressHandler)progress
                      params:(NSDictionary *)params
                    checkMD5:(BOOL)check
          cancellationSignal:(TFUpCancellationSignal)cancel {
    if (self = [super init]) {
        _mimeType = mime(mimeType);
        _fileName = fileName;
        _progressHandler = progress != nil ? progress : ^(NSString *key, float percent) {
        };
        _params = [TFUploadOption filteParam:params];
        _checkMd5 = check;
        _cancellationSignal = cancel != nil ? cancel : ^BOOL () {
            return NO;
        };
    }
    
    return self;
}

- (BOOL)priv_isCancelled {
    return _cancellationSignal && _cancellationSignal();
}

+ (instancetype)defaultOptions {
    return [[TFUploadOption alloc] initWithMime:nil withFileName:nil progressHandler:nil params:nil checkMD5:NO cancellationSignal:nil];
}


@end
