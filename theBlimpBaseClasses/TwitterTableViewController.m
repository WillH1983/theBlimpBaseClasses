//
//  TwitterTableViewController.m
//  TPM
//
//  Created by Will Hindenburg on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterTableViewController.h"
#import "UITextView+Facebook.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "WebViewController.h"
#import "NSMutableDictionary+appConfiguration.h"
#import "NSDate+Generic.h"
#import "TwitterConversationTableViewController.h"
#import "TextEntryViewController.h"

@interface TwitterTableViewController () <UIActionSheetDelegate, TextEntryDelegate>
@property (nonatomic, strong) UITableViewCell *twitterCell;
@property (nonatomic, strong) NSDictionary *tweetToRetweet;
@property (nonatomic, strong) ACAccount *twitterAccount;

- (void)retweetButtonPressed:(id)sender;

@end

@implementation TwitterTableViewController
@synthesize twitterTableData = _twitterTableData;
@synthesize activityIndicator = _activityIndicator;
@synthesize appConfiguration = _appConfiguration;
@synthesize twitterCell = _twitterCell;
@synthesize tweetToRetweet = _tweetToRetweet;
@synthesize twitterAccount = _twitterAccount;

- (NSMutableArray *)twitterTableData
{
    if (!_twitterTableData) _twitterTableData = [[NSMutableArray alloc] init];
    return _twitterTableData;
}

- (UITableViewCell *)twitterCell
{
    if (!_twitterCell) _twitterCell = [self.tableView dequeueReusableCellWithIdentifier:@"twitterCell"];
    return _twitterCell;
}

- (void)setTwitterTableData:(NSMutableArray *)twitterTableData
{
    _twitterTableData = twitterTableData;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentWebView:) 
                                                 name:@"urlSelected"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"urlSelected" object:nil];
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
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self.appConfiguration.twitterUserNameToRequest forKey:@"screen_name"];
    [params setObject:@"20" forKey:@"count"];
    [params setObject:@"1" forKey:@"include_rts"];
    
    //  Next, we create an URL that points to the target endpoint
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/user_timeline.json"];
    
    [self twitterGetRequestWithURL:url twitterParameters:params withRequestType:TWRequestTypeGetTimeline];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    id appDelegate = (id)[[UIApplication sharedApplication] delegate];
    self.appConfiguration = [appDelegate appConfiguration];
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if (!granted) 
        {
            // The user rejected your request 
            NSLog(@"User rejected access to the account.");
        } 
        else 
        {
            NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
            if ([twitterAccounts count] > 0)
            {
                self.twitterAccount = [twitterAccounts objectAtIndex:0];
                [self loadTwitterData];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *tmpString = @"Please create a Twitter Account in your iOS settings to continue";
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[NSString alloc] initWithFormat:@"%@ - Twitter", self.appConfiguration.appName] message:tmpString delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                    [alertView show];
                });
            }
            
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.twitterTableData count];
}

- (void)twitterPostRequestWithURL:(NSURL *)url twitterParameters:(NSMutableDictionary *)parms withRequestType:(TWRequestType)requestType
{
    
    TWRequest *request = [[TWRequest alloc] initWithURL:url
                                             parameters:parms
                                          requestMethod:TWRequestMethodPOST];
    
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
    NSError *jsonError;
    NSArray *timeline = [NSJSONSerialization JSONObjectWithData:responseData 
                                                        options:NSJSONReadingMutableLeaves 
                                                          error:&jsonError];
    
    if (timeline) 
    {
        // We have an object that we can parse
        if ([timeline valueForKey:@"error"])
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
        else 
        {
            if (requestType == TWRequestTypeRetweet)
            {
                id retweetedID = [timeline valueForKeyPath:@"retweeted_status.id"];
                if ([retweetedID isKindOfClass:[NSNumber class]])
                {
                    for (int i = 0; i < [self.twitterTableData count]; i++)
                    {
                        NSDictionary *items = [self.twitterTableData objectAtIndex:i];
                        if ([[items valueForKey:@"id"] isEqualToNumber:retweetedID])
                        {
                            NSMutableDictionary *mutableItems = [items mutableCopy];
                            [mutableItems setValue:[NSNumber numberWithInt:1] forKey:TWEET_RETWEETED];
                            [self.twitterTableData replaceObjectAtIndex:i withObject:[mutableItems copy]];
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                        [self.activityIndicator stopAnimating];
                    });
                }
            }
            else if (requestType == TWRequestTypeRemoveRetweet)
            {
                id retweetedID = [timeline valueForKeyPath:@"retweeted_status.id"];
                if ([retweetedID isKindOfClass:[NSNumber class]])
                {
                    for (int i = 0; i < [self.twitterTableData count]; i++)
                    {
                        NSDictionary *items = [self.twitterTableData objectAtIndex:i];
                        if ([[items valueForKey:@"id"] isEqualToNumber:retweetedID])
                        {
                            NSMutableDictionary *mutableItems = [items mutableCopy];
                            [mutableItems setValue:[NSNumber numberWithInt:0] forKey:TWEET_RETWEETED];
                            [self.twitterTableData replaceObjectAtIndex:i withObject:[mutableItems copy]];
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.activityIndicator stopAnimating];
                });
            }
            else if (requestType == TWRequestTypeTweet)
            {
                NSLog(@"%@", timeline);
            }
        }
    } 
    else 
    { 
        // Inspect the contents of jsonError
        NSLog(@"%@", jsonError);
    }
}]; 
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
            else if (requestType == TWRequestTypeGetTimeline)
            {
                if ([timeline isKindOfClass:[NSArray class]])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.twitterTableData = [timeline mutableCopy];
                        [self.activityIndicator stopAnimating];
                    });
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
    }]; 
}

- (void)retweetButtonPressed:(id)sender
{
    UIButton *retweetButton = sender;
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.twitterTableData objectAtIndex:indexPath.row];
    
    if ([retweetButton.titleLabel.text isEqualToString:@"Retweet"])
    {
        self.tweetToRetweet = dictionaryData;
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Retweet this to your followers - %@", [dictionaryData valueForKeyPath:TWITTER_TWEET]]
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Retweet", nil];
        
        // Show the sheet
        [sheet showFromTabBar:self.tabBarController.tabBar];
    }
    else 
    {
        [self.activityIndicator startAnimating];
        
        //  First, we create a dictionary to hold our request parameters
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:@"1" forKey:@"include_my_retweet"];
        
        NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/show/%@.json", [dictionaryData objectForKey:TWEET_ID]];
        NSURL *url = [NSURL URLWithString:retweetString];
        [self twitterGetRequestWithURL:url twitterParameters:params withRequestType:TWRequestTypeRemoveRetweet];
    }
    
}

- (void)viewConversationButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSDictionary *cellDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"twitterConversation" sender:cellDictionary];
}

- (void)replyButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSDictionary *cellDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"twitterReply" sender:cellDictionary];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet firstOtherButtonIndex] == buttonIndex)
    {
        [self.activityIndicator startAnimating];
        
        NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/retweet/%@.json", [self.tweetToRetweet objectForKey:TWEET_ID]];
        NSURL *url = [NSURL URLWithString:retweetString];
        [self twitterPostRequestWithURL:url twitterParameters:nil withRequestType:TWRequestTypeRetweet];
        self.tweetToRetweet = nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"twitterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *postedBy = (UILabel *)[cell.contentView viewWithTag:2];
    UITextView *tweetText = (UITextView *)[cell.contentView viewWithTag:3];
    UILabel *twitterScreenName = (UILabel *)[cell.contentView viewWithTag:4];
    UILabel *postedDate = (UILabel *)[cell.contentView viewWithTag:5];
    UIButton *retweetButton = (UIButton *)[cell.contentView viewWithTag:6];
    [retweetButton addTarget:self action:@selector(retweetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *viewConversationButton = (UIButton *)[cell.contentView viewWithTag:7];
    [viewConversationButton addTarget:self action:@selector(viewConversationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *replyButton = (UIButton *)[cell.contentView viewWithTag:8];
    [replyButton addTarget:self action:@selector(replyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *tweetDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    
    NSNumber *user_retweeted = [tweetDictionary valueForKeyPath:TWEET_RETWEETED];
    if ([user_retweeted boolValue])
    {
        [retweetButton setTitle:@"Retweeted" forState:UIControlStateNormal];
    }
    else
    {
        [retweetButton setTitle:@"Retweet" forState:UIControlStateNormal];
    }
    
    id replyID = [tweetDictionary valueForKey:TWEET_IN_REPLY_ID];
    if (replyID != [NSNull null])
    {
        [viewConversationButton setTitle:@"View Conversation" forState:UIControlStateNormal];
        [viewConversationButton addTarget:self action:@selector(viewConversationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [viewConversationButton setTitle:nil forState:UIControlStateNormal];
        viewConversationButton.titleLabel.text = nil;
        [viewConversationButton removeTarget:self action:@selector(viewConversationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    
    postedBy.text = [tweetDictionary valueForKeyPath:TWITTER_NAME];
    NSString *screenName = [tweetDictionary valueForKeyPath:TWITTER_SCREEN_NAME];
    twitterScreenName.text = [NSString stringWithFormat:@"@%@", screenName];
    
    CGFloat oldHeight = tweetText.frame.size.height;
    tweetText.text = [tweetDictionary valueForKeyPath:TWITTER_TWEET];
    [tweetText resizeTextViewForWidth:self.tableView.frame.size.width - 30];
    CGFloat heightChange = tweetText.frame.size.height - oldHeight;

    retweetButton.frame = CGRectMake(retweetButton.frame.origin.x, retweetButton.frame.origin.y + heightChange, retweetButton.frame.size.width, retweetButton.frame.size.height);
    viewConversationButton.frame = CGRectMake(viewConversationButton.frame.origin.x, viewConversationButton.frame.origin.y + heightChange, viewConversationButton.frame.size.width, viewConversationButton.frame.size.height);
    replyButton.frame = CGRectMake(replyButton.frame.origin.x, replyButton.frame.origin.y + heightChange, replyButton.frame.size.width, replyButton.frame.size.height);
    NSDate *date = [[NSDate alloc] initTwitterDateFormatWithString:[tweetDictionary valueForKeyPath:TWITTER_POSTED_DATE]];
    postedDate.text = date.socialDate;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITextView *tweetText = (UITextView *)[self.twitterCell.contentView viewWithTag:3];
    tweetText.frame = CGRectMake(tweetText.frame.origin.x, tweetText.frame.origin.y, tweetText.frame.size.width, 25);
    //Set the cell text label's based upon the table contents array location
    UITextView *tweetText2 = (UITextView *)[self.twitterCell.contentView viewWithTag:3];
    
    NSDictionary *tweetDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    tweetText2.text = [tweetDictionary valueForKeyPath:TWITTER_TWEET];
    CGFloat oldHeight = tweetText.frame.size.height;
    [tweetText resizeTextViewForWidth:self.tableView.frame.size.width - 30];
    CGFloat heightChange = tweetText.frame.size.height - oldHeight;

    CGFloat height = self.twitterCell.frame.size.height + heightChange;
    
    return height;
}

- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *twitterDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    NSURL *profileImageURL = [NSURL URLWithString:[twitterDictionary valueForKeyPath:TWITTER_PROFILE_IMAGE]];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSData *picture = [NSData dataWithContentsOfURL:profileImageURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
            if ([tmpArray containsObject:indexPath])
            {
                UITableViewCell *cell = [tableview cellForRowAtIndexPath:indexPath];
                UIImageView *profileImageVIew = (UIImageView *)[cell.contentView viewWithTag:1];
                profileImageVIew.image = [UIImage imageWithData:picture];
            }
        });
    });
}

- (void) presentWebView:(NSNotification *) notification
{
    
    if ([[notification name] isEqualToString:@"urlSelected"])
    {
        [self performSegueWithIdentifier:@"Web" sender:[notification object]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Web"] & [sender isKindOfClass:[NSURL class]])
    {
        [segue.destinationViewController setUrlToLoad:sender];
    }
    else if ([segue.identifier isEqualToString:@"twitterConversation"])
    {
        [segue.destinationViewController setTweetForConversation:sender];
    }
    else if ([segue.identifier isEqualToString:@"twitterReply"])
    {
        [segue.destinationViewController setDictionaryForComment:sender];
        [segue.destinationViewController setSubmitButtonTitle:@"Reply"];
        [segue.destinationViewController setWindowTitle:@"Tweet Reply"];
        [segue.destinationViewController setTextEntryDelegate:self];
    }
}

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string withDictionary:(NSDictionary *)dictionary forType:(TextEntryType)type
{
    [self.activityIndicator startAnimating];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *tweetString = [NSString stringWithFormat:@"@%@ %@", [dictionary valueForKeyPath:TWITTER_SCREEN_NAME], string];
    [params setObject:tweetString forKey:@"status"];
    [params setObject:[dictionary valueForKey:TWEET_ID] forKey:@"in_reply_to_status_id"];
    
    //  Next, we create an URL that points to the target endpoint
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
    
    [self twitterPostRequestWithURL:url twitterParameters:params withRequestType:TWRequestTypeTweet];
}

- (void)textViewDidCancel:(UITextView *)textView
{
    [self.tableView reloadData];
}

@end
