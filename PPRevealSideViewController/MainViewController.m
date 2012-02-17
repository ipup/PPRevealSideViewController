//
//  MainViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "TableViewController.h"
#import "PopedViewController.h"
@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Left"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showLeft)];
    self.navigationItem.leftBarButtonItem = PP_AUTORELEASE(left);
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Right"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showRight)];
    self.navigationItem.rightBarButtonItem = PP_AUTORELEASE(right);
    
    _animated = YES;
}

- (void)viewDidUnload
{
    _shadowSwitch = nil;
    _bounceSwitch = nil;
    _closeFullSwitch = nil;
    _keepOffsetSwitch = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    PPRevealSideOptions options = self.revealSideViewController.options;
    _shadowSwitch.on = (options & PPRevealSideOptionsShowShadows);
    _bounceSwitch.on = (options & PPRevealSideOptionsBounceAnimations);
    _closeFullSwitch.on = (options & PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection);
    _keepOffsetSwitch.on = (options & PPRevealSideOptionsKeepOffsetOnRotation);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void) showLeft {
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionLeft animated:_animated];
    PP_RELEASE(c);
}

- (void) showRight {
    PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionRight animated:_animated];
    PP_RELEASE(c);
}

- (IBAction)showUp:(id)sender {
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionTop animated:_animated];
    PP_RELEASE(c);
}

- (IBAction)showDown:(id)sender {
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom animated:_animated];
    PP_RELEASE(c);
}

- (IBAction)changeAnimated:(id)sender {
    _animated = !_animated;
}

- (void) setOption:(PPRevealSideOptions)option fromSwitch:(UISwitch*)sw {
    if (sw.on)
        [self.revealSideViewController setOption:option];
    else
        [self.revealSideViewController resetOption:option]; 
}

- (IBAction)changeShadow:(id)sender {
    [self setOption:PPRevealSideOptionsShowShadows fromSwitch:sender];
}

- (IBAction)changeBounce:(id)sender {
    [self setOption:PPRevealSideOptionsBounceAnimations fromSwitch:sender];
}

- (IBAction)changeCloseFull:(id)sender {
    [self setOption:PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection fromSwitch:sender];
}

- (IBAction)changeKeepOffset:(id)sender {
    [self setOption:PPRevealSideOptionsKeepOffsetOnRotation fromSwitch:sender];
}

- (IBAction)pushOldLeft:(id)sender {
    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft animated:YES];
}

- (IBAction)pushOldRight:(id)sender {
    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionRight animated:YES];
}

@end
