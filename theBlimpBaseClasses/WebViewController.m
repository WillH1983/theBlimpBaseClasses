//
//  WebViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebViewController.h"
#import "NSMutableDictionary+appConfiguration.h"

@interface WebViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIBarButtonItem *oldBarButtonItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIWebView *programmedWebView;
@property (nonatomic, strong) NSMutableDictionary *appConfiguration;
@end

@implementation WebViewController
@synthesize urlToLoad = _urlToLoad;
@synthesize webView = _webView;
@synthesize navigationBar = _navigationBar;
@synthesize titleForWebView = _titleForWebView;
@synthesize oldBarButtonItem = _oldBarButtonItem;
@synthesize activityIndicator = _activityIndicator;
@synthesize programmedWebView = _programmedWebView;
@synthesize completionBlock = _completionBlock;
@synthesize htmlString = _htmlString;
@synthesize htmlTitle = _htmlTitle;
@synthesize appConfiguration = _appConfiguration;

- (id)init
{
    return [self initWithToolbar:NO];
}

- (id)initWithToolbar:(BOOL)yesOrNo
{
    self = [super init];
    if (yesOrNo == YES)
    {
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        self.navigationBar.items = [[NSArray alloc] initWithObjects:navItem, nil];
        UIColor *standardColor = [UIColor colorWithRed:.7529 green:0.7372 blue:0.7019 alpha:1.0];
        self.navigationBar.tintColor = standardColor;
        [self.view addSubview:self.navigationBar];
        self.programmedWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44)];
    }
    else
    {
        self.programmedWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.programmedWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    }
    
    self.programmedWebView.delegate = self;
    self.programmedWebView.scalesPageToFit = YES;
    [self.view addSubview:self.programmedWebView];
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Pull the app delegate, this needs to be generic due to this class being included in other apps
    //Save the appConfiguration data from the app delegate
    id appDelegate = (id)[[UIApplication sharedApplication] delegate];
    self.appConfiguration = [appDelegate appConfiguration];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(donePressed:)];
    self.navigationBar.topItem.leftBarButtonItem = button;
    
    //Set the Imago Dei logo to the title view of the navigation controler
    //With the content mode set to AspectFit
    UIImage *logoImage = [UIImage imageNamed:self.appConfiguration.appNavigationBarLogoName];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = logoImageView;

    if (self.htmlString && self.urlToLoad && self.htmlTitle)
    {
        NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"style" ofType:@"css"];
        
        //do base url for css
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        NSString *html =[NSString stringWithFormat:@"<html><head><link rel=\"stylesheet\" href=\"%@\" type=\"text/css\" /></head><body><h1>%@</h1>%@</body></html>", cssPath,self.htmlTitle, self.htmlString];
        NSLog(@"%@",html);
        if (baseURL)[self.programmedWebView loadHTMLString:html baseURL:baseURL];
        if (baseURL)[self.webView loadHTMLString:html baseURL:baseURL];
        
    }
    else if (self.urlToLoad)
    {
        NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:self.urlToLoad];
        self.webView.scalesPageToFit = YES;
        [self.webView loadRequest:urlRequest];
        [self.programmedWebView loadRequest:urlRequest];
        self.title = @"Loading...";
        self.navigationBar.topItem.title = @"Loading...";
    }
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setNavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    NSString *tmpString = [url absoluteString];
    if ([tmpString isEqualToString:@"https://www.planningcenteronline.com/login"]) 
    {
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:self.completionBlock];
        return NO;
    }
    else return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
    [self.activityIndicator startAnimating];
    if ([UIApplication sharedApplication].isNetworkActivityIndicatorVisible == NO)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (!webView.isLoading)
    {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationBar.topItem.rightBarButtonItem = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.navigationBar.topItem.title = title;
        self.title = title;
        if (!self.title)
        {
            self.title = [self.programmedWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
            self.navigationBar.topItem.title = [self.programmedWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
        }
    }
}
- (IBAction)donePressed:(id)sender 
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.webView.scrollView sizeToFit];
    [self.programmedWebView.scrollView sizeToFit];
}

@end
