//
//  ImageViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface ImageViewController ()

@end

@implementation ImageViewController
@synthesize scrollView = _scrollView;
@synthesize navigationBar = _navigationBar;
@synthesize imageView = _imageView;
@synthesize imageForImageView = _imageForImageView;
@synthesize facebookPhotoObjectID = _facebookPhotoObjectID;

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
    self.scrollView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem *oldBarButtonItem = self.navigationBar.topItem.leftBarButtonItem;
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    UIBarButtonItem *spinnerButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    self.navigationBar.topItem.rightBarButtonItem = spinnerButton;
    
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@", self.facebookPhotoObjectID] completionHandler:^(FBRequestConnection *connection, id result, NSError  *error) {
        NSString *stringURL = nil;
        NSURL *urlStringForProfile = nil;
        
        
        if (result) stringURL = [result valueForKey:@"source"];
        if (stringURL) urlStringForProfile = [[NSURL alloc] initWithString:stringURL];
        UIImage *tmpImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:urlStringForProfile]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageForImageView = tmpImage;
                self.scrollView.zoomScale = 1;
                self.imageView.image = self.imageForImageView;
                [self.imageView sizeToFit];
                self.scrollView.contentSize = self.imageView.bounds.size;
                CGRect tmpRect = CGRectMake(0, 0, self.imageForImageView.size.width, self.imageForImageView.size.height);
                [self.scrollView zoomToRect:tmpRect animated:NO];
                self.navigationBar.topItem.leftBarButtonItem = oldBarButtonItem;
                [spinner stopAnimating];
            });
    }];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setScrollView:nil];
    [self setNavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.scrollView.zoomScale = 1;
    //self.imageView.image = self.imageForImageView;
    [self.imageView sizeToFit];
    self.scrollView.contentSize = self.imageView.bounds.size;
    //CGRect tmpRect = CGRectMake(0, 0, self.imageForImageView.size.width, self.imageForImageView.size.height);
    //[self.scrollView zoomToRect:tmpRect animated:NO];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView //1 line
{
    return self.imageView;
}
- (IBAction)doneButtonPressed:(id)sender 
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
