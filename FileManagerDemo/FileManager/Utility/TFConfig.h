//
//  TFConfig.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *    默认上传服务器
 */
extern NSString *const kTFUpHost;

/**
 *    备用上传服务器，当默认服务器网络连接失败时使用
 */
extern NSString *const kTFUpHostBackup;

extern NSString *const kUploadManagerKey;

/**
 *    断点上传时的分片大小
 */
extern const UInt32 kTFChunkSize;

/**
 *    断点上传时的分块大小
 */
extern const UInt32 kTFBlockSize;

/**
 *    上传失败的重试次数
 */
extern const UInt32 kTFRetryMax;

/**
 *    如果大于此值就使用断点上传，否则使用form上传
 */
extern const UInt32 kTFPutThreshold;

/**
 *    超时时间
 */
extern const float kTFTimeoutInterval;
