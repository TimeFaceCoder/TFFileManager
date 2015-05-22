//
//  TFFileUploaderManager.h
//  FileManagerDemo
//
//  Created by Melvin on 4/23/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFRecorderDelegate.h"

@class TFResponseInfo;
@class TFUploadOption;


/**
 *    上传完成后的回调函数
 *
 *    @param info 上下文信息，包括状态码，错误值
 *    @param key  上传时指定的key，原样返回
 *    @param resp 上传成功会返回文件信息，失败为nil; 可以通过此值是否为nil 判断上传结果
 */
typedef void (^TFUpCompletionHandler)(TFResponseInfo *info, NSString *key, NSDictionary *resp);

/**
 *  检查文件是否需要上传
 *
 *  @param fileList 需要上传的文件MD5数组
 */
typedef void (^TFCheckFileCompletionHandler)(NSArray *fileList);

@interface TFFileUploaderManager : NSObject
/**
 *    方便使用的单例方法
 *
 *    @param recorder             持久化记录接口实现
 *
 *    @return 上传管理类实例
 */
+ (instancetype)sharedInstanceWithRecorder:(id <TFRecorderDelegate> )recorder;

/**
 *    直接上传数据
 *
 *    @param data              待上传的数据
 *    @param token             上传需要的token, 由服务器生成
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
- (void)uploadData:(NSData *)data
          token:(NSString *)token
       complete:(TFUpCompletionHandler)completionHandler
         option:(TFUploadOption *)option;

/**
 *    上传文件
 *
 *    @param filePath          文件路径
 *    @param token             上传需要的token, 由服务器生成
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
- (void)uploadFile:(NSString *)filePath
          token:(NSString *)token
       complete:(TFUpCompletionHandler)completionHandler
         option:(TFUploadOption *)option;

/**
 *  检查上传文件
 *
 *  @param md5List           待检查的MD5数组
 *  @param sizeList
 *  @param token             上传需要的token,由服务器生成
 *  @param completionHandler 检查完成后的回调函数
 */
- (void)checkFile:(NSArray *)md5List
         sizeList:(NSArray *)sizeList
            token:(NSString *)token
         complete:(TFCheckFileCompletionHandler)completionHandler;


@end
