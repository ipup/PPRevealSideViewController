//
//  MainViewController.h
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
{
    BOOL _animated;
    IBOutlet UISwitch *_shadowSwitch;
    IBOutlet UISwitch *_bounceSwitch;
    IBOutlet UISwitch *_closeFullSwitch;
    IBOutlet UISwitch *_keepOffsetSwitch;
    IBOutlet UISwitch *_resizeSwitch;
    IBOutlet UILabel *_labelOffset;
    IBOutlet UISlider *_offsetSlider;
    
    IBOutlet UISwitch *_panNavOpenedSwitch;
    IBOutlet UISwitch *_panContentOpenedSwitch;
    IBOutlet UISwitch *_panNavClosedSwitch;
    IBOutlet UISwitch *_panContentClosedSwitch;
    IBOutlet UISwitch *_tapNavSwitch;
    IBOutlet UISwitch *_tapContentSwitch;
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
- (IBAction)pushNav:(id)sender;
- (IBAction)presentModal:(id)sender;
@end
