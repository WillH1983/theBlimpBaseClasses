//
//  TwitterConversationTableViewController.m
//  theBlimpBaseClasses
//
//  Created by Will Hindenburg on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterConversationTableViewController.h"
#import "NSMutableDictionary+appConfiguration.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@interface TwitterConversationTableViewController ()

@end

@implementation TwitterConversationTableViewController
@synthesize tweetForConversation = _tweetForConversation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)loadTwitterData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicator.hidesWhenStopped = YES;
        [self.activityIndicator startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    });
    
    //  First, we create a dictionary to hold our request parameters
    
    NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/show/%@.json", [self.tweetForConversation valueForKeyPath:TWEET_ID]];
    NSURL *url = [NSURL URLWithString:retweetString];
    [self twitterGetRequestWithURL:url twitterParameters:nil withRequestType:TWRequestTypeGetTweetsForConversation];
}

- (void)twitterGetRequestWithURL:(NSURL *)url twitterParameters:(NSMutableDictionary *)parms withRequestType:(TWRequestType)requestType
{
    //  Now we can create our request.  Note that we are performing a GET request.
    TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                             parameters:parms 
                                          requestMethod:TWRequestMethodGET];
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    if (twitterAccountType.accessGranted) 
    {
        NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
        request.account = [twitterAccounts objectAtIndex:0];
    }
    else return;
    
    //  Perform our request
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        //  Use the NSJSONSerialization class to parse the returned JSON
        NSError *jsonError;
        id timeline = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        
        if (timeline) 
        {
            // We have an object that we can parse
            if ([timeline valueForKey:@"error"] != nil && [timeline isKindOfClass:[NSDictionary class]])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ - Twitter", self.appConfiguration.appName] 
                                                                        message:[timeline valueForKey:@"error"] 
                                                                       delegate:nil 
                                                              cancelButtonTitle:@"Okay" 
                                                              otherButtonTitles: nil];
                    [alertView show];
                });
            }
            else if (requestType == TWRequestTypeGetTweetsForConversation)
            {
                if ([timeline isKindOfClass:[NSDictionary class]])
                {
                    [self.twitterTableData insertObject:timeline atIndex:0];
                    id tweetId = [timeline valueForKey:TWEET_IN_REPLY_ID];
                    if (tweetId != [NSNull null])
                    {
                        NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/show/%@.json", tweetId];
                        NSURL *url = [NSURL URLWithString:retweetString];
                        [self twitterGetRequestWithURL:url twitterParameters:nil withRequestType:TWRequestTypeGetTweetsForConversation];
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                            [self.activityIndicator stopAnimating];
                        });
                    }
                    
                }
            }
            else if (requestType == TWRequestTypeRemoveRetweet)
            {
                if ([timeline isKindOfClass:[NSDictionary class]])
                {
                    NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/destroy/%@.json", [timeline valueForKeyPath:USER_RETWEETED_ID]];
                    NSURL *url = [NSURL URLWithString:retweetString];
                    [self twitterPostRequestWithURL:url twitterParameters:nil withRequestType:TWRequestTypeRemoveRetweet];
                }
            }
        } 
        else 
        { 
            // Inspect the contents of jsonError
            NSLog(@"%@", jsonError);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
        });
    }]; 
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

@end
