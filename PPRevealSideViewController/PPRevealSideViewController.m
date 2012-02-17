//
//  PPRevealSideViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PPRevealSideViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface PPRevealSideViewController (Private)
- (void) setRootViewController:(UIViewController*)controller;
- (void) handleShadows;
- (void) informDelegateWithOptionalSelector:(SEL)selector withParam:(id)param;

- (BOOL) isLeftControllerClosed;
- (BOOL) isRightControllerClosed;
- (BOOL) isTopControllerClosed;
- (BOOL) isBottomControllerClosed;

- (PPRevealSideDirection) getSideToClose;

- (CGRect) getSlidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;

@end

@implementation PPRevealSideViewController
@synthesize rootViewController = _rootViewController;
@synthesize showShadows = _showShadows;
@synthesize interactions = _interactions;
@synthesize bouncingAnimations = _bouncingAnimations;
@synthesize bouncingOffset = _bouncingOffset;
@synthesize delegate = _delegate;

- (id) initWithRootViewController:(UIViewController*)rootViewController {
    self = [super init];
    if (self) {
        [self setRootViewController:rootViewController];
        self.showShadows = YES;
        self.bouncingAnimations = YES;
        self.bouncingOffset = -1.0;
        self.interactions = PPRevealSideInteractionNavigationBar;
        _viewControllers = [[NSMutableDictionary alloc] init];
        _viewControllersOffsets = [[NSMutableDictionary alloc] init];

    }
    return self;
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = PP_AUTORELEASE([[UIView alloc] initWithFrame:PPScreenBounds()]);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.clipsToBounds = YES;
    self.view.autoresizesSubviews = YES;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

#pragma mark - Push and pop methods
#define DefaultOffset 50.0
#define DefaultOffsetBouncing 5.0

#define OpenAnimationTime 0.5
#define OpenAnimationTimeBouncingRatio 0.3

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self pushViewController:controller
                 onDirection:direction
                  withOffset:DefaultOffset
                    animated:animated];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated {
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPushController:) withParam:controller];
    
    // save the offset
    [_viewControllersOffsets setObject:[NSNumber numberWithFloat:offset] forKey:[NSNumber numberWithInt:direction]];
    
    // save the controller
    [_viewControllers setObject:controller forKey:[NSNumber numberWithInt:direction]];
    
    // get the side direction to close
    PPRevealSideDirection directionToClose = [self getSideToClose];
    
    if (controller.view.superview != self.view) [controller.view removeFromSuperview], [self.view insertSubview:controller.view belowSubview:_rootViewController.view];
    
    // replace with the bounds since IB add some offsets with the status bar if enabled
    controller.view.frame = controller.view.bounds;
    
    void (^closeAnimBlock)(void) = ^(void) {
        controller.view.hidden = NO;
        
        if (_bouncingAnimations && animated) // then we make an offset
            _rootViewController.view.frame = [self getSlidingRectForOffset:offset- ((_bouncingOffset == - 1.0) ? DefaultOffsetBouncing : _bouncingOffset) forDirection:direction];
        else
            _rootViewController.view.frame = [self getSlidingRectForOffset:offset forDirection:direction];
        
    };
    
    NSTimeInterval animationTime;
    if (_bouncingAnimations) animationTime = OpenAnimationTime*(1.0-OpenAnimationTimeBouncingRatio);
    else animationTime = OpenAnimationTime;
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews;
    
    if (animated) {
        [UIView animateWithDuration:animationTime
                              delay:0.0
                            options:options
                         animations:closeAnimBlock
                         completion:^(BOOL finished) {
                             if (_bouncingAnimations) // then we come to normal
                             {
                                 [UIView animateWithDuration:OpenAnimationTime*OpenAnimationTimeBouncingRatio
                                                       delay:0.0
                                                     options:options
                                                  animations:^{
                                                      _rootViewController.view.frame = [self getSlidingRectForOffset:offset forDirection:direction];
                                                  } completion:^(BOOL finished) {
                                                      [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
                                                  }];
                             }
                             else
                                 [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
                                 
                         }];
    }
    else
        closeAnimBlock();
}

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated {
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPopToController:) withParam:centerController];

}

- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction {
    UIViewController *existingController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (existingController != controller) {
        
        if (existingController.view.superview) [existingController.view removeFromSuperview];
        
        [_viewControllers setObject:controller forKey:[NSNumber numberWithInt:direction]];
        if (![controller isViewLoaded]) {
            [self.view insertSubview:controller.view atIndex:0];
            controller.view.hidden = YES;
        }
        
    }
}

#pragma mark - Setters

- (void) setShowShadows:(BOOL)showShadows {
    [self willChangeValueForKey:@"showShadows"];
    _showShadows = showShadows;
    [self handleShadows];
    [self didChangeValueForKey:@"showShadows"];
}

#pragma mark - Private methods

- (void) setRootViewController:(UIViewController *)controller {
    if (_rootViewController != controller) {
        [self willChangeValueForKey:@"rootViewController"];
        [_rootViewController.view removeFromSuperview];
        
        _rootViewController = PP_RETAIN(controller);
        _rootViewController.revealSideViewController = self;
        
        [self handleShadows];
        
        [self.view addSubview:_rootViewController.view];
        [self didChangeValueForKey:@"rootViewController"];
    }
}

- (void) handleShadows {
    if (self.showShadows) {
        _rootViewController.view.layer.shadowOffset = CGSizeZero;
        _rootViewController.view.layer.shadowOpacity = 0.75f;
        _rootViewController.view.layer.shadowRadius = 10.0f;
        _rootViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
        _rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
        _rootViewController.view.clipsToBounds = NO; 
    }
    else {
        _rootViewController.view.layer.shadowPath = nil;
        _rootViewController.view.layer.shadowOpacity = 0.0f;
        _rootViewController.view.layer.shadowRadius = 0.0;
        _rootViewController.view.layer.shadowColor = nil;
    }
}

- (void) informDelegateWithOptionalSelector:(SEL)selector withParam:(id)param {
    if ([self.delegate respondsToSelector:selector]) {
        // suppression of 'performSelector may cause a leak because its selector is unknown' warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:selector withObject:self withObject:param];
#pragma clang diagnostic pop
    }
}

#pragma mark Closed Controllers 

- (BOOL) isLeftControllerClosed {
    UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:PPRevealSideDirectionLeft]];
    return !c && CGRectGetMinX(_rootViewController.view.frame) <= 0;
}

- (BOOL) isRightControllerClosed {
    UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:PPRevealSideDirectionRight]];
    return !c && CGRectGetMaxX(_rootViewController.view.frame) <= CGRectGetWidth(_rootViewController.view.frame);
}

- (BOOL) isTopControllerClosed {
    UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:PPRevealSideDirectionTop]];
    return !c && CGRectGetMinY(_rootViewController.view.frame) <= 0;
}

- (BOOL) isBottomControllerClosed {
    UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:PPRevealSideDirectionBottom]];
    return !c && CGRectGetMaxY(_rootViewController.view.frame) <= CGRectGetHeight(_rootViewController.view.frame); 
}

- (PPRevealSideDirection) getSideToClose {
    PPRevealSideDirection sideToReturn = PPRevealSideDirectionNone;
    if (![self isRightControllerClosed]) sideToReturn = PPRevealSideDirectionRight;
    if (![self isLeftControllerClosed]) sideToReturn = PPRevealSideDirectionLeft;
    if (![self isTopControllerClosed]) sideToReturn = PPRevealSideDirectionTop;
    if (![self isBottomControllerClosed]) sideToReturn = PPRevealSideDirectionBottom;
    return sideToReturn;
}

- (CGRect) getSlidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
    if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) offset = MIN(CGRectGetWidth(PPScreenBounds()), offset);
    
    if (direction == PPRevealSideDirectionTop || direction == PPRevealSideDirectionBottom) offset = MIN(CGRectGetHeight(PPScreenBounds()), offset);

    CGRect rectToReturn = CGRectZero;
    rectToReturn.size = _rootViewController.view.frame.size;
    
    switch (direction) {
        case PPRevealSideDirectionLeft:
            rectToReturn.origin = CGPointMake(CGRectGetWidth(_rootViewController.view.frame)-offset, 0.0);
            break;
        case PPRevealSideDirectionRight:
            rectToReturn.origin = CGPointMake(-offset, 0.0);
            break;
        case PPRevealSideDirectionBottom:
            rectToReturn.origin = CGPointMake(0.0, -offset);
            break;
        case PPRevealSideDirectionTop:
            rectToReturn.origin = CGPointMake(0.0, CGRectGetHeight(_rootViewController.view.frame)-offset);
            break;   
        default:
            break;
    }
    return rectToReturn;
}

#pragma mark - Orientation stuff

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    _rootViewController.view.layer.shadowPath = nil;
    _rootViewController.view.layer.shouldRasterize = YES;
    
    [_rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (id key in _viewControllers.allKeys)
        [(UIViewController *)[_viewControllers objectForKey:key] willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    _rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:_rootViewController.view.layer.bounds].CGPath;
    _rootViewController.view.layer.shouldRasterize = NO;
    
    [_rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    for (id key in _viewControllers.allKeys)
        [(UIViewController *)[_viewControllers objectForKey:key] didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [_rootViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Memory management things

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) dealloc {
    PP_RELEASE(_rootViewController);
    PP_RELEASE(_viewControllers);
    PP_RELEASE(_viewControllersOffsets);

#if !PP_ARC_ENABLED
 [super dealloc];
#endif
}

@end




@implementation UIViewController (PPRevealSideViewController)
static char revealSideViewControllerKey;

- (void) setRevealSideViewController:(PPRevealSideViewController *)revealSideViewController {
    objc_setAssociatedObject( self, 
                             &revealSideViewControllerKey,
                             revealSideViewController,
                             OBJC_ASSOCIATION_RETAIN );
}

- (PPRevealSideViewController*) revealSideViewController {
    id controller = objc_getAssociatedObject( self, 
                                             &revealSideViewControllerKey );
    
    // because we can't ask the navigation controller to set to the pushed controller the revealSideViewController !
    if (!controller && self.navigationController)
        controller = self.navigationController.revealSideViewController;

    return controller;
}

@end

UIInterfaceOrientation PPInterfaceOrientation() {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	return orientation;
}

CGRect PPScreenBounds() {
	CGRect bounds = [UIScreen mainScreen].bounds;
	if (UIInterfaceOrientationIsLandscape(PPInterfaceOrientation())) {
		CGFloat width = bounds.size.width;
		bounds.size.width = bounds.size.height;
		bounds.size.height = width;
	}
	return bounds;
}
