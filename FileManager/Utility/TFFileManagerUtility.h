//
//  TFFileManagerUtility.h
//  FileManagerDemo
//
//  Created by Melvin on 5/5/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^TFRun)(void);

void TFAsyncRun(TFRun run);

NSString *TFUserAgent(void);

static const NSString *kTFFileManagerVersion = @"0.0.1";

@interface TFFileManagerUtility : NSObject
/**
 *  字符串编码
 *
 *  @param source 字符串
 *
 *  @return NSString
 */
+ (NSString *)encodeString:(NSString *)source;

/**
 *  NSData编码
 *
 *  @param source NSData
 *
 *  @return NSString
 */
+ (NSString *)encodeData:(NSData *)source;

+ (NSArray *)getAddresses:(NSString *)hostName;

+ (NSString *)getAddressesString:(NSString *)hostName;

/**
 *  字符串MD5
 *
 *  @param string 字符串
 *
 *  @return NSString
 */
+ (NSString *)getMD5StringFromNSString:(NSString *)string;

/**
 *  NSData MD5
 *
 *  @param data NSData
 *
 *  @return NSString
 */
+ (NSString *)getMD5StringFromNSData:(NSData *)data;
/**
 *  文件MD5
 *
 *  @param path 文件路径
 *
 *  @return NSString
 */
+ (NSString *)getFileMD5WithPath:(NSString*)path;


@end
