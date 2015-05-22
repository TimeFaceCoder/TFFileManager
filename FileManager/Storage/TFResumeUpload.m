//
//  TFResumeUpload.m
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFResumeUpload.h"
#import "TFFileUploaderManager.h"
#import "TFFileManagerUtility.h"
#import "TFConfig.h"
#import "TFResponseInfo.h"
#import "TFUploadOption+Private.h"
#import "TFRecorderDelegate.h"


typedef void (^task)(void);

@interface TFResumeUpload ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) id <TFNetWorkDelegate> httpManager;
@property UInt32 size;
@property (nonatomic) int retryTimes;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *recorderKey;
@property (nonatomic) NSDictionary *headers;
@property (nonatomic, strong) TFUploadOption *option;
@property (nonatomic, strong) TFUpCompletionHandler complete;
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;

@property int64_t modifyTime;
@property (nonatomic, strong) id <TFRecorderDelegate> recorder;

@property (nonatomic, strong) NSString *chunkMD5;


- (void)makeBlock:(NSString *)uphost
           offset:(UInt32)offset
        blockSize:(UInt32)blockSize
        chunkSize:(UInt32)chunkSize
         progress:(TFInternalProgressBlock)progressBlock
         complete:(TFCompleteBlock)complete;

- (void)putChunk:(NSString *)uphost
          offset:(UInt32)offset
            size:(UInt32)size
        progress:(TFInternalProgressBlock)progressBlock
        complete:(TFCompleteBlock)complete;

- (void)makeFile:(NSString *)uphost
        complete:(TFCompleteBlock)complete;

@end


@implementation TFResumeUpload

- (instancetype)initWithData:(NSData *)data
                    withSize:(UInt32)size
                     withKey:(NSString *)key
                   withToken:(NSString *)token
       withCompletionHandler:(TFUpCompletionHandler)block
                  withOption:(TFUploadOption *)option
              withModifyTime:(NSDate *)time
                withRecorder:(id <TFRecorderDelegate> )recorder
             withRecorderKey:(NSString *)recorderKey
             withHttpManager:(id <TFNetWorkDelegate> )http {
    if (self = [super init]) {
        _data = data;
        _size = size;
        _key = key;
        _option = option != nil ? option : [TFUploadOption defaultOptions];
        _complete = block;
        _headers = @{ @"uploadToken":token, @"Content-Type":@"application/octet-stream" };
        _recorder = recorder;
        _httpManager = http;
        if (time != nil) {
            _modifyTime = [time timeIntervalSince1970];
        }
        _recorderKey = recorderKey;
    }
    return self;
}

- (void)record:(UInt32)offset {
    NSString *key = self.recorderKey;
    if (offset == 0 || _recorder == nil || key == nil || [key isEqualToString:@""]) {
        return;
    }
    NSNumber *n_size = @(self.size);
    NSNumber *n_offset = @(offset);
    NSNumber *n_time = [NSNumber numberWithLongLong:_modifyTime];
    NSMutableDictionary *rec = [NSMutableDictionary dictionaryWithObjectsAndKeys:n_size, @"size", n_offset, @"offset", n_time, @"modify_time", nil];
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:rec options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"up record json error %@ %@", key, error);
        return;
    }
    error = [_recorder set:key data:data];
    if (error != nil) {
        NSLog(@"up record set error %@ %@", key, error);
    }
}

- (void)removeRecord {
    if (_recorder == nil) {
        return;
    }
    [_recorder del:self.recorderKey];
}

- (UInt32)recoveryFromRecord {
    NSString *key = self.recorderKey;
    if (_recorder == nil || key == nil || [key isEqualToString:@""]) {
        return 0;
    }
    
    NSData *data = [_recorder get:key];
    if (data == nil) {
        return 0;
    }
    
    NSError *error;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error != nil) {
        NSLog(@"recovery error %@ %@", key, error);
        [_recorder del:self.key];
        return 0;
    }
    NSNumber *n_offset = info[@"offset"];
    NSNumber *n_size = info[@"size"];
    NSNumber *time = info[@"modify_time"];
    if (n_offset == nil || n_size == nil || time == nil) {
        return 0;
    }
    
    UInt32 offset = [n_offset unsignedIntValue];
    UInt32 size = [n_size unsignedIntValue];
    if (offset > size || size != self.size) {
        return 0;
    }
    UInt64 t = [time unsignedLongLongValue];
    if (t != _modifyTime) {
        NSLog(@"modify time changed %llu, %llu", t, _modifyTime);
        return 0;
    }
    return offset;
}

- (void)nextTask:(UInt32)offset retriedTimes:(int)retried host:(NSString *)host {
    if (self.isCancelled) {
        self.complete([TFResponseInfo cancel], self.key, nil);
        return;
    }
    
    if (offset == self.size) {
        TFCompleteBlock completionHandler = ^(TFResponseInfo *info, NSDictionary *resp) {
            if (info.isOK) {
                [self removeRecord];
                self.option.progressHandler(self.key, 1.0);
            }
            else if (info.couldRetry && retried < kTFRetryMax) {
                [self nextTask:offset retriedTimes:retried + 1 host:host];
                return;
            }
            self.complete(info, self.key, resp);
        };
        [self makeFile:host complete:completionHandler];
        return;
    }
    
    UInt32 chunkSize = [self calcPutSize:offset];
    TFInternalProgressBlock progressBlock = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percent = (float)(offset + totalBytesWritten) / (float)self.size;
        if (percent > 0.95) {
            percent = 0.95;
        }
        self.option.progressHandler(self.key, percent);
    };
    
    TFCompleteBlock completionHandler = ^(TFResponseInfo *info, NSDictionary *resp) {
        if (info.error != nil) {
            if (info.statusCode == 701) {
                [self nextTask:(offset / kTFBlockSize) * kTFBlockSize retriedTimes:0 host:host];
                return;
            }
            if (retried >= kTFRetryMax || !info.couldRetry) {
                self.complete(info, self.key, resp);
                return;
            }
            
            NSString *nextHost = host;
            if (info.isConnectionBroken || info.needSwitchServer) {
                nextHost = kTFUpHostBackup;
            }
            
            [self nextTask:offset retriedTimes:retried + 1 host:nextHost];
            return;
        }
        
        if (resp == nil) {
            [self nextTask:offset retriedTimes:retried host:host];
            return;
        }
        NSString *md5 = resp[@"md5"];
        if (md5 == nil || ![md5 isEqualToString:_chunkMD5]) {
            [self nextTask:offset retriedTimes:retried host:host];
            return;
        }
        [self record:offset + chunkSize];
        [self nextTask:offset + chunkSize retriedTimes:retried host:host];
    };
    if (offset % kTFBlockSize == 0) {
        UInt32 blockSize = [self calcBlockSize:offset];
        [self makeBlock:host offset:offset blockSize:blockSize chunkSize:chunkSize progress:progressBlock complete:completionHandler];
        return;
    }
    [self putChunk:host offset:offset size:chunkSize progress:progressBlock complete:completionHandler];
}

- (UInt32)calcPutSize:(UInt32)offset {
    UInt32 left = self.size - offset;
    return left < kTFChunkSize ? left : kTFChunkSize;
}

- (UInt32)calcBlockSize:(UInt32)offset {
    UInt32 left = self.size - offset;
    return left < kTFBlockSize ? left : kTFBlockSize;
}

- (UInt32)calcBlockIndex:(UInt32)offset blockSize:(UInt32)blockSize {
    UInt32 blockIndex = offset/blockSize;
    if (blockSize < kTFBlockSize) {
        blockIndex = offset/kTFBlockSize;
    }
    return blockIndex;
}

- (UInt32)calcChunkIndex:(UInt32)offset blockIndex:(UInt32)blockIndex size:(UInt32)size {
    UInt32 newoffset = offset;
    if (newoffset>kTFBlockSize) {
        newoffset -= blockIndex * kTFBlockSize;
    }
    UInt32 chunkIndex = newoffset/size;
    if (size < kTFChunkSize) {
        chunkIndex = newoffset/kTFChunkSize;
    }
    return chunkIndex;
}


- (void)makeBlock:(NSString *)uphost
           offset:(UInt32)offset
        blockSize:(UInt32)blockSize
        chunkSize:(UInt32)chunkSize
         progress:(TFInternalProgressBlock)progressBlock
         complete:(TFCompleteBlock)complete {
    NSData *data = [self.data subdataWithRange:NSMakeRange(offset, (unsigned int)chunkSize)];
    UInt32 blockIndex = [self calcBlockIndex:offset blockSize:blockSize];
    NSString *url = [[NSString alloc] initWithFormat:@"%@/mkblock/%u-%u", uphost, (unsigned int)blockSize,(unsigned int)blockIndex];
    NSLog(@"url:%@",url);
    _chunkMD5 = [TFFileManagerUtility getMD5StringFromNSData:data];
    
    [self post:url withData:data withCompleteBlock:complete withProgressBlock:progressBlock];
}

- (void)putChunk:(NSString *)uphost
          offset:(UInt32)offset
            size:(UInt32)size
        progress:(TFInternalProgressBlock)progressBlock
        complete:(TFCompleteBlock)complete {
    NSData *data = [self.data subdataWithRange:NSMakeRange(offset, (unsigned int)size)];
    UInt32 chunkOffset = offset % kTFBlockSize;
    UInt32 blockIndex = offset/kTFBlockSize;
    UInt32 chunkIndex = [self calcChunkIndex:offset blockIndex:blockIndex size:size];
    
    NSString *url = [[NSString alloc] initWithFormat:@"%@/putblock/%u-%u-%U", uphost, (unsigned int)chunkOffset,(unsigned int)blockIndex,(unsigned int)chunkIndex];
    NSLog(@"url:%@",url);
    _chunkMD5 = [TFFileManagerUtility getMD5StringFromNSData:data];
    [self post:url withData:data withCompleteBlock:complete withProgressBlock:progressBlock];
}

- (BOOL)isCancelled {
    return self.option.priv_isCancelled;
}

- (void)makeFile:(NSString *)uphost
        complete:(TFCompleteBlock)complete {
    NSString *mime = [[NSString alloc] initWithFormat:@"/mimeType/%@", [TFFileManagerUtility encodeString:self.option.mimeType]];
    NSLog(@"mime:%@",mime);
    __block NSString *url = [[NSString alloc] initWithFormat:@"%@/mkfile/%u", uphost, (unsigned int)self.size];
    
    [self.option.params enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *obj, BOOL *stop) {
        url = [NSString stringWithFormat:@"%@/%@/%@", url, key, [TFFileManagerUtility encodeString:obj]];
    }];
    NSMutableData *postData = [NSMutableData data];
    [self post:url withData:postData withCompleteBlock:complete withProgressBlock:nil];
}

- (void)         post:(NSString *)url
             withData:(NSData *)data
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock {
    [_httpManager post:url withData:data withParams:nil withHeaders:_headers withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:nil];
}

- (void)run {
    @autoreleasepool {
        UInt32 offset = [self recoveryFromRecord];
        [self nextTask:offset retriedTimes:0 host:kTFUpHost];
    }
}

@end
