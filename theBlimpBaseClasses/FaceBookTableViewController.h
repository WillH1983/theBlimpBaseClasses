//
//  FaceBookTableViewController.h
//  TPM
//
//  Created by Will Hindenburg on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SocialMediaDetailViewController.h"
#import "TextEntryViewController.h"
#import "PullRefreshTableViewController.h"

@interface FaceBookTableViewController : PullRefreshTableViewController <TextEntryDelegate>

@property (nonatomic, strong) NSArray *facebookArrayTableData;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIBarButtonItem *oldBarButtonItem;
@property (nonatomic, strong) NSString *userNameID;
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void) closeSession;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logInOutButton;

#define FBSessionStateChangedNotification @"com.example.Login:FBSessionStateChangedNotification"
#define FACEBOOK_CONTENT_TITLE @"message"
#define FACEBOOK_CONTENT_DESCRIPTION @"from.name"

@end
