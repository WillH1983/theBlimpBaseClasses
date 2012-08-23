//
//  TwitterTableViewController.h
//  TPM
//
//  Created by Will Hindenburg on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"

enum TWRequestType {
    TWRequestTypeRetweet,
    TWRequestTypeRemoveRetweet,
    TWRequestTypeTweet,
    TWRequestTypeGetTimeline,
    TWRequestTypeGetTweetsForConversation
};

typedef enum TWRequestType TWRequestType;

@interface TwitterTableViewController : PullRefreshTableViewController

@property (nonatomic, strong) NSMutableArray *twitterTableData;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSMutableDictionary *appConfiguration;

- (void)twitterPostRequestWithURL:(NSURL *)url twitterParameters:(NSMutableDictionary *)parms withRequestType:(TWRequestType)requestType;

- (void)twitterGetRequestWithURL:(NSURL *)url twitterParameters:(NSMutableDictionary *)parms withRequestType:(TWRequestType)requestType;

#define TWITTER_TWEET @"text"
#define TWITTER_NAME @"user.name"
#define TWITTER_SCREEN_NAME @"user.screen_name"
#define TWITTER_PROFILE_IMAGE @"user.profile_image_url"
#define TWITTER_SCREEN_NAME @"user.screen_name"
#define TWITTER_POSTED_DATE @"created_at"
#define TWEET_ID @"id_str"
#define TWEET_RETWEETED @"retweeted"
#define USER_RETWEETED_ID @"current_user_retweet.id_str"
#define TWEET_IN_REPLY_ID @"in_reply_to_status_id_str"

@end
