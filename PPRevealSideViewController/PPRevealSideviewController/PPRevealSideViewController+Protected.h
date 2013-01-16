//
//  PPRevealSideViewController+Protected.h
//  PPRevealSideViewController
//
//  Created by Marius Rackwitz on 16.01.13.
//
//

#import "PPRevealSideViewController.h"


@interface PPRevealSideViewController (Protected)

- (void)setRootViewController:(UIViewController *)controller replaceToOrigin:(BOOL)replace;
- (void)setRootViewController:(UIViewController *)controller;

- (void)addShadow;
- (void)removeShadow;
- (void)handleShadows;

- (void)informDelegateWithOptionalSelector:(SEL)selector withParam:(id)param;

- (void)popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController*)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset;

- (void)addGesturesToCenterController;
- (void)addPanGestureToController:(UIViewController *)controller;
- (void)addTapGestureToController:(UIViewController *)controller;
- (void)addGesturesToController:(UIViewController *)controller;
- (void)removeAllPanGestures;
- (void)removeAllTapGestures;
- (void)removeAllGestures;
- (void)setOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;
- (void)removeControllerFromView:(UIViewController *)controller animated:(BOOL)animated;

- (BOOL)isLeftControllerClosed;
- (BOOL)isRightControllerClosed;
- (BOOL)isTopControllerClosed;
- (BOOL)isBottomControllerClosed;
- (BOOL)isOptionEnabled:(PPRevealSideOptions)option;
- (BOOL)canCrossOffsets;

- (PPRevealSideDirection)sideToClose;

- (CGRect)slidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;
- (CGRect)sideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction;

- (UIEdgeInsets)edgeInsetsForDirection:(PPRevealSideDirection)direction;

@end