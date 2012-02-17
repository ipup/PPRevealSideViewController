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
}
- (IBAction)showUp:(id)sender;
- (IBAction)showDown:(id)sender;
- (IBAction)changeAnimated:(id)sender;
- (IBAction)changeShadow:(id)sender;
- (IBAction)changeBounce:(id)sender;
- (IBAction)changeCloseFull:(id)sender;
@end
