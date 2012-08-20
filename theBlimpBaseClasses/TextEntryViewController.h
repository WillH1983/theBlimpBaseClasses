//
//  ImagoDeiTextEntryViewController.h
//  ImagoDei
//
//  Created by Will Hindenburg on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextEntryDelegate <NSObject>
- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string withDictionaryForComment:(NSDictionary *)dictionary;

- (void)textViewDidCancel:(UITextView *)textView;
@end

@interface TextEntryViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *submitButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, weak) id <TextEntryDelegate> textEntryDelegate;
@property (nonatomic, strong) NSDictionary *dictionaryForComment;
@property (nonatomic, strong) NSString *submitButtonTitle;
@property (nonatomic, strong) NSString *windowTitle;
@end
