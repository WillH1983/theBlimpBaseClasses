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
@synthesize textEntryDelegate = _textEntryDelegate;
@synthesize dictionaryForComment = _dictionaryForComment;
@synthesize submitButtonTitle = _submitButtonTitle;
@synthesize windowTitle = _windowTitle;

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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.submitButton.enabled = NO;
    [self.textView becomeFirstResponder];
    
    self.textView.layer.cornerRadius = 10;   
    self.textView.clipsToBounds = YES;
    
    if (self.submitButtonTitle) self.submitButton.title = self.submitButtonTitle;
    if (self.windowTitle) self.navigationBar.topItem.title = self.windowTitle;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)cancelButtonPressed:(id)sender 
{
    [self.textEntryDelegate textViewDidCancel:self.textView];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postButtonPushed:(id)sender 
{
    if ([self.textEntryDelegate respondsToSelector:@selector(textView:didFinishWithString:withDictionaryForComment:)])
    {
        [self.textEntryDelegate textView:self.textView didFinishWithString:self.textView.text withDictionaryForComment:self.dictionaryForComment];
    }
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
