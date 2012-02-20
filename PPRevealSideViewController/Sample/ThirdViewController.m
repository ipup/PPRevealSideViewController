//
//  ThirdViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 18/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "ThirdViewController.h"
#import "TableViewController.h"

@implementation ThirdViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)pushNavController:(id)sender {
    ThirdViewController *c = [[ThirdViewController alloc] initWithNibName:@"ThirdViewController" bundle:nil];
    [self.navigationController pushViewController:c animated:YES];
    PP_RELEASE(c);
}

- (IBAction)popPreviousLeft:(id)sender {
    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft animated:YES];
}

- (IBAction)pushNewRight:(id)sender {
    TableViewController *t = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:t];
    [self.revealSideViewController pushViewController:n
                                          onDirection:PPRevealSideDirectionTop
                                             animated:YES];
    PP_RELEASE(t);
    PP_RELEASE(n);
}
@end
