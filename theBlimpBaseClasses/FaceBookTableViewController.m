//
//  FaceBookTableViewController.m
//  TPM
//
//  Created by Will Hindenburg on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FaceBookTableViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "WebViewController.h"
#import "ImageViewController.h"
#import "UITextView+Facebook.h"
#import "NSMutableDictionary+appConfiguration.h"
#import "NSDate+Generic.h"

@interface FaceBookTableViewController ()
@property (nonatomic, strong) FBRequest *facebookRequest;
@property (nonatomic, strong) NSMutableDictionary *photoDictionary;
@property (nonatomic, strong) NSMutableDictionary *appConfiguration;
@property (nonatomic, strong) UITableViewCell *defaultFacebookCell;
@property (nonatomic, strong) UITableViewCell *facebookPhotoCell;

- (void)processPostPhotoRequestWithConnection:(FBRequestConnection *)connection
                                  withMessage:(NSString *)message
                                  withResults:(id)result
                                    postError:(NSError *)error;

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string
  withDictionary:(NSDictionary *)dictionary
        andImage:(UIImage *)image
         forType:(TextEntryType)type;

- (void)processGetFeedRequestWithConnection:(FBRequestConnection *)connection
                                withResults:(id)result
                                  postError:(NSError *)error;
- (void)processPostRequestWithConnection:(FBRequestConnection *)connection
                             withResults:(id)result
                               postError:(NSError *)error;

- (void)processPostPhotoRequestWithConnection:(FBRequestConnection *)connection
                                  withMessage:(NSString *)message
                                  withResults:(id)result
                                    postError:(NSError *)error;

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender
    dictionaryForFacebookGraphAPIString:(NSString *)facebookGraphAPIString;

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender
      postDataForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
                         withParameters:(NSMutableDictionary *)params;

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender
    deleteDataForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
                         withParameters:(NSMutableDictionary *)params;
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;

- (void)sessionStateChanged:(NSNotification*)notification;
- (IBAction)LogOutInButtonClicked:(id)sender;
- (void)commonInit;
- (NSString *)keyForDetailCellLabelText;
- (void)commentsButtonPushed:(id)sender;
- (void)postImageButtonPressed:(id)sender;
- (void)mainCommentsButtonPushed:(id)sender;
- (void)likeButtonPressed:(id)sender;
- (void)textViewDidCancel:(UITextView *)textView;
- (UIImage *)getScaledImage:(UIImage *)img insideButton:(UIButton *)btn;
- (void)determineCauseOfError:(NSError *)error;
- (void)presentWebView:(NSNotification *)notification;
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)closeSession;

@end

@implementation FaceBookTableViewController
@synthesize logInOutButton = _logInOutButton;
@synthesize facebookRequest = _facebookRequest;
@synthesize photoDictionary = _photoDictionary;
@synthesize facebookArrayTableData = _facebookArrayTableData;
@synthesize activityIndicator = _activityIndicator;
@synthesize oldBarButtonItem = _oldBarButtonItem;
@synthesize userNameID = _userNameID;
@synthesize appConfiguration = _appConfiguration;
@synthesize defaultFacebookCell = _defaultFacebookCell;
@synthesize facebookPhotoCell = _facebookPhotoCell;

- (NSMutableDictionary *)photoDictionary
{
    //Lazy Init for the photo dictionary
    if (!_photoDictionary) _photoDictionary = [[NSMutableDictionary alloc] init];
    return _photoDictionary;
}

- (UITableViewCell *)defaultFacebookCell
{
    //Lazy init for the default Facebook cell which allows for fast loading when determining cell height
    if (!_defaultFacebookCell)
    {
        _defaultFacebookCell = [self.tableView dequeueReusableCellWithIdentifier:@"defaultFacebookCell"];
    }
    return _defaultFacebookCell;
}

- (UITableViewCell *)facebookPhotoCell
{
    //Lazy init for the Facebook photo cell which allows for fast loading when determining cell height
    if (_facebookPhotoCell == nil)
    {
        _facebookPhotoCell = [self.tableView dequeueReusableCellWithIdentifier:@"photoFacebookCell"];
    }
    return _facebookPhotoCell;
}

- (void)setFacebookArrayTableData:(NSArray *)facebookArrayTableData
{
    _facebookArrayTableData = facebookArrayTableData;
    //Reload table data when the model changes
    [self.tableView reloadData];
}

- (NSArray *)facebookArrayTableData
{
    //Lazy init for the facebook table data
    if (!_facebookArrayTableData) _facebookArrayTableData = [[NSArray alloc] init];
    return _facebookArrayTableData;
}

- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) 
    {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        //Retrieve the left bar button item, and change the text to "Log Out"
        self.navigationItem.leftBarButtonItem.title = @"Log Out";
        
        //This method will request an array that contains information about the user that logged in
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //Retireve the User Defaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            //Save the facebook userID to NSUserDefaults
            [defaults setObject:[result valueForKey:@"id"] forKey:@"userNameID"];
            [defaults synchronize];
            
            //Populate the userNameID to the property
            self.userNameID = [result valueForKey:@"id"];
            
            //Configure the graph path to request based on the app configuration in app delegate
            NSString *graphPath = [NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest];
            
            //Request facebook feed
            [FBRequestConnection startWithGraphPath:graphPath completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                //Process completed feed request
                [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
                
                //Change UI to reflect that the user is logged in
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.logInOutButton.title = @"Log Out";
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                });
            }];
        }];
    }
    else
    {
        //If the session state changes to anything but open, set UI to reflect that the user is not logged in
        dispatch_async(dispatch_get_main_queue(), ^{
            self.logInOutButton.title = @"Login";
            self.navigationItem.rightBarButtonItem.enabled = NO;
        });
    }
}

- (IBAction)LogOutInButtonClicked:(id)sender 
{
    // If the user is authenticated, log out when the button is clicked.
    // If the user is not authenticated, log in when the button is clicked.
    if (FBSession.activeSession.isOpen) {
        [self closeSession];
    } else {
        // The user has initiated a login, so call the openSession method
        // and show the login UX if necessary.
        [self openSessionWithAllowLoginUI:YES];
    }
    
    
}

#pragma mark - View Lifecycle

- (void)commonInit
{
    //The table should not allow selection
    self.tableView.allowsSelection = NO;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self commonInit];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"urlSelected" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Retireve the User Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Pull the userNameID from the defaults
    self.userNameID = [defaults objectForKey:@"userNameID"];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    BOOL opened = [self openSessionWithAllowLoginUI:NO];
    if (!opened) self.navigationItem.rightBarButtonItem.enabled = NO;
    
    //initialize the activity indicator, start is animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicator.hidesWhenStopped = YES;
    
    //Save the previous rightBarButtonItem so it can be put back on once the View is done loading
    self.oldBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Pull the app delegate, this needs to be generic due to this class being included in other apps
    //Save the appConfiguration data from the app delegate
    id appDelegate = (id)[[UIApplication sharedApplication] delegate];
    self.appConfiguration = [appDelegate appConfiguration];
    
    //If the facebook session is already valid, the barButtonItem will be change to say "Log Out"
    if ([FBSession activeSession].isOpen) 
    {
        self.navigationItem.leftBarButtonItem.title = @"Log Out";
    }
    
    //Help to verify small data requirement
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //Begin the facebook request, the data that comes back form this method will be used
    //to populate the UITableView
    if ([self.facebookArrayTableData count] == 0)
    {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since this is the first time this view has appeared, the feed data will be requested, start the acitivity indicator
        [self.activityIndicator startAnimating];
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //Prcoess the feed response data
            [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
        }];
    }
    
    //When ever the view reappears, reload the table data.  This helps when the post entry view disappears
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Remove notifications after the view disappears
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentWebView:) 
                                                 name:@"urlSelected"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionStateChanged:)
                                                 name:FBSessionStateChangedNotification
                                               object:nil];
    
}

#pragma mark - Table view data source


- (NSString *)keyForDetailCellLabelText
{
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Return the tableview cell count
    return [self.facebookArrayTableData count];
}

- (NSDictionary *)dictionaryForSenderInsideCell:(id)sender
{
    //Walk up the view tree in order to find the cell dictionary
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [[NSDictionary alloc] init];
    if (indexPath) dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    if (dictionaryData) return dictionaryData;
    else return nil;
}

- (void)commentsButtonPushed:(id)sender
{
    //Find the cell dictionary corresponding to the view comments button pushed
    id dictionaryData = [self dictionaryForSenderInsideCell:sender];
    if (dictionaryData) [self performSegueWithIdentifier:@"detailView" sender:dictionaryData];
}

- (void)postImageButtonPressed:(id)sender
{
    //Find the cell dictionary corresponding to the comments button pushed
    id dictionaryData = [self dictionaryForSenderInsideCell:sender];
    if (dictionaryData) [self performSegueWithIdentifier:@"Photo" sender:dictionaryData];
}

- (void)mainCommentsButtonPushed:(id)sender
{
    //Find the cell dictionary corresponding to the comments button pushed
    id dictionaryData = [self dictionaryForSenderInsideCell:sender];
    if (dictionaryData) [self performSegueWithIdentifier:@"CommentOnPost" sender:dictionaryData];
}

- (void)likeButtonPressed:(id)sender
{
    //Find the cell dictionary corresponding to the like button pushed
    id dictionaryData = [self dictionaryForSenderInsideCell:sender];
    
    //If the data returned is not a dictionary, return without doing anything
    if (![dictionaryData isKindOfClass:[NSDictionary class]]) return;
    
    //Create the graphAPIString to like and unlike posts
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/likes", [dictionaryData valueForKeyPath:@"id"]];
    UIButton *likeButton = sender;

    if ([likeButton.titleLabel.text isEqualToString:@"Like"])
    {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        //Begin request to like a post
        [FBRequestConnection startWithGraphPath:graphAPIString
                                     parameters:nil
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //Process the post response
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        //Immediately set the button text to "Unlike", after the post is sent the response is checked, and the
        //table is reloaded.  After the reload the button may change back to "Like" if it is not successful
        [likeButton setTitle:@"Unlike" forState:UIControlStateNormal]; 
        
    }
    else {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        //Being the request to "Delete" a like, which is the same as "Unliking"
        [FBRequestConnection startWithGraphPath:graphAPIString
                                     parameters:[[NSMutableDictionary alloc] init]
                                     HTTPMethod:@"DELETE"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //Process the post request
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        //Immediately set the button text to "Like", after the post is sent the response is checked, and the
        //table is reloaded.  After the reload the button may change back to "Unlike" if it is not successful
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    
}

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string
  withDictionary:(NSDictionary *)dictionary
        andImage:(UIImage *)image
         forType:(TextEntryType)type
{
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook will be sending the comments data, including a
    //possible image, start animating the activity Indicator
    [self.activityIndicator startAnimating];
    
    NSString *graphAPIString = nil;
    
    //Init a parameter dictionary with the text from the textview
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:string, @"message", nil];
    
    //If the user intends to comment on a post
    if (type == TextEntryTypeComment)
    {
        //Init graphAPIString with the post ID
        graphAPIString = [NSString stringWithFormat:@"%@/comments", [dictionary valueForKeyPath:@"id"]];
        //Start the operation to post on the comment
        [FBRequestConnection startWithGraphPath:graphAPIString
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
    }
    //If the user intends to post to the wall
    else if (type == TextEntryTypePost)
    {
        //If there is an image provided in the post, post to the users album
        if (image)
        {
            //Create a graphAPIString to post to the photos of the users album
            graphAPIString = [NSString stringWithFormat:@"%@/photos", self.appConfiguration.facebookFeedToRequest];
            
            //Set the image data, and ensure that the app does not post to the users wall
            [params setObject:image forKey:@"source"];
            [params setObject:@"true" forKey:@"no_story"];
            
            //Start the request to post a picture to the apps wall
            [FBRequestConnection startWithGraphPath:graphAPIString
                                         parameters:params
                                         HTTPMethod:@"POST"
                                  completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [self processPostPhotoRequestWithConnection:connection withMessage:string withResults:result postError:error];
            }];
        }
        //If there is no image, create and post to the apps facebook feed
        else
        {
            //Create a graphAPIString to post text to the users wall, and start the request to post
            graphAPIString = [NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest];
            [FBRequestConnection startWithGraphPath:graphAPIString
                                         parameters:params
                                         HTTPMethod:@"POST"
                                  completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [self processPostRequestWithConnection:connection withResults:result postError:error];
            }];
        }
        
    }
    
    
}

- (void)textViewDidCancel:(UITextView *)textView
{
    //Reload table view if the textview is canceled, this is needed
    //if the textview is rotated while entering data the tableview needs
    //to adjust the height of the rows
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.facebookArrayTableData objectAtIndex:[indexPath row]];

    //Retrieve the type of facebook post that the tableview row will display
    NSString *typeOfPost = [dictionaryForCell valueForKeyPath:@"type"];
    
    UITableViewCell *cell = nil;
    UITextView *textView = nil;
    UIButton *commentButton = nil;
    UIButton *buttonImage = nil;
    UILabel *postedByLabel = nil;
    UIButton *addCommentButton = nil;
    UIImageView *profileImageView = nil;
    UIButton *likeButton = nil;
    UILabel *datePosted = nil;
    
    //Dequeue a resuable cell based upon the type of post
    if ([typeOfPost isEqualToString:@"photo"])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"photoFacebookCell"];
    }
    else 
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"defaultFacebookCell"];
    }
    
    if (cell)
    {
        //Retrieve each object from the cell based upon the view tag
        
        //Retrieve view to display image of profile that made the post
        profileImageView = (UIImageView *)[cell.contentView viewWithTag:1];
        
        //Retrieve the label that will be used to show the name of the poster
        postedByLabel = (UILabel *)[cell.contentView viewWithTag:2];
        
        //Retrieve the textview that will be used to show the post text
        textView = (UITextView *)[cell.contentView viewWithTag:3];
        
        //Retrieve the commentButton that will be used comment on a post
        commentButton = (UIButton *)[cell.contentView viewWithTag:4];
        
        //Retrieve the addCommentButton that will be used to post to a wall
        addCommentButton = (UIButton *)[cell.contentView viewWithTag:5];
        
        //Retrieve the buttonImage that will be used to display an image
        buttonImage = (UIButton *)[cell.contentView viewWithTag:6];
        
        //Retrieve the button that will be used to like/unlike a post
        likeButton = (UIButton *)[cell.contentView viewWithTag:7];
        
        //Retrieve the label that will be used to display the date of post
        datePosted = (UILabel *)[cell.contentView viewWithTag:8];
        
        if (!commentButton)
        {
            commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
            
            //Set the comment button target action to call a method when the user wants to comment on a post
            [commentButton addTarget:self action:@selector(commentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
            
            commentButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
            commentButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
            
            commentButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            //System Bold 15.0
            commentButton.tag = 4;
            
            commentButton.frame = CGRectMake(likeButton.frame.origin.x - 5, likeButton.frame.origin.y + 5, cell.frame.size.width - 10, 30);
            UIImage *facebookCommentButtonImage = [UIImage imageNamed:self.appConfiguration.facebookCommentButtonImageTitle];
            UIEdgeInsets AcceptDeclineEdge = UIEdgeInsetsMake(20, 20, 20, 20);
            UIImage *stretchableFacebookCommentButtonImage = [facebookCommentButtonImage resizableImageWithCapInsets:AcceptDeclineEdge];
            [commentButton setBackgroundImage:stretchableFacebookCommentButtonImage forState:UIControlStateNormal];
            [cell.contentView addSubview:commentButton];
            [cell.contentView sendSubviewToBack:commentButton];
            
        }
        
        //Set the main comment button target action to call a method when the user wants to post to the apps wall
        [addCommentButton addTarget:self action:@selector(mainCommentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [addCommentButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        
        //Set the main image image target action to call a method to display a full view of the image
        [buttonImage addTarget:self action:@selector(postImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        //Set the like button target action to call a method to like or unlike a post
        //and set the tint colors of the different selected states
        [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [likeButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateApplication];

    }
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKeyPath:FACEBOOK_CONTENT_TITLE];
    
    //Create an NSDate based upon the facebook posted created time and format
    NSDate *facebookDate = [[NSDate alloc] initFacebookDateFormatWithString:[dictionaryForCell valueForKey:@"created_time"]];
    
    //Pull the proper string to display on the cell, ie 1 hour ago, Yesterday 3:48am
    datePosted.text = facebookDate.socialDate;
    
    //If the type of post is link
    if ([typeOfPost isEqualToString:@"link"])
    {
        NSRange range = NSMakeRange(NSNotFound, 0);
        //If message content of the facebook link post is empty
        if (mainTextLabel == nil)
        {
            //If there is no message in the post, create a string with the name and description of the link
            mainTextLabel = [NSString stringWithFormat:@"%@ - %@", [dictionaryForCell valueForKey:@"name"],[dictionaryForCell valueForKey:@"description"]];
        }
        else
        {
            //Search the facebook message field for a link
            range = [mainTextLabel rangeOfString:@"http"];
        }
        //If a link is not found in the message content of the facebook message, or the message
        //content is nil, take the link and append it to the end of the main text label
        if (range.location == NSNotFound)
        {
            NSString *linkURL = [dictionaryForCell valueForKeyPath:@"link"];
            if ([linkURL isKindOfClass:[NSString class]])
            {
                mainTextLabel = [mainTextLabel stringByAppendingString:@" "];
                mainTextLabel = [mainTextLabel stringByAppendingString:linkURL];
            }
        }
    }
    //If there is no message in the facebook post, default to the story field
    else if (mainTextLabel == nil)
    {
        if ([dictionaryForCell valueForKey:@"story"])
        {
            mainTextLabel = [dictionaryForCell valueForKey:@"story"];
        }
    }
    
    //Retrieve the name of the user who posted the information
    id fromName = [dictionaryForCell valueForKeyPath:@"from.name"];
    if ([fromName isKindOfClass:[NSString class]]) postedByLabel.text = fromName;
    
    //Retrieve the total number of comments, and update the comments string
    //that is places inside the comment button
    NSNumber *count = [dictionaryForCell valueForKeyPath:@"comments.count"];
    NSString *commentsString = [[NSString alloc] initWithFormat:@"%@ Comments", count];
    [commentButton setTitle:commentsString forState:UIControlStateNormal];
    
    //Set the default to be no match found
    BOOL matchFound = NO;
    
    //Retrieve an array of users ids who like the post
    id likes = [dictionaryForCell valueForKeyPath:@"likes.data.id"];
    
    //Verify that the return is of type array, then look through each id to see
    //if the user is one of the people who have liked the post.  If the user did
    //like the post, set the likeButton text to "Unlike"
    if ([likes isKindOfClass:[NSArray class]])
    {
        NSArray *likesArray = likes;
        for (NSString *items in likesArray)
        {
            if ([items isEqualToString:self.userNameID])
            {
                [likeButton setTitle:@"Unlike" forState:UIControlStateNormal]; 
                matchFound = YES;
            }
        }
    }
    
    //If not match is found, set the likeButton text to "Like"
    if (matchFound == NO)
    {
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    
    //Set the cell text label's based upon the table contents array location
    textView.text = mainTextLabel;
    
    //Save the old Text View size before the textView height is adjusted
    CGFloat oldSizeHeight = textView.frame.size.height;
    
    //Resize the text view based upon the text, and the required width
    [textView resizeTextViewForWidth:self.tableView.frame.size.width - 20];
    
    //Calculate the height change between the old and new textView
    CGFloat heightChange = textView.frame.size.height - oldSizeHeight;
    
    profileImageView.image = nil;
    
    if ([typeOfPost isEqualToString:@"photo"])
    {
        //if the type of post is a photo, adjust the buttonImage, comment button,
        //and addComment button based upon the heigh change
        buttonImage.imageView.image = nil;
        buttonImage.frame = CGRectMake(buttonImage.frame.origin.x, buttonImage.frame.origin.y + heightChange, buttonImage.frame.size.width, buttonImage.frame.size.height);
        commentButton.frame = CGRectMake(commentButton.frame.origin.x, commentButton.frame.origin.y + heightChange, commentButton.frame.size.width, commentButton.frame.size.height);
        addCommentButton.frame = CGRectMake(addCommentButton.frame.origin.x, addCommentButton.frame.origin.y + heightChange, addCommentButton.frame.size.width, addCommentButton.frame.size.height);
        likeButton.frame = CGRectMake(likeButton.frame.origin.x, likeButton.frame.origin.y + heightChange, likeButton.frame.size.width, likeButton.frame.size.height);
    }
    else
    {
        //If the type of post is anything but a photo, adjust the cell height based upon
        //the height change
        commentButton.frame = CGRectMake(commentButton.frame.origin.x, commentButton.frame.origin.y + heightChange, commentButton.frame.size.width, commentButton.frame.size.height);
        addCommentButton.frame = CGRectMake(addCommentButton.frame.origin.x, addCommentButton.frame.origin.y + heightChange, addCommentButton.frame.size.width, addCommentButton.frame.size.height);
        likeButton.frame = CGRectMake(likeButton.frame.origin.x, likeButton.frame.origin.y + heightChange, likeButton.frame.size.width, likeButton.frame.size.height);
        
    }
    return cell;
}

- (UIImage *) getScaledImage:(UIImage *)img insideButton:(UIButton *)btn 
{
    
    // Check which dimension (width or height) to pay respect to and
    // calculate the scale factor
    CGFloat imgRatio = img.size.width / img.size.height,
    btnRatio = btn.frame.size.width / btn.frame.size.height,
    scaleFactor = (imgRatio > btnRatio
                   ? img.size.width / btn.frame.size.width
                   : img.size.height / btn.frame.size.height);
    
    // Create image using scale factor
    UIImage *scaledImg = [UIImage imageWithCGImage:[img CGImage] 
                                             scale:scaleFactor 
                                       orientation:UIImageOrientationUp];
    return scaledImg;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tmpDictionary = [self.facebookArrayTableData objectAtIndex:[indexPath row]];
    NSString *pictureID = [tmpDictionary valueForKeyPath:@"object_id"];
    NSString *profileFromId = [tmpDictionary valueForKeyPath:@"from.id"];
    NSString *typeOfPost = [tmpDictionary valueForKeyPath:@"type"];
    
    //if (![type isEqualToString:@"photo"]) return;
    
    if ([typeOfPost isEqualToString:@"photo"])
    {
        __block NSData *picture = [self.photoDictionary objectForKey:pictureID];
        
        if (!picture)
        {
            if (pictureID)
            {
                [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@", pictureID] completionHandler:^(FBRequestConnection *connection, id result, NSError  *error) {
                    NSURL *url = [[NSURL alloc] initWithString:[result valueForKey:@"source"]];
                    picture = [NSData dataWithContentsOfURL:url];
                    if (picture) [self.photoDictionary setObject:picture forKey:pictureID];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
                        if ([tmpArray containsObject:indexPath])
                        {
                            UIButton *buttonImage = (UIButton *)[cell.contentView viewWithTag:6];
                            UIImage *image = [UIImage imageWithData:picture];
                            buttonImage.contentMode = UIViewContentModeScaleAspectFit;
                            UIImage *scaledImage = [self getScaledImage:image insideButton:buttonImage];
                            [buttonImage setImage:scaledImage forState:UIControlStateNormal];
                        }
                    });
                }];
                
            }
        }
        else {
            UIButton *buttonImage = (UIButton *)[cell.contentView viewWithTag:6];
            UIImage *image = [UIImage imageWithData:picture];
            buttonImage.contentMode = UIViewContentModeScaleAspectFit;
            UIImage *scaledImage = [self getScaledImage:image insideButton:buttonImage];
            [buttonImage setImage:scaledImage forState:UIControlStateNormal];
        }
    }
    
    __block NSData *profilePictureData = [self.photoDictionary objectForKey:profileFromId];
    NSString *urlStringForProfilePicture = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture/type=small", profileFromId];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        if (!profilePictureData)
        {
            if (profileFromId)
            {
                NSURL *profileUrl = [[NSURL alloc] initWithString:urlStringForProfilePicture];
                profilePictureData = [NSData dataWithContentsOfURL:profileUrl];
                if (profilePictureData) [self.photoDictionary setObject:profilePictureData forKey:profileFromId];
                NSLog(@"Profile Picture");
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
            if ([tmpArray containsObject:indexPath])
            {
                UIImageView *profileImageView = (UIImageView *)[cell.contentView viewWithTag:1];
                [profileImageView setImage:[UIImage imageWithData:profilePictureData]];
            }
        });
    });
    dispatch_release(downloadQueue);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.facebookArrayTableData objectAtIndex:[indexPath row]];
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKey:FACEBOOK_CONTENT_TITLE];
    
    NSString *typeOfPost = [dictionaryForCell valueForKeyPath:@"type"];
    if (mainTextLabel == nil)
    {
        mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForDetailCellLabelText]];
    }
    
    if ([typeOfPost isEqualToString:@"link"])
    {
        NSRange range = [mainTextLabel rangeOfString:@"http"];
        if (mainTextLabel == nil)
        {
            mainTextLabel = [NSString stringWithFormat:@"%@ - %@", [dictionaryForCell valueForKey:@"name"],[dictionaryForCell valueForKey:@"description"]];
            NSString *linkURL = [dictionaryForCell valueForKeyPath:@"link"];
            if ([linkURL isKindOfClass:[NSString class]])
            {
                mainTextLabel = [mainTextLabel stringByAppendingString:@" "];
                mainTextLabel = [mainTextLabel stringByAppendingString:linkURL];
            }
        }
        else if (range.location == NSNotFound)
        {
            NSString *linkURL = [dictionaryForCell valueForKeyPath:@"link"];
            if ([linkURL isKindOfClass:[NSString class]])
            {
                mainTextLabel = [mainTextLabel stringByAppendingString:@" "];
                mainTextLabel = [mainTextLabel stringByAppendingString:linkURL];
            }
        }
    }
    else if (mainTextLabel == nil)
    {
        if ([dictionaryForCell valueForKey:@"story"])
        {
            mainTextLabel = [dictionaryForCell valueForKey:@"story"];
        }
    }
    
    CGFloat height = CGFLOAT_MIN;
    if ([typeOfPost isEqualToString:@"photo"])
    {
        UITextView *textView2 = (UITextView *)[self.facebookPhotoCell.contentView viewWithTag:3];
        textView2.frame = CGRectMake(textView2.frame.origin.x, textView2.frame.origin.y, textView2.frame.size.width, 25);
        //Set the cell text label's based upon the table contents array location
        UITextView *textView = (UITextView *)[self.facebookPhotoCell.contentView viewWithTag:3];
        textView.text = mainTextLabel;
        CGFloat oldSizeHeight = textView.frame.size.height;
        [textView resizeTextViewForWidth:self.tableView.frame.size.width - 20];
        
        CGFloat heightChange = textView.frame.size.height - oldSizeHeight;
        height = self.facebookPhotoCell.frame.size.height + heightChange;
    }
    else
    {
        UITextView *textView2 = (UITextView *)[self.defaultFacebookCell.contentView viewWithTag:3];
        textView2.frame = CGRectMake(textView2.frame.origin.x, textView2.frame.origin.y, textView2.frame.size.width, 25);
        //Set the cell text label's based upon the table contents array location
        UITextView *textView = (UITextView *)[self.defaultFacebookCell.contentView viewWithTag:3];
        textView.text = mainTextLabel;
        CGFloat oldSizeHeight = textView.frame.size.height;
        [textView resizeTextViewForWidth:self.tableView.frame.size.width - 20];
        
        CGFloat heightChange = textView.frame.size.height - oldSizeHeight;
        height = self.defaultFacebookCell.frame.size.height + heightChange;
    }
    
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Cell Push" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Web"] & [sender isKindOfClass:[NSURL class]])
    {
        [segue.destinationViewController setUrlToLoad:sender];
    }
    else if ([segue.identifier isEqualToString:@"detailView"])
    {
        if ([sender isKindOfClass:[NSDictionary class]])
        {
            //Set the model for the MVC we are about to push onto the stack
            [segue.destinationViewController setShortCommentsDictionaryModel:sender];
            
        }
    }
    else if ([segue.identifier isEqualToString:@"Photo"])
    {
        if ([sender isKindOfClass:[NSDictionary class]])
        {
            NSString *objectID = [sender valueForKey:@"object_id"];
            [segue.destinationViewController setFacebookPhotoObjectID:objectID];
        }
    }
    else if ([segue.identifier isEqualToString:@"CommentOnPost"])
    {
        [segue.destinationViewController setTextEntryDelegate:self];
        [segue.destinationViewController setDictionaryForComment:sender];
        [segue.destinationViewController setSubmitButtonTitle:@"Send"];
        [segue.destinationViewController setWindowTitle:@"Comment on Post"];
        [segue.destinationViewController setType:TextEntryTypeComment];
    }
    else if ([segue.identifier isEqualToString:@"PostToPage"])
    {
        [segue.destinationViewController setTextEntryDelegate:self];
        [segue.destinationViewController setDictionaryForComment:sender];
        [segue.destinationViewController setSubmitButtonTitle:@"Post"];
        [segue.destinationViewController setWindowTitle:@"Facebook"];
        [segue.destinationViewController setType:TextEntryTypePost];
        [segue.destinationViewController setSupportPicture:YES];
    }
}

- (void)processGetFeedRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    
    if (error) [self determineCauseOfError:error];

    //Verify the result from the facebook class is actually a dictionary
    else if ([result isKindOfClass:[NSDictionary class]])
    {
        
        NSMutableArray *array = [result mutableArrayValueForKey:@"data"];
        
        //Set the property equal to the new comments array, which will then trigger a table reload
        self.facebookArrayTableData = array;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        
        //If an oldbutton was removed from the right bar button spot, put it back
        self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
        
        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
    });
}

- (void)determineCauseOfError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        self.facebookArrayTableData = nil;
        [self.tableView reloadData];
        //[self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
        NSDictionary *errorDictionary = [[error userInfo] valueForKey:@"com.facebook.sdk:ParsedJSONResponseKey"];
        NSString *errorMessage = [errorDictionary valueForKeyPath:@"body.error.message"];
        NSNumber *errorCode = [errorDictionary valueForKeyPath:@"body.error.code"];
        NSString *tmpString = nil;
        if ([errorCode intValue] == 104) tmpString = @"Please Log In to continue";
        else tmpString = errorMessage;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[NSString alloc] initWithFormat:@"%@ - Facebook", self.appConfiguration.appName] message:tmpString delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    });
}

- (void)processPostRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    if (error) [self determineCauseOfError:error];
    else {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError  *error) {
            [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
        }];
    }
}

- (void)processPostPhotoRequestWithConnection:(FBRequestConnection *)connection withMessage:(NSString *)message withResults:(id)result postError:(NSError *)error
{
    if (error) [self determineCauseOfError:error];
    else 
    {
        NSString *facebookPhotoID = [result valueForKey:@"id"];
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@", facebookPhotoID] completionHandler:^(FBRequestConnection *connection, id result2, NSError  *error) {
            if (error) [self determineCauseOfError:error];
            else 
            {
                NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[result2 valueForKey:@"link"], @"link", message, @"message" ,nil];
                NSString *graphAPIString = [NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest];
                [FBRequestConnection startWithGraphPath:graphAPIString parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (error) [self determineCauseOfError:error];
                    else [self processPostRequestWithConnection:connection withResults:result postError:error];
                }];
            }
        }];
    }
    
}

#pragma mark - SocialMediaDetailView datasource

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender
    dictionaryForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
{
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    //When the SocialMediaDetailViewController needs further information from
    //the facebook class, this method is called
    [FBRequestConnection startWithGraphPath:facebookGraphAPIString completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
}

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender
      postDataForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
                         withParameters:(NSMutableDictionary *)params
{
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    [FBRequestConnection startWithGraphPath:facebookGraphAPIString parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
}

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender 
    deleteDataForFacebookGraphAPIString:(NSString *)facebookGraphAPIString 
                         withParameters:(NSMutableDictionary *)params
{
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    [FBRequestConnection startWithGraphPath:facebookGraphAPIString parameters:params HTTPMethod:@"DELETE" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
}
#pragma mark - Facebook Session Delegate Methods

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setLogInOutButton:nil];
    [super viewDidUnload];
}

- (void)refresh {
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    //[self.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] andDelegate:self];
    
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
}

- (void)presentWebView:(NSNotification *)notification
{
    
    if ([[notification name] isEqualToString:@"urlSelected"])
    {
        [self performSegueWithIdentifier:@"Web" sender:[notification object]];
    }
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) 
    {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

/*
 * Opens a Facebook session and optionally shows the login UX.
 */
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI 
{
    NSArray *params = [[NSArray alloc] initWithObjects:@"publish_stream", @"user_photos", nil];
    BOOL open = [FBSession openActiveSessionWithPermissions:params allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [self sessionStateChanged:session state:state error:error];
    }];
    return open;
}

- (void) closeSession {
    [FBSession.activeSession closeAndClearTokenInformation];
}

@end
