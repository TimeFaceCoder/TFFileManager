//
//  TFSessionManager.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFSessionManager.h"
#import <AFNetworking/AFNetworking.h>
#import "TFConfig.h"
#import "TFResponseInfo.h"
#import "TFFileManagerUtility.h"

@interface TFProgessDelegate : NSObject
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
@property (nonatomic, strong) TFInternalProgressBlock progressBlock;
@property (nonatomic, strong) NSProgress *progress;
- (instancetype)initWithProgress:(TFInternalProgressBlock)progressBlock;
@end

@implementation TFProgessDelegate

- (instancetype)initWithProgress:(TFInternalProgressBlock)progressBlock {
    if (self = [super init]) {
        _progressBlock = progressBlock;
        _progress = nil;
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context; {
    if (context == nil || object == nil) {
        return;
    }
    
    NSProgress *progress = (NSProgress *)object;
    
    void *p = (__bridge void *)(self);
    if (p == context) {
        _progressBlock(progress.completedUnitCount, progress.totalUnitCount);
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@interface TFSessionManager ()
@property (nonatomic) AFHTTPSessionManager *httpManager;
@end

static NSString *userAgent = nil;

@implementation TFSessionManager

+ (void)initialize {
    userAgent = TFUserAgent();
}

- (instancetype)initWithProxy:(NSDictionary *)proxyDict {
    if (self = [super init]) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        if (proxyDict != nil) {
            configuration.connectionProxyDictionary = proxyDict;
        }
        _httpManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        _httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    
    return self;
}

+ (TFResponseInfo *)buildResponseInfo:(NSHTTPURLResponse *)response
                            withError:(NSError *)error
                         withDuration:(double)duration
                         withResponse:(NSData *)body
                             withHost:(NSString *)host {
    TFResponseInfo *info;
    
    if (response) {
        int status =  (int)[response statusCode];
        info = [[TFResponseInfo alloc] init:status withHost:host withDuration:duration withBody:body];
    }
    else {
        info = [TFResponseInfo responseInfoWithNetError:error host:host duration:duration];
    }
    return info;
}

- (void)  sendRequest:(NSMutableURLRequest *)request
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock {
    __block NSDate *startTime = [NSDate date];
    NSProgress *progress = nil;
    __block NSString *host = request.URL.host;
    
    if (progressBlock == nil) {
        progressBlock = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        };
    }
    __block TFProgessDelegate *delegate = [[TFProgessDelegate alloc] initWithProgress:progressBlock];
    
    NSURLSessionUploadTask *uploadTask = [_httpManager uploadTaskWithStreamedRequest:request
                                                                            progress:&progress
                                                                   completionHandler: ^(NSURLResponse *response, id responseObject, NSError *error)
    {
        NSData *data = responseObject;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        double duration = [[NSDate date] timeIntervalSinceDate:startTime];
        TFResponseInfo *info;
        NSDictionary *resp = nil;
        if (error == nil) {
            info = [TFSessionManager buildResponseInfo:httpResponse
                                             withError:nil
                                          withDuration:duration
                                          withResponse:data
                                              withHost:host];
            if (info.isOK) {
                NSError *tmp;
                resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&tmp];
            }
        }
        else {
            info = [TFSessionManager buildResponseInfo:httpResponse
                                             withError:error
                                          withDuration:duration
                                          withResponse:data
                                              withHost:host];
        }
        
        if (delegate.progress != nil) {
            [delegate.progress removeObserver:delegate forKeyPath:@"fractionCompleted" context:(__bridge void *)(delegate)];
            delegate.progress = nil;
        }
        completeBlock(info, resp);
    }];
    if (progress != nil) {
        [progress addObserver:delegate forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:(__bridge void *)delegate];
        delegate.progress = progress;
    }
    
    [request setTimeoutInterval:kTFTimeoutInterval];
    
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:nil forHTTPHeaderField:@"Accept-Language"];
    [uploadTask resume];
}

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)fileName
         withMimeType:(NSString *)mime
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock
      withCancelBlock:(TFCancelBlock)cancelBlock {
    NSMutableURLRequest *request = [_httpManager.requestSerializer
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:url
                                    parameters:params
                                    constructingBodyWithBlock: ^(id < AFMultipartFormData > formData) {
                                        if (data) {
                                            [formData appendPartWithFileData:data
                                                                        name:@"file"
                                                                    fileName:fileName
                                                                    mimeType:mime];
                                        }
                                    }
                                    
                                    error:nil];
    [self sendRequest:request
    withCompleteBlock:completeBlock
    withProgressBlock:progressBlock];
}

- (void)         post:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
          withHeaders:(NSDictionary *)headers
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock
      withCancelBlock:(TFCancelBlock)cancelBlock {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:url]];
    if (headers) {
        [request setAllHTTPHeaderFields:headers];
    }
    
    [request setHTTPMethod:@"POST"];
    
    if (params) {
        [request setValuesForKeysWithDictionary:params];
    }
    [request setHTTPBody:data];
    TFAsyncRun( ^{
        [self sendRequest:request
        withCompleteBlock:completeBlock
        withProgressBlock:progressBlock];
    });
}


@end
