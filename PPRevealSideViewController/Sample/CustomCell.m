//
//  CustomCell.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 17/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell
@synthesize myLabel = _myLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [self.contentView addSubview:_disclosureButton];
        _disclosureButton.frame = CGRectMake(0, 0, 40, 40);
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        _myLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _myLabel.backgroundColor = [UIColor clearColor];
        _myLabel.numberOfLines = 2;
        
        [self.contentView addSubview:_myLabel];
        
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];    
    CGRect newFrame = _disclosureButton.frame;
    newFrame.origin.x = CGRectGetWidth(self.contentView.frame)- 5.0 /*margin*/ - self.revealSideInset.right - CGRectGetWidth(newFrame);
    newFrame.origin.y = floorf((CGRectGetHeight(self.frame) - CGRectGetHeight(_disclosureButton.frame))/2.0);
    _disclosureButton.frame = newFrame;
    
    CGFloat margin = 3.0;
    
    _myLabel.frame = CGRectMake(margin, 
                                margin, 
                                CGRectGetMinX(newFrame)-2*margin,
                                CGRectGetHeight(self.frame) - 2*margin);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) dealloc {
    self.myLabel = nil;
#if !PP_ARC_ENABLED
    [super dealloc];
#endif
}

@end
