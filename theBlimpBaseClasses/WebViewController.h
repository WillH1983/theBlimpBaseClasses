//
//  WebViewController.h
//  ImagoDei
//
//  Created by Will Hindenburg on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^WebViewCompletionBlock)(void);

@interface WebViewController : UIViewController
@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) NSString *titleForWebView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) UINavigationBar *navigationBar;
@property (nonatomic, strong) WebViewCompletionBlock completionBlock;

- (id)initWithToolbar:(BOOL)yesOrNo;

@end
