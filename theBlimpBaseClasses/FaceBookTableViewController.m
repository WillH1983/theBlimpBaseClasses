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
    if (_photoDictionary == nil) _photoDictionary = [[NSMutableDictionary alloc] init];
    return _photoDictionary;
}

- (UITableViewCell *)defaultFacebookCell
{
    if (_defaultFacebookCell == nil)
    {
        _defaultFacebookCell = [self.tableView dequeueReusableCellWithIdentifier:@"defaultFacebookCell"];
    }
    return _defaultFacebookCell;
}

- (UITableViewCell *)facebookPhotoCell
{
    if (_facebookPhotoCell == nil)
    {
        _facebookPhotoCell = [self.tableView dequeueReusableCellWithIdentifier:@"photoFacebookCell"];
    }
    return _facebookPhotoCell;
}

- (void)setFacebookArrayTableData:(NSArray *)facebookArrayTableData
{
    _facebookArrayTableData = facebookArrayTableData;
    [self.tableView reloadData];
}

- (NSArray *)facebookArrayTableData
{
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
        
        //This method will request the full comments array from the delegate and
        
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //Retireve the User Defaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            //Pull the accessToken, and expirationDate from the facebook instance, and
            //save them to the user defaults
            [defaults setObject:[result valueForKey:@"id"] forKey:@"userNameID"];
            self.userNameID = [defaults objectForKey:@"userNameID"];
            [defaults synchronize];
            
            
            [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.logInOutButton.title = @"Log Out";
                });
            }];
        }];
    } else 
    {
        self.logInOutButton.title = @"Login";
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
    self.tableView.allowsSelection = NO;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self commonInit];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    //When the view disappears the code in this fucnction removes all delegation to this class
    //and it stops the loading
    
    //This is required incase a connection request is in progress when the view disappears
    //[self.facebookRequest setDelegate:nil];
    
    //This is required incase a facebook method completes after the view has disappered
    
    
    //Super method
    [super viewDidDisappear:animated];
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
    
    //Pull the accessToken, and expirationDate from the facebook instance, and
    //save them to the user defaults
    self.userNameID = [defaults objectForKey:@"userNameID"];
    
    //initialize the activity indicator, set it to the center top of the view, and
    //start it animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicator.hidesWhenStopped = YES;
    
    //Save the previous rightBarButtonItem so it can be put back on once the View is done loading
    self.oldBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    [self openSessionWithAllowLoginUI:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
        }];
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentWebView:) 
                                                 name:@"urlSelected"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:FBSessionStateChangedNotification
     object:nil];
    
    
}

#pragma mark - Table view data source

- (NSString *)keyForMainCellLabelText
{
    return FACEBOOK_CONTENT_TITLE;
}

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
    return [self.facebookArrayTableData count];
}

- (void)commentsButtonPushed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"detailView" sender:dictionaryData];
}

- (void)postImageButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"Photo" sender:[dictionaryData valueForKeyPath:@"object_id"]];
}

- (void)mainCommentsButtonPushed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"textInput" sender:dictionaryData];
}

- (void)likeButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/likes", [dictionaryData valueForKeyPath:@"id"]];
    UIButton *likeButton = sender;

    if ([likeButton.titleLabel.text isEqualToString:@"Like"])
    {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        [FBRequestConnection startWithGraphPath:graphAPIString parameters:[[NSMutableDictionary alloc] init] HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSLog(@"%@", result);
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        [likeButton setTitle:@"Unlike" forState:UIControlStateNormal]; 
        
    }
    else {
        //Set the right navigation bar button item to the activity indicator
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        
        //Since facebook had to log in, data will need to be requested, start the activity indicator
        [self.activityIndicator startAnimating];
        
        [FBRequestConnection startWithGraphPath:graphAPIString parameters:[[NSMutableDictionary alloc] init] HTTPMethod:@"DELETE" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self processPostRequestWithConnection:connection withResults:result postError:error];
        }];
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    
}

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string withDictionaryForComment:(NSDictionary *)dictionary;
{
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [dictionary valueForKeyPath:@"id"]];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:string, @"message", nil];
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    [FBRequestConnection startWithGraphPath:graphAPIString parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self processPostRequestWithConnection:connection withResults:result postError:error];
    }];
}

- (void)textViewDidCancel:(UITextView *)textView
{
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.facebookArrayTableData objectAtIndex:[indexPath row]];

    
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
        profileImageView = (UIImageView *)[cell.contentView viewWithTag:1];
        postedByLabel = (UILabel *)[cell.contentView viewWithTag:2];
        textView = (UITextView *)[cell.contentView viewWithTag:3];
        commentButton = (UIButton *)[cell.contentView viewWithTag:4];
        [commentButton addTarget:self action:@selector(commentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        
        addCommentButton = (UIButton *)[cell.contentView viewWithTag:5];
        [addCommentButton addTarget:self action:@selector(mainCommentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [addCommentButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        
        buttonImage = (UIButton *)[cell.contentView viewWithTag:6];
        [buttonImage addTarget:self action:@selector(postImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        likeButton = (UIButton *)[cell.contentView viewWithTag:7];
        [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [likeButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateApplication];
        
        datePosted = (UILabel *)[cell.contentView viewWithTag:8];

    }
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForMainCellLabelText]];
    NSDate *date = [[NSDate alloc] initFacebookDateFormatWithString:[dictionaryForCell valueForKey:@"created_time"]];
    datePosted.text = date.socialDate;
    
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
    
    id fromName = [dictionaryForCell valueForKeyPath:@"from.name"];
    if ([fromName isKindOfClass:[NSString class]]) postedByLabel.text = fromName;
    
    BOOL matchFound = NO;
    
    id likes = [dictionaryForCell valueForKeyPath:@"likes.data.id"];
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
    if (matchFound == NO)
    {
        [likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    
    //Set the cell text label's based upon the table contents array location
    textView.text = mainTextLabel;
    CGFloat oldSizeHeight = textView.frame.size.height;
    
    [textView resizeTextViewForWidth:self.tableView.frame.size.width - 20];
    CGFloat heightChange = textView.frame.size.height - oldSizeHeight;
    
    NSNumber *count = [dictionaryForCell valueForKeyPath:@"comments.count"];
    NSString *commentsString = [[NSString alloc] initWithFormat:@"%@ Comments", count];
    [commentButton setTitle:commentsString forState:UIControlStateNormal];
    profileImageView.image = nil;
    
    if ([typeOfPost isEqualToString:@"photo"])
    {
        buttonImage.imageView.image = nil;
        buttonImage.frame = CGRectMake(buttonImage.frame.origin.x, buttonImage.frame.origin.y + heightChange, buttonImage.frame.size.width, buttonImage.frame.size.height);
        commentButton.frame = CGRectMake(commentButton.frame.origin.x, commentButton.frame.origin.y + heightChange, commentButton.frame.size.width, commentButton.frame.size.height);
        addCommentButton.frame = CGRectMake(addCommentButton.frame.origin.x, addCommentButton.frame.origin.y + heightChange, addCommentButton.frame.size.width, addCommentButton.frame.size.height);
        likeButton.frame = CGRectMake(likeButton.frame.origin.x, likeButton.frame.origin.y + heightChange, likeButton.frame.size.width, likeButton.frame.size.height);
    }
    else
    {
        
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
    
    //if (![type isEqualToString:@"photo"]) return;
    
    __block NSData *picture = [self.photoDictionary objectForKey:pictureID];
    __block NSData *profilePictureData = [self.photoDictionary objectForKey:profileFromId];
    
    NSString *urlStringForProfilePicture = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture/type=small", profileFromId];
    NSString *urlStringForPicture = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?type=normal", pictureID];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        if (!picture)
        {
            if (pictureID)
            {
                NSURL *url = [[NSURL alloc] initWithString:urlStringForPicture];
                picture = [NSData dataWithContentsOfURL:url];
                if (picture) [self.photoDictionary setObject:picture forKey:pictureID];
                NSLog(@"Picture");
            }
        }
        
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
                UIButton *buttonImage = (UIButton *)[cell.contentView viewWithTag:6];
                UIImage *image = [UIImage imageWithData:picture];
                buttonImage.contentMode = UIViewContentModeScaleAspectFit;
                UIImage *scaledImage = [self getScaledImage:image insideButton:buttonImage];
                [buttonImage setImage:scaledImage forState:UIControlStateNormal];
                
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
    NSString *mainTextLabel = [dictionaryForCell valueForKey:[self keyForMainCellLabelText]];
    
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
        if ([sender isKindOfClass:[NSString class]])
        {
            [segue.destinationViewController setFacebookPhotoObjectID:sender];
        }
    }
    else if ([segue.identifier isEqualToString:@"textInput"])
    {
        [segue.destinationViewController setTextEntryDelegate:self];
        [segue.destinationViewController setDictionaryForComment:sender];
        [segue.destinationViewController setSubmitButtonTitle:@"Post"];
        [segue.destinationViewController setWindowTitle:@"Comment"];
    }
}

- (void)processGetFeedRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    
    if (error)
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
        
        //[self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
    });
}

- (void)processPostRequestWithConnection:(FBRequestConnection *)connection withResults:(id)result postError:(NSError *)error
{
    if (error)
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
    else {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] completionHandler:^(FBRequestConnection *connection, id result, NSError  *error) {
            [self processGetFeedRequestWithConnection:connection withResults:result postError:error];
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

#pragma mark - Facebook Initialization Method

#pragma mark - Facebook Dialog Methods

- (IBAction)postToWall:(id)sender 
{
    /*NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.appConfiguration.facebookID, @"app_id",
                                   [NSString stringWithFormat:@"Post to %@'s Wall", self.appConfiguration.appName], @"description",
                                   self.appConfiguration.facebookFeedToRequest, @"to",
                                   nil];*/
    
    //[self.facebook dialog:@"feed" andParams:params andDelegate:self];
}


#pragma mark - Facebook Session Delegate Methods

- (void)fbSessionInvalidated
{
    //Do nothing here for now, stubbed out to get rid of compiler warning
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setLogInOutButton:nil];
    [super viewDidUnload];
}

- (void)refresh {
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    //[self.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.appConfiguration.facebookFeedToRequest] andDelegate:self];
}

- (void) presentWebView:(NSNotification *) notification
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
    NSArray *params = [[NSArray alloc] initWithObjects:@"publish_stream", nil];
    BOOL open = [FBSession openActiveSessionWithPermissions:params allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [self sessionStateChanged:session state:state error:error];
    }];
    return open;
}

- (void) closeSession {
    [FBSession.activeSession closeAndClearTokenInformation];
}

@end
