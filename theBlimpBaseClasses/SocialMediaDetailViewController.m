//
//  SocialMediaDetailViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocialMediaDetailViewController.h"
#import "ImageViewController.h"
#import "WebViewController.h"
#import "UITextView+Facebook.h"
#import "NSDate+Generic.h"
#import "NSMutableDictionary+appConfiguration.h"
#import <FacebookSDK/FacebookSDK.h>

@interface SocialMediaDetailViewController ()
@property (nonatomic, strong) NSArray *commentsArray;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) UIButton *buttonImage;
@property (nonatomic, strong) FBRequest *facebookRequest;
@property (nonatomic, strong) NSMutableDictionary *appConfiguration;
@end

@implementation SocialMediaDetailViewController
@synthesize profilePictureImageView;
@synthesize shortCommentsDictionaryModel = _shortCommentsDictionaryModel;
@synthesize commentsArray = _commentsArray;
@synthesize textView = _textView;
@synthesize buttonImage = _buttonImage;
@synthesize fullCommentsDictionaryModel = _fullCommentsDictionaryModel;
@synthesize postImage = _postImage;
@synthesize facebookRequest = _facebookRequest;
@synthesize activityIndicator = _activityIndicator;
@synthesize oldBarButtonItem = _oldBarButtonItem;
@synthesize appConfiguration = _appConfiguration;

#define FONT_SIZE 14.0f
#define CELL_CONTENT_WIDTH 200.0f
#define CELL_CONTENT_MARGIN 16.0f
#define FACEBOOK_DETAIL_FONT_SIZE 16.0f

- (void)setCommentsArray:(NSArray *)commentsArray
{
    _commentsArray = commentsArray;
    [self.tableView reloadData];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    id appDelegate = [[UIApplication sharedApplication] delegate];
    self.appConfiguration = [appDelegate appConfiguration];
    
    //Do not allow the cells in the tableview to be selected
    [self.tableView setAllowsSelection:NO];
    
    self.oldBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    //initialize the activity indicator, set it to the center top of the view, and
    //start it animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicator.hidesWhenStopped = YES;
    
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [self.shortCommentsDictionaryModel valueForKeyPath:@"id"]];
    
    //Pull the full comments dictionary from the delegate to use as our Model
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    //When the SocialMediaDetailViewController needs further information from
    //the facebook class, this method is called
    [FBRequestConnection startWithGraphPath:graphAPIString completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentWebView:) 
                                                 name:@"urlSelected"
                                               object:nil];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"urlSelected" 
                                                  object:nil];
}

- (void)viewDidUnload
{
    [self setProfilePictureImageView:nil];
    [self setTextView:nil];
    [self setButtonImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    //When the view disappears the code in this fucnction removes all delegation to this class
    //This is required incase a connection request is in progress when the view disappears
    //[self.facebookRequest setDelegate:nil];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)processGetFeedRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //Since the request has been recieved, and parsed, stop the Activity Indicator
            [self.activityIndicator stopAnimating];
            self.fullCommentsDictionaryModel = nil;
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
    //Verify the result from the facebook class is actually a dictionary
    else if ([result isKindOfClass:[NSDictionary class]])
    {
        self.fullCommentsDictionaryModel = result;
        [self loadSocialMediaView];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        
        //If an oldbutton was removed from the right bar button spot, put it back
        self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
        
        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
    });
}

- (void)likeButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.commentsArray objectAtIndex:indexPath.row];
    
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/likes", [dictionaryData valueForKeyPath:@"id"]];
    UIButton *likeButton = sender;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    if ([likeButton.titleLabel.text isEqualToString:@"Like"])
    {
        [FBRequestConnection startWithGraphPath:graphAPIString parameters:[[NSMutableDictionary alloc] init] HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        [likeButton setTitle:@"Unlike" forState:UIControlStateNormal];  
        
    }
    else {
        //[self.facebook requestWithGraphPath:graphAPIString andParams:[[NSMutableDictionary alloc] init] andHttpMethod:@"DELETE" andDelegate:self];
        [FBRequestConnection startWithGraphPath:graphAPIString parameters:[[NSMutableDictionary alloc] init] HTTPMethod:@"DELETE" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    
}

- (void)processPostRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //Since the request has been recieved, and parsed, stop the Activity Indicator
            [self.activityIndicator stopAnimating];
            self.fullCommentsDictionaryModel = nil;
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
    else {
        NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [self.shortCommentsDictionaryModel valueForKeyPath:@"id"]];
        [FBRequestConnection startWithGraphPath:graphAPIString completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
        }];
    }
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
    return [self.commentsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This function is used to configure a cell and display the proper information
    //for the table row.  The output of this function is a cell that displays one comment
    //from one facebook person, and the name of that person
    
    static NSString *CellIdentifier = @"CommentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UIImageView *profileImageView = nil;
    UILabel *name = nil;
    UITextView *comment = nil;
    UIButton *likeButton = nil;
    UILabel *datePosted = nil;
    
    //If there is no reusable cell of this type, create a new one
    if (!cell)
    {
        //Initialize a UITableViewCell of type Subtitle
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    profileImageView = (UIImageView *)[cell.contentView viewWithTag:3];
    name = (UILabel *)[cell.contentView viewWithTag:1];
    comment = (UITextView *)[cell.contentView viewWithTag:2];
    
    likeButton = (UIButton *)[cell.contentView viewWithTag:4];
    [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    datePosted = (UILabel *)[cell.contentView viewWithTag:5];
    
    profileImageView.image = nil;
    
    //Retrieve the corresponding dictionary for the cell, retrieve the main and detail text
    //label, and set the cell labels
    NSDictionary *dictionaryForCell = [self.commentsArray objectAtIndex:[indexPath row]];
    NSString *mainTextLabel = [dictionaryForCell valueForKeyPath:@"message"];
    NSString *detailTextLabel = [dictionaryForCell valueForKeyPath:@"from.name"];

    NSDate *socialMediaDate = [[NSDate alloc] initFacebookDateFormatWithString:[dictionaryForCell valueForKey:@"created_time"]];
    
    NSNumber *user_likes = [dictionaryForCell valueForKeyPath:@"user_likes"];
    if ([user_likes boolValue])
    {
        [likeButton setTitle:@"Unlike" forState:UIControlStateNormal];
    }
    else
    {
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    CGFloat oldSizeHeight = comment.frame.size.height;
    
    comment.text = mainTextLabel;
    name.text = detailTextLabel;
    datePosted.text = socialMediaDate.socialDate;
    
    [comment resizeTextViewForWidth:self.tableView.frame.size.width - comment.frame.origin.x - 30];
    CGFloat heightChange = comment.frame.size.height - oldSizeHeight;
    
    likeButton.frame = CGRectMake(likeButton.frame.origin.x, likeButton.frame.origin.y + heightChange, likeButton.frame.size.width, likeButton.frame.size.height);
    datePosted.frame = CGRectMake(datePosted.frame.origin.x, datePosted.frame.origin.y + heightChange, datePosted.frame.size.width, datePosted.frame.size.height);
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This function is used to download the facebook person profile image and display
    //it in the table row cell image area
    
    //Create a download que to download the facebook profile image
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        //Retreive the NSDictionary corresponding to the table row
        NSDictionary *tmpDictionary = [self.commentsArray objectAtIndex:[indexPath row]];
        
        //Create a URL based upon the facebook graph API
        NSString *profileFromId = [tmpDictionary valueForKeyPath:@"from.id"];
        NSString *urlString = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture", profileFromId];
        NSURL *url = [[NSURL alloc] initWithString:urlString];
        
        //Create an image based upon the downloaded NSData from the Facebook graph URL
        //created above
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        NSLog(@"Loading Web Data");
        dispatch_async(dispatch_get_main_queue(), ^{
            //Verify the index path the image was downloaded for is still visible
            //in the tableview.  If it is still visible set the cell imageView
            NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
            UIImageView *profileImageView = (UIImageView *)[cell.contentView viewWithTag:3];
            if ([tmpArray containsObject:indexPath]) [profileImageView setImage:image];
        });
    });
    dispatch_release(downloadQueue);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This function calculates a approprate height based up on length of the text that will
    //be displayed in the cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    
    if (cell)
    {
        NSDictionary *tmpDictionary = [self.commentsArray objectAtIndex:[indexPath row]];
        NSString *dictionaryText = [tmpDictionary valueForKeyPath:@"message"];
        
        //Set the cell text label's based upon the table contents array location
        UITextView *textView = (UITextView *)[cell.contentView viewWithTag:2];
        UIButton *likeButton = (UIButton *)[cell.contentView viewWithTag:4];
        textView.text = dictionaryText;
        
        CGFloat oldSizeHeight = textView.frame.size.height;
        
        [textView resizeTextViewForWidth:self.tableView.frame.size.width - textView.frame.origin.x - 30];
        CGFloat heightChange = textView.frame.size.height - oldSizeHeight;
        likeButton.frame = CGRectMake(likeButton.frame.origin.x, likeButton.frame.origin.y + heightChange, likeButton.frame.size.width, likeButton.frame.size.height);
        CGFloat height = likeButton.frame.origin.y + likeButton.frame.size.height;
        return height;
    }
    else return 44;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //This function witll create a UITextView, put the UITextView inside a UITableViewCell and return
    //The cell as the header view
    
    //Pull the main and detail text label out of the corresponding dictionary
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentHeaderCell"];
    if (cell)
    {
        UILabel *name = (UILabel *)[cell.contentView viewWithTag:1];
        UITextView *comment = (UITextView *)[cell.contentView viewWithTag:2];
        UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:4];
        
        NSString *typeOfPost = [self.shortCommentsDictionaryModel valueForKeyPath:@"type"];
        NSString *commentString = [self.shortCommentsDictionaryModel valueForKeyPath:@"message"];
        NSString *dateString = [self.shortCommentsDictionaryModel valueForKeyPath:@"created_time"];
        NSDate *socialMediaDate = [[NSDate alloc] initFacebookDateFormatWithString:dateString];
        
        if ([typeOfPost isEqualToString:@"link"])
        {
            NSRange range = [commentString rangeOfString:@"http"];
            if (range.location == NSNotFound)
            {
                NSString *linkURL = [self.shortCommentsDictionaryModel valueForKeyPath:@"link"];
                if ([linkURL isKindOfClass:[NSString class]])
                {
                    commentString = [commentString stringByAppendingString:@" "];
                    commentString = [commentString stringByAppendingString:linkURL];
                }
            }
        }
        
        name.text = [self.shortCommentsDictionaryModel valueForKeyPath:@"from.name"];
        comment.text = commentString;
        dateLabel.text = socialMediaDate.socialDate;
        
        [comment resizeTextViewForWidth:self.tableView.frame.size.width - comment.frame.origin.x - 10];
        dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
        dispatch_async(downloadQueue, ^{
    
            //Create a URL based upon the facebook graph API
            NSString *profileFromId = [self.shortCommentsDictionaryModel valueForKeyPath:@"from.id"];
            NSString *urlString = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture", profileFromId];
            NSURL *url = [[NSURL alloc] initWithString:urlString];
            
            //Create an image based upon the downloaded NSData from the Facebook graph URL
            //created above
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            NSLog(@"Loading Web Data");
            dispatch_async(dispatch_get_main_queue(), ^{
                //Verify the index path the image was downloaded for is still visible
                //in the tableview.  If it is still visible set the cell imageView
                UIImageView *profileImageView = (UIImageView *)[cell.contentView viewWithTag:3];
                [profileImageView setImage:image];
            });
        });
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //This function will determine the size required for the header based
    //upon the size of the text string
    
    //Pull the main and detail text label out of the corresponding dictionary
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentHeaderCell"];
    
    if (cell)
    {
        NSString *typeOfPost = [self.shortCommentsDictionaryModel valueForKeyPath:@"type"];
        NSString *commentString = [self.shortCommentsDictionaryModel valueForKeyPath:@"message"];
        
        if ([typeOfPost isEqualToString:@"link"])
        {
            NSRange range = [commentString rangeOfString:@"http"];
            if (range.location == NSNotFound)
            {
                NSString *linkURL = [self.shortCommentsDictionaryModel valueForKeyPath:@"link"];
                if ([linkURL isKindOfClass:[NSString class]])
                {
                    commentString = [commentString stringByAppendingString:@" "];
                    commentString = [commentString stringByAppendingString:linkURL];
                }
            }
        }
        
        UITextView *comment = (UITextView *)[cell.contentView viewWithTag:2];
        comment.text = commentString;
        [comment resizeTextViewForWidth:self.tableView.frame.size.width - comment.frame.origin.x - 10];
        CGFloat height = comment.frame.origin.y + comment.frame.size.height;
        return height;
    }
    else return 44;
}

#pragma mark - NSNotification Methods
- (void)presentWebView:(NSNotification *) notification
{
    //A notification is sent when a URL is selected in a UITextView. When
    //it is recieved segue to the web view controller
    if ([[notification name] isEqualToString:@"urlSelected"])
    {
        [self performSegueWithIdentifier:@"Web" sender:[notification object]];
    }
}

#pragma mark - Segue Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //If a photo segue is required, send the photo object ID so the image
    //can be downloaded
    if ([segue.identifier isEqualToString:@"Photo"])
    {
        [segue.destinationViewController setFacebookPhotoObjectID:[self.fullCommentsDictionaryModel valueForKeyPath:@"object_id"]];
    }
    //If a web segue is required, send the URL to the new controller so the
    //Website can be loaded
    else if ([segue.identifier isEqualToString:@"Web"] & [sender isKindOfClass:[NSURL class]])
    {
        [segue.destinationViewController setUrlToLoad:sender];
    }
    //If the comment button is pushed the comment view controller will be
    //presented, and the delegate will be set to this controller
    else if ([segue.identifier isEqualToString:@"comment"])
    {
        [segue.destinationViewController setTextEntryDelegate:self];
        [segue.destinationViewController setSubmitButtonTitle:@"Post"];
        [segue.destinationViewController setWindowTitle:@"Comment on Post"];
        [segue.destinationViewController setType:TextEntryTypeComment];
    }
}

#pragma mark - Helper Methods
- (void)refresh 
{
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    //[self.socialMediaDelegate SocialMediaDetailViewController:self dictionaryForFacebookGraphAPIString:[self.shortCommentsDictionaryModel objectForKey:@"id"]];
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [self.shortCommentsDictionaryModel valueForKeyPath:@"id"]];
    
    //When the SocialMediaDetailViewController needs further information from
    //the facebook class, this method is called
    [FBRequestConnection startWithGraphPath:graphAPIString completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
    }];
}

- (void)loadSocialMediaView
{
    //This function is called after the full comments dictionary has been downloaded
    //from the facebook server.  The purpose of this function is to load the original
    //postData in the textView, and to set the comments to the model of the controlller
    //"commentsArray".  When commentsArray gets set the tableview reloads
    
    //Pull the original postData from the fullCommentsDictionaryModel that was retrieved
    //from SocialMediaDetailViewControllerDelegate, then use introspection to verify the 
    //postData is a String
    id postData = [self.shortCommentsDictionaryModel objectForKey:@"message"];
    if ([postData isKindOfClass:[NSString class]]) self.textView.text = postData;
    
    //Pull all of the comments from the fullCommentsDictionaryModel and use introspection
    //to verify the commentsArray is actually an array or if the commentsArray is nil
    //We still want to set the comments array to nil so the table will be reloaded
    id commentsArray = [self.fullCommentsDictionaryModel valueForKeyPath:@"data"];
    if ([commentsArray isKindOfClass:[NSArray class]] || (!commentsArray)) self.commentsArray = commentsArray;
    
    //retrieve the profile ID from the controller model, and create a facebook graphi API URL
    NSString *profileId = [self.shortCommentsDictionaryModel valueForKeyPath:@"from.id"];
    NSString *urlStringForProfile = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture", profileId];
    
    //Verify the urlStringForProfile is not nil
    if (urlStringForProfile)
    {
        //Create a downloadQueue, create a NSURL, and create a UIImage based upon downloaded
        //NSData object
        dispatch_queue_t downloadQueue2 = dispatch_queue_create("Post Imageview", NULL);
        dispatch_async(downloadQueue2, ^{
            NSURL *urlForProfilePicture = [[NSURL alloc] initWithString:urlStringForProfile];
            NSLog(@"Loading Web Data");
            UIImage *profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:urlForProfilePicture]];
            //Once the UIImage is ready, stop the Activity indicator by putting the
            //oldBarButtonItem back, and set the profileImage view to the downloaded Image
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
                self.profilePictureImageView.image = profileImage;
            });
        });
        dispatch_release(downloadQueue2);
    }
}

#pragma mark - Button methods

- (IBAction)commentButtonPressed:(id)sender 
{
    //When the comment button is pushed the approprate segue will be performed
    [self performSegueWithIdentifier:@"comment" sender:self];
}

- (void)postImageButtonPressed:(id)sender 
{
    NSDictionary *imageViewModel = [self.fullCommentsDictionaryModel valueForKeyPath:@"object_id"];
    if (imageViewModel == nil) return;
    [self performSegueWithIdentifier:@"Photo" sender:self];
}

#pragma mark - ImagoDeiTextEntryDelegate Method

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string withDictionary:(NSDictionary *)dictionary forType:(TextEntryType)type
{
    //This function is called when the Comment View controller has data entered
    //and the view is closing.  The purpose of this function is to retireve the data
    //and post it to facebook using the graph API
    
    if (type == TextEntryTypeComment)
    {
        NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [self.shortCommentsDictionaryModel valueForKeyPath:@"id"]];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:string, @"message", nil];
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        [FBRequestConnection startWithGraphPath:graphAPIString parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        //[self.socialMediaDelegate SocialMediaDetailViewController:self postDataForFacebookGraphAPIString:graphAPIString withParameters:[[NSMutableDictionary alloc] initWithObjectsAndKeys:string, @"message", nil]]; 
    }
}

- (void)textViewDidCancel:(UITextView *)textView
{
    [self.tableView reloadData];
}

@end
