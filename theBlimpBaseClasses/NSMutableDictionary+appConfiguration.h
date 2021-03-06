//
//  NSMutableDictionary+appConfiguration.h
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (appConfiguration)
@property (nonatomic, strong) NSURL *RSSlink;
@property (nonatomic, strong) NSString *defaultLocalPathImageForTableViewCell;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *facebookID;
@property (nonatomic, strong) NSString *facebookFeedToRequest;
@property (nonatomic, strong) NSString *twitterUserNameToRequest;
@property (nonatomic, strong) NSString *facebookCommentButtonImageTitle;
@property (nonatomic, strong) NSString *appNavigationBarLogoName;
@end
