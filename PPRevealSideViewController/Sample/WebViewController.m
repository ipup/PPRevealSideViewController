//
//  WebViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 22/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController
@synthesize webView;

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
    
    // Remember, it works best if the page is scaled to fit the screen so that it do not interfere with the panning gesture of the UIWebView
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.ipup.pro"]]];

    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Push old"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(pushOld)];
    self.navigationItem.leftBarButtonItem = PP_AUTORELEASE(left);   
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Disable NonControlleur bounce"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(disableBouncing)];
    self.navigationItem.rightBarButtonItem = PP_AUTORELEASE(right);
}

- (void) pushOld {
    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft
                                                           animated:YES];    
}

- (void) disableBouncing {
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionNone];

    // could be PPRevealSideDirectionLeft | PPRevealSideDirectionRight
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
