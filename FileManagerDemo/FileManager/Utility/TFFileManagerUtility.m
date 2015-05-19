//
//  TFFileManagerUtility.m
//  FileManagerDemo
//
//  Created by Melvin on 5/5/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFFileManagerUtility.h"
#import <UIKit/UIKit.h>
#import <arpa/inet.h>
#import <zlib.h>
#import "TFConfig.h"
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>



void TFAsyncRun(TFRun run) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        run();
    });
}


static NSString *clientId(void) {
    long long now_timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    int r = arc4random() % 1000;
    return [NSString stringWithFormat:@"%lld%u", now_timestamp, r];
}

NSString *TFUserAgent(void) {
    return [NSString stringWithFormat:@"TimeFace/%@ (%@; iOS %@; %@)", kTFFileManagerVersion, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], clientId()];
}



#define FileHashDefaultChunkSizeForReadingData 1024*8

static uint8_t const kBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static NSArray *getAddresses(CFHostRef hostRef) {
    Boolean lookup = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL);
    if (!lookup) {
        return nil;
    }
    CFArrayRef addresses = CFHostGetAddressing(hostRef, &lookup);
    if (!lookup) {
        return nil;
    }
    
    char buf[32];
    __block NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    // Iterate through the records to extract the address information
    struct sockaddr_in *remoteAddr;
    for (int i = 0; i < CFArrayGetCount(addresses); i++) {
        CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
        remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
        
        if (remoteAddr != NULL) {
            const char *p = inet_ntop(AF_INET, &(remoteAddr->sin_addr), buf, 32);
            NSString *ip = [NSString stringWithUTF8String:p];
            [ret addObject:ip];
            NSLog(@"Resolved %u->%@", i, ip);
        }
    }
    return ret;
}


@implementation TFFileManagerUtility

+ (NSString *)encodeString:(NSString *)sourceString {
    NSData *data = [NSData dataWithBytes:[sourceString UTF8String] length:[sourceString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    return [self encodeData:data];
}

+ (NSString *)encodeData:(NSData *)data {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kBase64EncodingTable[(value >> 6) & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kBase64EncodingTable[(value >> 0) & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

+ (NSArray *)getAddresses:(NSString *)hostName {
    // Convert the hostname into a StringRef
    CFStringRef hostNameRef = CFStringCreateWithCString(kCFAllocatorDefault, [hostName UTF8String], kCFStringEncodingASCII);
    
    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostNameRef);
    NSArray *ret = getAddresses(hostRef);
    
    CFRelease(hostRef);
    CFRelease(hostNameRef);
    return ret;
}

+ (NSString *)getAddressesString:(NSString *)hostName {
    NSArray *result = [TFFileManagerUtility getAddresses:hostName];
    if (result == nil || result.count == 0) {
        return @"";
    }
    return [result componentsJoinedByString:@";"];
}

+ (NSString *)getMD5StringFromNSString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [TFFileManagerUtility getMD5StringFromNSData:data];
}

+ (NSString *)getMD5StringFromNSData:(NSData *)data {
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([data bytes], (CC_LONG)[data length], digest);
    NSMutableString *result = [NSMutableString string];
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat: @"%02x", (int)(digest[i])];
    }
    return [result copy];
}

+ (NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path,
                                                                   FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

@end
