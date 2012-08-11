//
//  FaceBookTableViewController.h
//  TPM
//
//  Created by Will Hindenburg on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Facebook.h"
#import "SocialMediaDetailViewController.h"
#import "ImagoDeiTextEntryViewController.h"

@interface FaceBookTableViewController : UITableViewController <FBSessionDelegate,FBRequestDelegate, FBDialogDelegate, SocialMediaDetailViewControllerDelegate, ImagoDeiTextEntryDelegate>

@property (nonatomic, strong) Facebook *facebook;
@property (nonatomic, strong) NSArray *facebookArrayTableData;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIBarButtonItem *oldBarButtonItem;
@property (nonatomic, strong) NSString *userNameID;

#define FACEBOOK_CONTENT_TITLE @"message"
#define FACEBOOK_CONTENT_DESCRIPTION @"from.name"

@end
