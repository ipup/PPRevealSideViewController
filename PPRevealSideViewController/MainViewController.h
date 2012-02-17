//
//  MainViewController.h
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
{
    BOOL _animated;
    __weak IBOutlet UISwitch *_shadowSwitch;
    __weak IBOutlet UISwitch *_bounceSwitch;
    __weak IBOutlet UISwitch *_closeFullSwitch;
    __weak IBOutlet UISwitch *_keepOffsetSwitch;
}
- (IBAction)showUp:(id)sender;
- (IBAction)showDown:(id)sender;
- (IBAction)changeAnimated:(id)sender;
- (IBAction)changeShadow:(id)sender;
- (IBAction)changeBounce:(id)sender;
- (IBAction)changeCloseFull:(id)sender;
- (IBAction)changeKeepOffset:(id)sender;
- (IBAction)pushOldLeft:(id)sender;
- (IBAction)pushOldRight:(id)sender;
@end
