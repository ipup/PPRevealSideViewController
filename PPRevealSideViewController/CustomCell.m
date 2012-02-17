//
//  CustomCell.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 17/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [self.contentView addSubview:_disclosureButton];
        _disclosureButton.frame = CGRectMake(0, 0, 40, 40);
        self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];    
    CGRect newFrame = _disclosureButton.frame;
    newFrame.origin.x = CGRectGetWidth(self.contentView.frame)- 5.0 /*margin*/ - self.revealSideInset.right - CGRectGetWidth(newFrame);
    newFrame.origin.y = floorf((CGRectGetHeight(self.frame) - CGRectGetHeight(_disclosureButton.frame))/2.0);
    _disclosureButton.frame = newFrame;
    PPLog(@"%@", NSStringFromCGRect(newFrame));
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
