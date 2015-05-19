//
//  TFResponseInfo.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFResponseInfo.h"
const int kTFFileError        = -4;
const int kTFInvalidArgument  = -3;
const int kTFRequestCancelled = -2;
const int kTFNetworkError     = -1;

static TFResponseInfo *cancelledInfo = nil;

static NSString *domain = @"timeface.cn";

@implementation TFResponseInfo

+ (instancetype)cancel {
    return [[TFResponseInfo alloc] initWithCancelled];
}

+ (instancetype)responseInfoWithInvalidArgument:(NSString *)text {
    return [[TFResponseInfo alloc] initWithStatus:kTFInvalidArgument errorDescription:text];
}

+ (instancetype)responseInfoWithNetError:(NSError *)error host:(NSString *)host duration:(double)duration {
    if (error.code != -1003) {
    }
    return [[TFResponseInfo alloc] initWithStatus:kTFNetworkError error:error host:host duration:duration];
}

+ (instancetype)responseInfoWithFileError:(NSError *)error {
    return [[TFResponseInfo alloc] initWithStatus:kTFFileError error:error];
}

- (instancetype)initWithCancelled {
    return [self initWithStatus:kTFRequestCancelled errorDescription:@"cancelled by user"];
}

- (instancetype)initWithStatus:(int)status
                         error:(NSError *)error {
    return [self initWithStatus:status error:error host:nil duration:0];
}

- (instancetype)initWithStatus:(int)status
                         error:(NSError *)error
                          host:(NSString *)host
                      duration:(double)duration {
    if (self = [super init]) {
        _statusCode = status;
        _error = error;
        _host = host;
        _duration = duration;
    }
    return self;
}

- (instancetype)initWithStatus:(int)status
              errorDescription:(NSString *)text {
    NSError *error = [[NSError alloc] initWithDomain:domain code:status userInfo:@{ @"error":text }];
    return [self initWithStatus:status error:error];
}

- (instancetype)init:(int)status
            withHost:(NSString *)host
        withDuration:(double)duration
            withBody:(NSData *)body {
    if (self = [super init]) {
        _statusCode = status;
        _host = [host copy];
        _duration = duration;
        if (status != 200) {
            if (body == nil) {
                _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:nil];
            }
            else {
                NSError *tmp;
                NSDictionary *uInfo = [NSJSONSerialization JSONObjectWithData:body options:NSJSONReadingMutableLeaves error:&tmp];
                if (tmp != nil) {
                    // 出现错误时，如果信息是非UTF8编码会失败，返回nil
                    NSString *str = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
                    if (str == nil) {
                        str = @"";
                    }
                    uInfo = @{ @"error": str };
                }
                _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:uInfo];
            }
        }
        else if (body == nil || body.length == 0) {
            NSDictionary *uInfo = @{ @"error":@"no response json" };
            _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:uInfo];
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, status: %d, host: %@ duration:%f s error: %@>", NSStringFromClass([self class]), self, _statusCode, _host, _duration, _error];
}

- (BOOL)isCancelled {
    return _statusCode == kTFRequestCancelled;
}

- (BOOL)isOK {
    return _statusCode == 200 && _error == nil;
}

- (BOOL)isConnectionBroken {
    return _statusCode == kTFNetworkError;
}

- (BOOL)needSwitchServer {
    return _statusCode == kTFNetworkError || (_statusCode / 100 == 5 && _statusCode != 579);
}

- (BOOL)couldRetry {
    return (_statusCode >= 500 && _statusCode < 600 && _statusCode != 579) || _statusCode == kTFNetworkError || _statusCode == 996 || _statusCode == 406 || (_statusCode == 200 && _error != nil);
}

@end
