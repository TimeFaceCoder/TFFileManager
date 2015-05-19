//
//  TFResponseInfo.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *    中途取消的状态码
 */
extern const int kTFRequestCancelled;

/**
 *    网络错误状态码
 */
extern const int kTFNetworkError;

/**
 *    错误参数状态码
 */
extern const int kTFInvalidArgument;

/**
 *    读取文件错误状态码
 */
extern const int kTFFileError;

@interface TFResponseInfo : NSObject

/**
 *    状态码
 */
@property (readonly) int statusCode;
/**
 *    错误信息，出错时请反馈此记录
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 *    服务器域名
 */
@property (nonatomic, copy, readonly) NSString *host;

/**
 *    请求消耗的时间，单位 秒
 */
@property (nonatomic, readonly) double duration;

/**
 *    服务器IP
 */
@property (nonatomic, readonly) NSString *serverIp;

/**
 *    网络类型
 */
//@property (nonatomic, readonly) NSString *networkType;

/**
 *    是否取消
 */
@property (nonatomic, readonly, getter = isCancelled) BOOL canceled;

/**
 *    成功的请求
 */
@property (nonatomic, readonly, getter = isOK) BOOL ok;

/**
 *    是否网络错误
 */
@property (nonatomic, readonly, getter = isConnectionBroken) BOOL broken;

/**
 *    是否需要重试，内部使用
 */
@property (nonatomic, readonly) BOOL couldRetry;

/**
 *    是否需要换备用server，内部使用
 */
@property (nonatomic, readonly) BOOL needSwitchServer;


+ (instancetype)cancel;

+ (instancetype)responseInfoWithInvalidArgument:(NSString *)desc;

+ (instancetype)responseInfoWithNetError:(NSError *)error
                                    host:(NSString *)host
                                duration:(double)duration;

+ (instancetype)responseInfoWithFileError:(NSError *)error;

- (instancetype)init:(int)status
            withHost:(NSString *)host
        withDuration:(double)duration
            withBody:(NSData *)body;

@end
