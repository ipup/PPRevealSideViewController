//
//  LeftViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "TableViewController.h"
#import "CustomCell.h"
#import "PopedViewController.h"
#import "MainViewController.h"
#import "SecondViewController.h"
#import "ThirdViewController.h"
#import "WebViewController.h"

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    @try {
        [self.tableView removeObserver:self
                            forKeyPath:@"revealSideInset"];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView addObserver:self 
                     forKeyPath:@"revealSideInset"
                        options:NSKeyValueObservingOptionNew
                        context:NULL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.tableView removeObserver:self
                        forKeyPath:@"revealSideInset"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"revealSideInset"]) {
        UIEdgeInsets newInset = self.tableView.contentInset;
        newInset.top = self.tableView.revealSideInset.top;
        newInset.bottom = self.tableView.revealSideInset.bottom;
        self.tableView.contentInset = newInset;
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) dealloc 
{
    @try{
        [self.tableView removeObserver:self
                            forKeyPath:@"revealSideInset"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
#if !PP_ARC_ENABLED
    [super dealloc];
#endif
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CustomCell *cell = (CustomCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = PP_AUTORELEASE([[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]);
    }
    switch (indexPath.row % 6) {
        case 0:
            cell.myLabel.text = @"Go to root or push if nav";
            break;
        case 1:
            cell.myLabel.text = @"Push a new right";
            break; 
        case 2:
            cell.myLabel.text = @"Push new left";
            break;
        case 3:
            cell.myLabel.text = @"Pop new center";
            break;
        case 4:
            cell.myLabel.text = @"Pop main center";
            break;
        case 5:
            cell.myLabel.text = @"Pop Web view center";
            break;
        default:
            break;
    }
    cell.revealSideInset = self.tableView.revealSideInset;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row % 6) {
        case 0:
            if (self.navigationController) {
                ThirdViewController *c = [[ThirdViewController alloc] initWithNibName:@"ThirdViewController" bundle:nil];
                [self.navigationController pushViewController:c animated:YES];
                PP_RELEASE(c);
            }
            else
            [self.revealSideViewController popViewControllerAnimated:YES];
            break;
        case 1:
        {
                PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil];
                [self.revealSideViewController pushViewController:c
                                                      onDirection:PPRevealSideDirectionRight animated:YES];
                PP_RELEASE(c);
        }
            break; 
        case 2:
        {
            PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil];
            // Since we are in the left already, we force the pop then push
            [self.revealSideViewController pushViewController:c
                                                  onDirection:PPRevealSideDirectionLeft 
                                                     animated:YES
                                               forceToPopPush:YES];
            PP_RELEASE(c);
        }
            break;
        case 3:
        {
            SecondViewController *c = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
            [self.revealSideViewController popViewControllerWithNewCenterController:c 
                                                                           animated:YES];
            PP_RELEASE(c);
        }
            break;
        case 4:
        {
            MainViewController *c = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
            UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
            [self.revealSideViewController popViewControllerWithNewCenterController:n 
                                                                           animated:YES];
            PP_RELEASE(c);
            PP_RELEASE(n);
        }            
            break;
        case 5:
        {
            WebViewController *c = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
            UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
            [self.revealSideViewController popViewControllerWithNewCenterController:n 
                                                                           animated:YES];
            PP_RELEASE(c);
            PP_RELEASE(n);
        }            
            break;
        default:
            break;
    }
}

@end
