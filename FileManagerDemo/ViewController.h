//
//  ViewController.h
//  FileManagerDemo
//
//  Created by Melvin on 4/23/15.
//  Copyright (c) 2015 TimeFace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) IBOutlet UIButton *checkButton;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
- (IBAction)startUpload:(id)sender;
- (IBAction)checkFile:(id)sender;

@end

