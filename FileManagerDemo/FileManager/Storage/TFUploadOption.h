//
//  TFUploadOption.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *    上传进度回调函数
 *
 *    @param key     上传时指定的存储key
 *    @param percent 进度百分比
 */
typedef void (^TFUpProgressHandler)(NSString *key, float percent);

/**
 *    上传中途取消函数
 *
 *    @return 如果想取消，返回True, 否则返回No
 */
typedef BOOL (^TFUpCancellationSignal)(void);


@interface TFUploadOption : NSObject

/**
 *    用于服务器上传回调通知的自定义参数，参数的key必须以t开头
 */
@property (copy, nonatomic, readonly) NSDictionary *params;

/**
 *    指定文件的mime类型
 */
@property (copy, nonatomic, readonly) NSString *mimeType;

/**
 *    是否进行md5校验
 */
@property (readonly) BOOL checkMd5;

/**
 *    回调函数
 */
@property (copy, readonly) TFUpProgressHandler progressHandler;

/**
 *    取消函数
 */
@property (copy, readonly) TFUpCancellationSignal cancellationSignal;


/**
 *  上传参数初始化
 *
 *  @param mimeType     mime类型
 *  @param progress     进度回调
 *  @param params       自定义参数回调
 *  @param check        是否进行md5校验
 *  @param cancellation 取消回调
 *
 *  @return TFUploadOption
 */
- (instancetype)initWithMime:(NSString *)mimeType
             progressHandler:(TFUpProgressHandler)progress
                      params:(NSDictionary *)params
                    checkMD5:(BOOL)check
          cancellationSignal:(TFUpCancellationSignal)cancellation;

/**
 *  上传参数初始化
 *
 *  @param progress 进度回调
 *
 *  @return TFUploadOption
 */
- (instancetype)initWithProgessHandler:(TFUpProgressHandler)progress;

+ (instancetype)defaultOptions;

@end
