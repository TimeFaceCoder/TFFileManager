//
//  TFUploaderOperation+Private.h
//  FileManagerDemo
//
//  Created by Melvin on 4/28/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "TFUploadOption.h"

@interface TFUploadOption (Private)

@property (nonatomic, getter = priv_isCancelled, readonly) BOOL cancelled;

@end
