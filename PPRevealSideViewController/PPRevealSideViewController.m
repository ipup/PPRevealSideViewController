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

- (void) popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController*)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset;

- (BOOL) isOptionEnabled:(PPRevealSideOptions)option;
- (BOOL) canCrossOffsets;

- (CGRect) getSideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction;
- (UIEdgeInsets) getEdgetInsetForDirection:(PPRevealSideDirection)direction;

@end

@implementation PPRevealSideViewController
@synthesize rootViewController = _rootViewController;
@synthesize interactions = _interactions;
@synthesize options = _options;
@synthesize bouncingOffset = _bouncingOffset;

@synthesize delegate = _delegate;

- (id) initWithRootViewController:(UIViewController*)rootViewController {
    self = [super init];
    if (self) {
        [self setRootViewController:rootViewController];
        
        // set default options
        self.options = PPRevealSideOptionsShowShadows | PPRevealSideOptionsBounceAnimations | PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection;
        
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
#define DefaultOffset 70.0
#define DefaultOffsetBouncing 5.0

#define OpenAnimationTime 0.5
#define OpenAnimationTimeBouncingRatio 0.3

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self pushViewController:controller
                 onDirection:direction
                  withOffset:DefaultOffset
                    animated:animated];
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self pushOldViewControllerOnDirection:direction
                                withOffset:DefaultOffset
                                  animated:animated];
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated {
    UIViewController *oldController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (oldController) {
        [self pushViewController:oldController
                     onDirection:direction
                      withOffset:offset
                        animated:animated];
    }
    else
    {
        // make a small animation to indicate that there is not yet a controller
        CGRect originalFrame = _rootViewController.view.frame;
        [UIView animateWithDuration:OpenAnimationTime*0.2 
                              delay:0.0
                            options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             _rootViewController.view.frame = [self getSlidingRectForOffset:CGRectGetWidth(_rootViewController.view.frame)-14.0
                                                                               forDirection:direction];
                         } completion:^(BOOL finished) {
                             _rootViewController.view.frame = originalFrame;
                         }];
    }
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated {
    
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPushController:) withParam:controller];
    
    // get the side direction to close
    PPRevealSideDirection directionToClose = [self getSideToClose];
    
    // if this is the same direction, then close it
    if (directionToClose == direction) {
        [self popViewControllerWithNewCenterController:_rootViewController animated:animated];
        return;
    }
    else // if the direction is different, and we close completely before opening, then pop / push !
        if (directionToClose != PPRevealSideDirectionNone && [self isOptionEnabled:PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection]) {
            [self popViewControllerWithNewCenterController:_rootViewController 
                                                  animated:animated 
                                   andPresentNewController:controller withDirection:direction andOffset:offset];
            return;
        }
    
    NSNumber *directionNumber = [NSNumber numberWithInt:direction];
    
    // save the offset
    [_viewControllersOffsets setObject:[NSNumber numberWithFloat:offset] forKey:directionNumber];
    
    // save the controller and remove the old one from the view
    UIViewController *oldController = [_viewControllers objectForKey:directionNumber];
    if (controller != oldController) {
        [oldController.view removeFromSuperview];
    }
    [_viewControllers setObject:controller forKey:directionNumber];
    
    // set the container controller to self
    controller.revealSideViewController = self;
    
    // Place the controller juste below the rootviewcontroller
    [controller.view removeFromSuperview];
    [self.view insertSubview:controller.view belowSubview:_rootViewController.view];
    
    // if bounces is activated and the push is animated, calculate the first frame with the bounce
    CGRect rootFrame = CGRectZero;
    if ([self canCrossOffsets] && animated) // then we make an offset
        rootFrame = [self getSlidingRectForOffset:offset- ((_bouncingOffset == - 1.0) ? DefaultOffsetBouncing : _bouncingOffset) forDirection:direction];
    else
        rootFrame = [self getSlidingRectForOffset:offset forDirection:direction];
    
    
    void (^openAnimBlock)(void) = ^(void) {
        controller.view.hidden = NO;        
        _rootViewController.view.frame = rootFrame;
    };
    
    // replace the view since IB add some offsets with the status bar if enabled
    controller.view.frame = [self getSideViewFrameFromRootFrame:rootFrame
                                                   andDirection:direction];
    
    NSTimeInterval animationTime;
    if ([self canCrossOffsets]) animationTime = OpenAnimationTime*(1.0-OpenAnimationTimeBouncingRatio);
    else animationTime = OpenAnimationTime;
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews;
    
    if (animated) {
        [UIView animateWithDuration:animationTime
                              delay:0.0
                            options:options
                         animations:openAnimBlock
                         completion:^(BOOL finished) {
                             if ([self canCrossOffsets]) // then we come to normal
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
    else {
        openAnimBlock();
        [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
    }
}

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated {
    [self popViewControllerWithNewCenterController:centerController
                                          animated:animated
                           andPresentNewController:nil
                                     withDirection:PPRevealSideDirectionNone
                                         andOffset:0.0];
}

- (void) popViewControllerAnimated:(BOOL)animated {
    [self popViewControllerWithNewCenterController:_rootViewController
                                          animated:animated];
}

- (void) popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController *)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset {
    
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPopToController:) withParam:centerController];
    
    PPRevealSideDirection directionToClose = [self getSideToClose];
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews;
    
    // define the close anim block
    void (^bigAnimBlock)(BOOL) = ^(BOOL finished) {
        if (finished) {
            CGRect olfFrame = _rootViewController.view.frame;
            [self setRootViewController:centerController];
            _rootViewController.view.frame = olfFrame;
            
            // this is the anim block to put to normal the center controller
            void(^smallAnimBlock)(void) = ^(void) {
                CGRect newFrame = _rootViewController.view.frame;
                newFrame.origin.x = 0.0;
                newFrame.origin.y = 0.0;
                _rootViewController.view.frame = newFrame;
            };
            
            // this is the completion block when you pop then push the new controller
            void (^smallAnimBlockCompletion)(BOOL) = ^(BOOL finished) {
                if (finished) {
                    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPopToController:) withParam:centerController];
                    
                    // remove the view (don't need to surcharge (not english this word ? ... ) all the interface).
                    UIViewController *oldController = (UIViewController*)[_viewControllers objectForKey:[NSNumber numberWithInt:directionToClose]];
                    [oldController.view removeFromSuperview];
                    
                    if (controllerToPush) {
                        [self pushViewController:controllerToPush
                                     onDirection:direction
                                      withOffset:offset
                                        animated:animated];
                    }
                }
            };
            
            // execute the blocks depending on animated or not
            if (animated) {
                NSTimeInterval animationTime;
                if ([self canCrossOffsets]) animationTime = OpenAnimationTime*(1.0-OpenAnimationTimeBouncingRatio);
                else animationTime = OpenAnimationTime;
                
                [UIView animateWithDuration:animationTime
                                      delay:0.0
                                    options:options
                                 animations:smallAnimBlock
                                 completion:smallAnimBlockCompletion];
            }
            else
            {
                smallAnimBlock();
                smallAnimBlockCompletion(YES);
            }
        }
    };
    
    // Now we are gonna use the big block !!
    if ([self canCrossOffsets] && animated) {
        PPRevealSideDirection directionToOpen = [self getSideToClose];
        
        // open completely and then close it
        [UIView animateWithDuration:OpenAnimationTime*OpenAnimationTimeBouncingRatio
                              delay:0.0
                            options:options
                         animations:^{
                             // this will open completely the view
                             _rootViewController.view.frame = [self getSlidingRectForOffset:0.0 forDirection:directionToOpen];
                         } completion:bigAnimBlock];
    }
    else
    {
        // we just execute the close anim block
        // Badly, we can't use the bigAnimBlock as an animation block since there is the finished parameter. So, just execute it !
        if (animated) {
            [UIView animateWithDuration:OpenAnimationTime
                                  delay:0.0
                                options:options
                             animations:^{
                                 bigAnimBlock(YES);
                             } completion:^(BOOL finished) {
                                 
                             } ];
            
        }  
        else
            bigAnimBlock(YES);
    }
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

#pragma mark - Observation method
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"view.frame"]) {
        PPRevealSideDirection direction = [self getSideToClose];
        UIViewController *openedController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
        if (openedController) {
            openedController.view.revealSideInset = [self getEdgetInsetForDirection:direction];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Setters

- (void) setOptions:(PPRevealSideOptions)options {
    [self willChangeValueForKey:@"options"];
    _options = options;
    [self handleShadows];
    [self didChangeValueForKey:@"options"];
}

- (void) setOption:(PPRevealSideOptions)option {
    _options |= option;
    if (option == PPRevealSideOptionsShowShadows) [self handleShadows];
}
- (void) resetOption:(PPRevealSideOptions)option {
    _options ^= option;
    if (option == PPRevealSideOptionsShowShadows) [self handleShadows];
}

#pragma mark - Private methods

- (void) setRootViewController:(UIViewController *)controller {
    if (_rootViewController != controller) {
        [self willChangeValueForKey:@"rootViewController"];
        [_rootViewController.view removeFromSuperview];
        
        [_rootViewController removeObserver:self forKeyPath:@"view.frame"];
        
        _rootViewController = PP_RETAIN(controller);
        _rootViewController.revealSideViewController = self;
        
        [_rootViewController addObserver:self
                              forKeyPath:@"view.frame"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
        [self handleShadows];
        
        [self.view addSubview:_rootViewController.view];
        [self didChangeValueForKey:@"rootViewController"];
    }
}

- (void) handleShadows {
    if ([self isOptionEnabled:PPRevealSideOptionsShowShadows]) {
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
    return CGRectGetMinX(_rootViewController.view.frame) <= 0;
}

- (BOOL) isRightControllerClosed {
    return CGRectGetMaxX(_rootViewController.view.frame) >= CGRectGetWidth(_rootViewController.view.frame);
}

- (BOOL) isTopControllerClosed {
    return CGRectGetMinY(_rootViewController.view.frame) <= 0;
}

- (BOOL) isBottomControllerClosed {
    return CGRectGetMaxY(_rootViewController.view.frame) >= CGRectGetHeight(_rootViewController.view.frame); 
}

- (PPRevealSideDirection) getSideToClose {
    PPRevealSideDirection sideToReturn = PPRevealSideDirectionNone;
    if (![self isRightControllerClosed]) sideToReturn = PPRevealSideDirectionRight;
    if (![self isLeftControllerClosed]) sideToReturn = PPRevealSideDirectionLeft;
    if (![self isTopControllerClosed]) sideToReturn = PPRevealSideDirectionTop;
    if (![self isBottomControllerClosed]) sideToReturn = PPRevealSideDirectionBottom;
    return sideToReturn;
}

- (CGRect) getSlidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction andOrientation:(UIInterfaceOrientation)orientation {
    if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) offset = MIN(CGRectGetWidth(PPScreenBounds()), offset);
    
    if (direction == PPRevealSideDirectionTop || direction == PPRevealSideDirectionBottom) offset = MIN(CGRectGetHeight(PPScreenBounds()), offset);
    
    CGRect rectToReturn = CGRectZero;
    rectToReturn.size = _rootViewController.view.frame.size;
    
    CGFloat width = CGRectGetWidth(_rootViewController.view.frame);
    CGFloat height = CGRectGetHeight(_rootViewController.view.frame);
    switch (direction) {
        case PPRevealSideDirectionLeft:
            rectToReturn.origin = CGPointMake(width-offset, 0.0);
            break;
        case PPRevealSideDirectionRight:
            rectToReturn.origin = CGPointMake(-(width-offset), 0.0);
            break;
        case PPRevealSideDirectionBottom:
            rectToReturn.origin = CGPointMake(0.0, -(height-offset));
            break;
        case PPRevealSideDirectionTop:
            rectToReturn.origin = CGPointMake(0.0, height-offset);
            break;   
        default:
            break;
    }

    return rectToReturn;
}

- (CGRect) getSlidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
        return [self getSlidingRectForOffset:offset forDirection:direction andOrientation:PPInterfaceOrientation()];
}

- (BOOL) isOptionEnabled:(PPRevealSideOptions)option {
    return _options & option; 
}

- (BOOL) canCrossOffsets {
    return ![self isOptionEnabled:PPRevealSideOptionsResizeSideView] && [self isOptionEnabled:PPRevealSideOptionsBounceAnimations];
}

- (void) resizeCurrentView {
    PPRevealSideDirection direction = [self getSideToClose];
    
    if (
        ([self isOptionEnabled:PPRevealSideOptionsKeepOffsetOnRotation] && (direction == PPRevealSideDirectionRight || direction == PPRevealSideDirectionLeft))
        ||
        (direction == PPRevealSideDirectionBottom || direction == PPRevealSideDirectionTop)
        ) {
        _rootViewController.view.frame = [self getSlidingRectForOffset:[(NSNumber*)([_viewControllersOffsets objectForKey:[NSNumber numberWithInt:direction]]) floatValue]
                                                          forDirection:direction];
    }
}

- (CGRect) getSideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction {
    CGRect slideFrame = CGRectZero;

    CGFloat rootHeight = CGRectGetHeight(rootFrame);
    CGFloat rootWidth = CGRectGetWidth(rootFrame);
    
    if ([self isOptionEnabled:PPRevealSideOptionsResizeSideView]){
        switch (direction) {
            case PPRevealSideDirectionLeft:
                slideFrame.size.height = rootHeight;
                slideFrame.size.width = CGRectGetMinX(rootFrame);
                break;
            case PPRevealSideDirectionRight:
                slideFrame.origin.x = CGRectGetMaxX(rootFrame);
                slideFrame.size.height = rootHeight;
                slideFrame.size.width = rootWidth - CGRectGetMaxX(rootFrame);
                break; 
            case PPRevealSideDirectionTop:
                slideFrame.size.height = CGRectGetMinY(rootFrame);
                slideFrame.size.width = rootWidth;
                break;
            case PPRevealSideDirectionBottom:
                slideFrame.origin.y = CGRectGetMaxY(rootFrame);
                slideFrame.size.height = rootHeight-CGRectGetMaxY(rootFrame);
                slideFrame.size.width = rootWidth;
                break;
            default:
                break;
        }
    }
    else
    {
        slideFrame.size.width = rootWidth;
        slideFrame.size.height = rootHeight;
    }

    return slideFrame;
}

- (UIEdgeInsets) getEdgetInsetForDirection:(PPRevealSideDirection)direction {
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (![self isOptionEnabled:PPRevealSideOptionsResizeSideView]){
        CGFloat offset = [[_viewControllersOffsets objectForKey:[NSNumber numberWithInt:direction]] floatValue];
        
        switch (direction) {
            case PPRevealSideDirectionLeft:
                inset.right = offset;
                break;
            case PPRevealSideDirectionRight:
                inset.left = offset;
                break;
            case PPRevealSideDirectionTop:
                inset.bottom = offset;
                break;
            case PPRevealSideDirectionBottom:
                inset.top = offset;
                break;
            default:
                break;
        }
    }
    PPLog(@"%@", NSStringFromUIEdgeInsets(inset));
    return inset;
}

#pragma mark - Orientation stuff

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self resizeCurrentView];
    
    [_rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (id key in _viewControllers.allKeys)
    {
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        
        if (controller.view.superview) {
            controller.view.frame = [self getSideViewFrameFromRootFrame:_rootViewController.view.frame
                                                           andDirection:[key intValue]];
            
            [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    _rootViewController.view.layer.shadowPath = nil;
    _rootViewController.view.layer.shouldRasterize = YES;
    
    [_rootViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (id key in _viewControllers.allKeys)
    {
        // optimisation
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        if (controller.view.superview)
            [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    _rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:_rootViewController.view.layer.bounds].CGPath;
    _rootViewController.view.layer.shouldRasterize = NO;
    
    [_rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    for (id key in _viewControllers.allKeys)
    {
        // optimisation
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        if (controller.view.superview)
            [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
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
    [self willChangeValueForKey:@"revealSideViewController"];
    objc_setAssociatedObject( self, 
                             &revealSideViewControllerKey,
                             revealSideViewController,
                             OBJC_ASSOCIATION_RETAIN );
    [self didChangeValueForKey:@"revealSideViewController"];
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

@implementation UIView (PPRevealSideViewController)
static char revealSideInsetKey;

- (void) setRevealSideInset:(UIEdgeInsets)revealSideInset {
    [self willChangeValueForKey:@"revealSideInset"];
    NSString *stringInset = NSStringFromUIEdgeInsets(revealSideInset);
    objc_setAssociatedObject( self, 
                             &revealSideInsetKey,
                             stringInset,
                             OBJC_ASSOCIATION_RETAIN );
    [self didChangeValueForKey:@"revealSideInset"];
}

- (UIEdgeInsets) revealSideInset {
    NSString *stringInset =  objc_getAssociatedObject( self, 
                                                      &revealSideInsetKey );
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (stringInset)
        inset = UIEdgeInsetsFromString(stringInset);
    else
        inset = self.superview.revealSideInset;
    return inset;
}

@end

#pragma mark - Some Functions

UIInterfaceOrientation PPInterfaceOrientation(void) {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	return orientation;
}

CGRect PPScreenBounds(void) {
	CGRect bounds = [UIScreen mainScreen].bounds;
	if (UIInterfaceOrientationIsLandscape(PPInterfaceOrientation())) {
		CGFloat width = bounds.size.width;
		bounds.size.width = bounds.size.height;
		bounds.size.height = width;
	}
	return bounds;
}
