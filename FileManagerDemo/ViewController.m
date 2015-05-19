//
//  ViewController.m
//  FileManagerDemo
//
//  Created by Melvin on 4/23/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import "ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "TFFileManagerKit.h"

@interface ViewController ()<TFRecorderDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    dispatch_queue_t queue = dispatch_queue_create("cn.timeface.uploadimage.queue", DISPATCH_QUEUE_SERIAL);
//    dispatch_group_t group = dispatch_group_create();
//    dispatch_group_async(group, queue, ^{
//        [NSThread sleepForTimeInterval:1];
//        NSLog(@"group1");
//    });
//    dispatch_group_async(group, queue, ^{
//        [NSThread sleepForTimeInterval:1];
//        NSLog(@"group2");
//    });
//    dispatch_group_async(group, queue, ^{
//        [NSThread sleepForTimeInterval:1];
//        NSLog(@"group3");
//    });
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"updateUi"); 
//    });
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
//        dispatch_group_t group = dispatch_group_create();
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
//        dispatch_queue_t queue = dispatch_queue_create("cn.timeface.uploadimage.queue", DISPATCH_QUEUE_SERIAL);
//        for (int i = 0; i < 9; i++){
//            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//            dispatch_group_async(group, queue, ^{
//                int time = arc4random_uniform(5);
//                NSLog(@"%i time:%@",i,@(time));
//                sleep(time);
//                dispatch_semaphore_signal(semaphore);
//            });
//        }
//        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//        NSLog(@"group over");
//    });
    
  
//    dispatch_release(group);
//    dispatch_release(semaphore);
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"Yosemite" withExtension:@"jpg"];
//
    NSString *md5 = [TFFileManagerUtility getFileMD5WithPath:[sourceURL path]];
//
    NSLog(@"md5:%@ TIME:%@",md5,@([[NSDate date] timeIntervalSince1970] - currentTime));

    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startUpload:(id)sender {
    NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"Yosemite" withExtension:@"jpg"];
    
    TFUploadOption *option = [[TFUploadOption alloc] initWithMime:@"image/JPEG"
                                                  progressHandler:^(NSString *key, float percent)
                              {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [SVProgressHUD showProgress:percent];
                                      _progressView.progress = percent;
                                  });
                                  
                              }
                                                           params:@{@"sPath":@"E:\\temp",
                                                                    @"sName":@"demo.file"}
                                                         checkMD5:NO
                                               cancellationSignal:NULL];
//
//    [manager putData:[NSData dataWithContentsOfFile:[sourceURL path]]
//               token:@"token"
//            complete:^(TFResponseInfo *info, NSString *key, NSDictionary *resp)
//    {
//        NSLog(@"");
//    } option:option];
    
    [[TFFileUploaderManager sharedInstanceWithRecorder:self] uploadFile:[sourceURL path]
               token:@"token"
            complete:^(TFResponseInfo *info, NSString *key, NSDictionary *resp)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    } option:option];
    
    
    
}

#pragma mark - TFRecorderDelegate

- (NSError *)set:(NSString *)key
            data:(NSData *)value {
    return nil;
}

- (NSData *)get:(NSString *)key {
    return nil;
}
- (NSError *)del:(NSString *)key {
    return nil;
}

@end
