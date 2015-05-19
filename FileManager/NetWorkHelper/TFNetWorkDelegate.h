//
//  TFNetWorkDelegate.h
//  FileManagerDemo
//
//  Created by Melvin on 4/27/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TFResponseInfo;

typedef void (^TFInternalProgressBlock)(long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^TFCompleteBlock)(TFResponseInfo *info, NSDictionary *resp);
typedef BOOL (^TFCancelBlock)(void);

/**
 *    Http 客户端接口
 */
@protocol TFNetWorkDelegate <NSObject>

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock
      withCancelBlock:(TFCancelBlock)cancelBlock;

- (void)post:(NSString *)url withData:(NSData *)data withParams:(NSDictionary *)params
 withHeaders:(NSDictionary *)headers
withCompleteBlock:(TFCompleteBlock)completeBlock
withProgressBlock:(TFInternalProgressBlock)progressBlock
withCancelBlock:(TFCancelBlock)cancelBlock;

@end
