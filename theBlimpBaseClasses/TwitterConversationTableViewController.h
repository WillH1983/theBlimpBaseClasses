//
//  TwitterConversationTableViewController.h
//  theBlimpBaseClasses
//
//  Created by Will Hindenburg on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterTableViewController.h"
#import "PullRefreshTableViewController.h"

@interface TwitterConversationTableViewController : TwitterTableViewController

@property (nonatomic, strong) NSDictionary *tweetForConversation;

@end
