//
//  NSMutableDictionary+appConfiguration.m
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSMutableDictionary+appConfiguration.h"

@implementation NSMutableDictionary (appConfiguration)

- (void)setRSSlink:(NSURL *)RSSlink
{
    [self setObject:RSSlink forKey:@"RSSLink"];
}

- (NSURL *)RSSlink
{
    return [self objectForKey:@"RSSLink"];
}

- (void)setDefaultLocalPathImageForTableViewCell:(NSString *)defaultLocalPathImageForTableViewCell
{
    [self setObject:defaultLocalPathImageForTableViewCell forKey:@"defaultLocalPathImageForTableViewCell"];
}

- (NSString *)defaultLocalPathImageForTableViewCell
{
    return [self objectForKey:@"defaultLocalPathImageForTableViewCell"];
}

- (void)setAppName:(NSString *)appName
{
    [self setObject:appName forKey:@"appName"];
}

- (NSString *)appName
{
    return [self objectForKey:@"appName"];
}

- (void)setFacebookID:(NSString *)facebookID
{
    [self setObject:facebookID forKey:@"facebookID"];
}

- (NSString *)facebookID
{
    return [self objectForKey:@"facebookID"];
}

- (void)setFacebookFeedToRequest:(NSString *)facebookFeedToRequest
{
    [self setObject:facebookFeedToRequest forKey:@"facebookFeedToRequest"];
}

- (NSString *)facebookFeedToRequest
{
    return [self objectForKey:@"facebookFeedToRequest"];
}

- (void)setTwitterUserNameToRequest:(NSString *)twitterUserNameToRequest
{
    [self setObject:twitterUserNameToRequest forKey:@"twitterUserNameToRequest"];
}

- (NSString *)twitterUserNameToRequest
{
    return [self objectForKey:@"twitterUserNameToRequest"];
}

- (void)setFacebookCommentButtonImageTitle:(NSString *)facebookCommentButtonImageTitle
{
    [self setObject:facebookCommentButtonImageTitle forKey:@"facebookCommentButtonImageTitle"];
}

- (NSString *)facebookCommentButtonImageTitle
{
    return [self objectForKey:@"facebookCommentButtonImageTitle"];
}

@end
