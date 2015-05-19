//
//  TFSessionManager.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFNetWorkDelegate.h"

@interface TFSessionManager : NSObject<TFNetWorkDelegate>

- (instancetype)initWithProxy:(NSDictionary *)proxyDict;

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock
      withCancelBlock:(TFCancelBlock)cancelBlock;

- (void)         post:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
          withHeaders:(NSDictionary *)headers
    withCompleteBlock:(TFCompleteBlock)completeBlock
    withProgressBlock:(TFInternalProgressBlock)progressBlock
      withCancelBlock:(TFCancelBlock)cancelBlock;

@end
