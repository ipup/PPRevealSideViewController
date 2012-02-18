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
    __weak IBOutlet UISwitch *_resizeSwitch;
    __weak IBOutlet UILabel *_labelOffset;
    __weak IBOutlet UISlider *_offsetSlider;
    
    __weak IBOutlet UISwitch *_panNavOpenedSwitch;
    __weak IBOutlet UISwitch *_panContentOpenedSwitch;
    __weak IBOutlet UISwitch *_panNavClosedSwitch;
    __weak IBOutlet UISwitch *_panContentClosedSwitch;
    __weak IBOutlet UISwitch *_tapNavSwitch;
    __weak IBOutlet UISwitch *_tapContentSwitch;
    CGFloat _offset;
}
- (IBAction)changeOffset:(id)sender;
- (IBAction)showUp:(id)sender;
- (IBAction)showDown:(id)sender;
- (IBAction)changeAnimated:(id)sender;
- (IBAction)changeShadow:(id)sender;
- (IBAction)changeBounce:(id)sender;
- (IBAction)changeCloseFull:(id)sender;
- (IBAction)changeKeepOffset:(id)sender;
- (IBAction)changeResize:(id)sender;
- (IBAction)pushOldLeft:(id)sender;
- (IBAction)pushOldRight:(id)sender;
- (IBAction)changePanOpened:(id)sender;
- (IBAction)changePanClosed:(id)sender;
- (IBAction)changeTap:(id)sender;
@end
