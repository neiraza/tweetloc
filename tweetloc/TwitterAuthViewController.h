//
//  TwitterAuthViewController.h
//  tweetloc_sample
//
//  Created by togu on 2014/02/18.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterAuthViewController : UIViewController <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *tweetMap;

- (IBAction)authenticate;
@end
