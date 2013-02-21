//
//  MainViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "MainViewController.h"
#import "TableViewController.h"
#import "PopedViewController.h"
#import "SecondViewController.h"
#import "ThirdViewController.h"
#import "ModalViewController.h"

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
    
    _offsetSlider.value = 70.0;
    [self changeOffset:_offsetSlider];
    
    
    // reinit the bouncing directions (should not be done in your own implementation, this is just for the sample)
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionBottom | PPRevealSideDirectionLeft | PPRevealSideDirectionRight | PPRevealSideDirectionTop];

    _animated = YES;
    
}

- (void)viewDidUnload
{
    _shadowSwitch = nil;
    _bounceSwitch = nil;
    _closeFullSwitch = nil;
    _keepOffsetSwitch = nil;
    _resizeSwitch = nil;
    _labelOffset = nil;
    _offsetSlider = nil;
    _panNavOpenedSwitch = nil;
    _panContentOpenedSwitch = nil;
    _panNavClosedSwitch = nil;
    _panContentClosedSwitch = nil;
    _tapNavSwitch = nil;
    _tapContentSwitch = nil;
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
    _resizeSwitch.on = (options & PPRevealSideOptionsResizeSideView);
    
    PPRevealSideInteractions inter = self.revealSideViewController.panInteractionsWhenOpened;
    _panNavOpenedSwitch.on = (inter & PPRevealSideInteractionNavigationBar);
    _panContentOpenedSwitch.on = (inter & PPRevealSideInteractionContentView);
    
    inter = self.revealSideViewController.panInteractionsWhenClosed;
    _panNavClosedSwitch.on = (inter & PPRevealSideInteractionNavigationBar);
    _panContentClosedSwitch.on = (inter & PPRevealSideInteractionContentView);
    
    inter = self.revealSideViewController.tapInteractionsWhenOpened;
    _tapNavSwitch.on = (inter & PPRevealSideInteractionNavigationBar);
    _tapContentSwitch.on = (inter & PPRevealSideInteractionContentView);

}

- (void) preloadLeft {
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.revealSideViewController preloadViewController:c
                                                 forSide:PPRevealSideDirectionLeft
                                              withOffset:_offset];
    PP_RELEASE(c);
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preloadLeft) object:nil];
    [self performSelector:@selector(preloadLeft) withObject:nil afterDelay:0.3];
}

- (void) showLeft
{
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];

    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionLeft withOffset:_offset animated:_animated completion:^{
            PPRSLog(@"This is the end!");
        }];
    else // NB: we could have use directly completion method with nil parameter, but I just want to make sure the app is working without using it (pseudo regression test)
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionLeft withOffset:_offset animated:_animated];
    
    PP_RELEASE(c);
}

- (void) showRight {
    PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionRight withOffset:_offset animated:_animated completion:^{
            PPRSLog(@"This is the end!");
        }];
    else
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionRight withOffset:_offset animated:_animated];
    
    PP_RELEASE(c);
}

- (IBAction)changeOffset:(id)sender {
    UISlider *s = (UISlider*)sender;
    _offset = floorf(s.value);
    _labelOffset.text = [NSString stringWithFormat:@"Offset %.0f", _offset];
    
    [self.revealSideViewController changeOffset:_offset
                                forDirection:PPRevealSideDirectionRight];
    [self.revealSideViewController changeOffset:_offset
                                   forDirection:PPRevealSideDirectionLeft];
    [self.revealSideViewController changeOffset:_offset
                                   forDirection:PPRevealSideDirectionTop];
    [self.revealSideViewController changeOffset:_offset
                                   forDirection:PPRevealSideDirectionBottom];
    
}

- (IBAction)showUp:(id)sender {
    TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushViewController:n onDirection:PPRevealSideDirectionTop withOffset:_offset animated:_animated completion:^{
            PPRSLog(@"This is the end!");
        }];
    else
        [self.revealSideViewController pushViewController:n onDirection:PPRevealSideDirectionTop withOffset:_offset animated:_animated];
    PP_RELEASE(c);
    PP_RELEASE(n);
}

- (IBAction)showDown:(id)sender {
    PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom withOffset:_offset animated:_animated completion:^{
            PPRSLog(@"This is the end!");
        }];
    else
        [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom withOffset:_offset animated:_animated];
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

- (IBAction)changeResize:(id)sender {
    [self setOption:PPRevealSideOptionsResizeSideView fromSwitch:sender];
}

- (IBAction)pushOldLeft:(id)sender {
    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft withOffset:_offset animated:YES completion:^{
            PPRSLog(@"This is the end!");
        }];
    else
        [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft withOffset:_offset animated:YES];
}

- (IBAction)pushOldRight:(id)sender {
    if (_useCompletionBlock.isOn)
        [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionRight withOffset:_offset animated:YES completion:^{
            PPRSLog(@"This is the end!");
        }];
    else
        [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionRight withOffset:_offset animated:YES];
}

- (IBAction)changePanOpened:(id)sender {
    PPRevealSideInteractions inter = PPRevealSideInteractionNone;
    if (_panNavOpenedSwitch.on)
        inter |= PPRevealSideInteractionNavigationBar;
    if (_panContentOpenedSwitch.on)
        inter |= PPRevealSideInteractionContentView;
    
    self.revealSideViewController.panInteractionsWhenOpened = inter;
}

- (IBAction)changePanClosed:(id)sender {
    PPRevealSideInteractions inter = PPRevealSideInteractionNone;
    if (_panNavClosedSwitch.on)
        inter |= PPRevealSideInteractionNavigationBar;
    if (_panContentClosedSwitch.on)
        inter |= PPRevealSideInteractionContentView;
    
    self.revealSideViewController.panInteractionsWhenClosed = inter;
}

- (IBAction)changeTap:(id)sender {
    PPRevealSideInteractions inter = PPRevealSideInteractionNone;
    if (_tapNavSwitch.on)
        inter |= PPRevealSideInteractionNavigationBar;
    if (_tapContentSwitch.on)
        inter |= PPRevealSideInteractionContentView;
    
    self.revealSideViewController.tapInteractionsWhenOpened = inter;
}

- (void)changeCompletion:(id)sender
{
    // nothing to do
}

- (IBAction)switchCentral:(id)sender {
	PPRSLog(@"switchCentral");
	SecondViewController *c = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
	[self.revealSideViewController replaceCentralViewControllerWithNewController:c animated:YES animationDirection:PPRevealSideDirectionLeft completion:^{
		PPRSLog(@"Poped with new controller");
	}];
	PP_RELEASE(c);
	
//	__block __typeof(&*self) weakSelf = self;
//	[self.revealSideViewController openCompletelySide:PPRevealSideDirectionLeft animated:YES completion:^{
//		NSLog(@"opened completely");
//		SecondViewController *c = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
//		[weakSelf.revealSideViewController popViewControllerWithNewCenterController:c animated:YES completion:^{
//			NSLog(@"poped with new controller");
//		}];
//		PP_RELEASE(c);
//	}];
}

- (IBAction)pushNav:(id)sender {
    ThirdViewController *c = [[ThirdViewController alloc] initWithNibName:@"ThirdViewController" bundle:nil];
    [self.navigationController pushViewController:c animated:YES];
    PP_RELEASE(c);
}

- (IBAction)presentModal:(id)sender 
{
    ModalViewController *m = [[ModalViewController alloc] initWithNibName:@"ModalViewController" bundle:nil];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:m];
    if (PPSystemVersionGreaterOrEqualThan(5.0))
        [self presentModalViewController:n animated:YES];
    else
        [self.revealSideViewController presentModalViewController:n animated:YES];
    
    PP_RELEASE(m);
    PP_RELEASE(n);
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark iOS 6

- (BOOL)shouldAutorotate{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)])
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
            return UIInterfaceOrientationMaskAll;
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
