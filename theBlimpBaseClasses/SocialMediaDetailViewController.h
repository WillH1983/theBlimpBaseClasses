//
//  SocialMediaDetailViewController.h
//  ImagoDei
//
//  Created by Will Hindenburg on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "TextEntryViewController.h"

typedef void(^SocialMediaDetailCompletionBlock)(void);

@class SocialMediaDetailViewController;

@interface SocialMediaDetailViewController : UITableViewController <TextEntryDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property (nonatomic, strong) NSDictionary *shortCommentsDictionaryModel;
@property (nonatomic, strong) NSDictionary *fullCommentsDictionaryModel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIBarButtonItem *oldBarButtonItem;

@end
