//
//  ImagoDeiTextEntryViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextEntryViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TextEntryViewController ()
@end

@implementation TextEntryViewController
@synthesize textView;
@synthesize submitButton;
@synthesize navigationBar = _navigationBar;
@synthesize imageView = _imageView;
@synthesize textEntryDelegate = _textEntryDelegate;
@synthesize dictionaryForComment = _dictionaryForComment;
@synthesize submitButtonTitle = _submitButtonTitle;
@synthesize windowTitle = _windowTitle;
@synthesize type = _type;
@synthesize imagePickerPopover = _imagePickerPopover;
@synthesize supportPicture = _supportPicture;

- (void)textChanged:(NSNotification *) notification
{
    id object = [notification object];
    if ([object isKindOfClass:[UITextView class]])
    {
        UITextView *notificationTextView = object;
        if ([notificationTextView hasText]) self.submitButton.enabled = YES;
        else self.submitButton.enabled = NO;
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(textChanged:) 
                                                 name:UITextViewTextDidChangeNotification 
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidChangeNotification
                                                  object:nil];
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setSubmitButton:nil];
    [self setNavigationBar:nil];
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.submitButton.enabled = NO;
    [self.textView becomeFirstResponder];
    
    //self.textView.layer.cornerRadius = 10;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 10.0;

    
    if (self.submitButtonTitle) self.submitButton.title = self.submitButtonTitle;
    if (self.windowTitle) self.navigationBar.topItem.title = self.windowTitle;
    
    if (self.supportPicture)
    {
        UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePicture:)];
        UIBarButtonItem *currentBarButtonItem = self.navigationBar.topItem.rightBarButtonItem;
        self.navigationBar.topItem.rightBarButtonItems = [NSArray arrayWithObjects: currentBarButtonItem, cameraButton, nil];
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (IBAction)takePicture:(id)sender 
{
    if ([self.imagePickerPopover isPopoverVisible])
    {
        //If the popover is already up, get rid of it
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    //If our device has a camera, we want to take a picture, otherwise, we
    //just pick from photo library
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    else
    {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    [imagePicker setDelegate:self];
    
    imagePicker.allowsEditing = YES;
    
    //Place image picker on the screen
    //Check for iPad device before instantiating the popover controller
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        //Create a new popover controller that will display the image picker
        self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.imagePickerPopover setDelegate:self];
        
        //Display the popover controller; sender
        //is the camera bar button item
        [self.imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Get picked image from infor dictionary
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!image) 
    {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    self.imageView.image = image;
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.imageView.frame.origin.x, self.textView.frame.size.height);
    [self.view bringSubviewToFront:self.imageView];
    
    //If on the phone, the image picker is presented modally.  Dismiss it.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"User dismissed popover");
    self.imagePickerPopover = nil;
}

- (IBAction)cancelButtonPressed:(id)sender 
{
    [self.textEntryDelegate textViewDidCancel:self.textView];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postButtonPushed:(id)sender 
{
    if ([self.textEntryDelegate respondsToSelector:@selector(textView:didFinishWithString:withDictionary:andImage:forType:)])
    {
        [self.textEntryDelegate textView:self.textView didFinishWithString:self.textView.text withDictionary:self.dictionaryForComment andImage:self.imageView.image forType:self.type];
    }
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
