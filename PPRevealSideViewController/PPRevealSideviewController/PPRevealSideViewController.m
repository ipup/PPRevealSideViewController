//
//  PPRevealSideViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "PPRevealSideViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - Unit constants
static const CGFloat DefaultOffset = 70.0;
static const CGFloat DefaultOffsetBouncing = 5.0;
static const CGFloat OpenAnimationTime = 0.3;
static const CGFloat OpenAnimationTimeBouncingRatio = 0.3;
static const CGFloat BOUNCE_ERROR_OFFSET = 14.0;
static const CGFloat divisionNumber = 5.0;
static const CGFloat OFFSET_TRIGGER_CHOSE_DIRECTION = 3.0;
static const CGFloat OFFSET_TRIGGER_CHANGE_DIRECTION = 0.0;
static const CGFloat MAX_TRIGGER_OFFSET = 100.0;

#pragma mark -
@interface PPRevealSideViewController (Private)
- (void) setRootViewController:(UIViewController *)controller replaceToOrigin:(BOOL)replace;
- (void) setRootViewController:(UIViewController*)controller;
- (void) addShadow;
- (void) removeShadow;
- (void) handleShadows;
- (void) informDelegateWithOptionalSelector:(SEL)selector withParam:(id)param;
- (void) popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController*)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset;
- (void) addGesturesToCenterController;
- (void) addPanGestureToController:(UIViewController*)controller;
- (void) addTapGestureToController:(UIViewController*)controller;
- (void) addGesturesToController:(UIViewController*)controller;
- (void) removeAllPanGestures;
- (void) removeAllTapGestures;
- (void) removeAllGestures;
- (void) setOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;
- (void) removeControllerFromView:(UIViewController*)controller animated:(BOOL)animated;
- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset forceRemoval:(BOOL)force;

- (BOOL) isLeftControllerClosed;
- (BOOL) isRightControllerClosed;
- (BOOL) isTopControllerClosed;
- (BOOL) isBottomControllerClosed;
- (BOOL) isOptionEnabled:(PPRevealSideOptions)option;
- (BOOL) canCrossOffsets;

- (PPRevealSideDirection) getSideToClose;

- (CGRect) getSlidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;
- (CGRect) getSideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction alreadyFullScreenLayout:(BOOL)alreadyFullScreenLayout;

- (UIEdgeInsets) getEdgetInsetForDirection:(PPRevealSideDirection)direction;

- (CGFloat) getOffsetForDirection:(PPRevealSideDirection)direction andInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (CGFloat) getOffsetForDirection:(PPRevealSideDirection)direction;
- (void) tryToRemoveObserverOnFrame;

@end

// Make a private category so that we can have the setter
@interface UIViewController (PPRevealSideViewControllerPrivate)
- (void) setRevealSideViewController:(PPRevealSideViewController *)revealSideViewController;
@end

#pragma mark -
@implementation PPRevealSideViewController
@synthesize rootViewController = _rootViewController;
@synthesize panInteractionsWhenClosed = _panInteractionsWhenClosed;
@synthesize panInteractionsWhenOpened = _panInteractionsWhenOpened;
@synthesize tapInteractionsWhenOpened = _tapInteractionsWhenOpened;
@synthesize directionsToShowBounce = _directionsToShowBounce;
@synthesize options = _options;
@synthesize bouncingOffset = _bouncingOffset;
@synthesize delegate = _delegate;

- (id) initWithRootViewController:(UIViewController*)rootViewController {
    self = [super init];
    if (self) {
        // set default options
        self.options = PPRevealSideOptionsShowShadows | PPRevealSideOptionsBounceAnimations | PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection;
        
        self.bouncingOffset = -1.0;
        
        self.panInteractionsWhenClosed = PPRevealSideInteractionNavigationBar;
        self.panInteractionsWhenOpened = PPRevealSideInteractionNavigationBar | PPRevealSideInteractionContentView;
        
        self.tapInteractionsWhenOpened = PPRevealSideInteractionContentView | PPRevealSideInteractionNavigationBar;
        
        //self.directionsToShowBounce = PPRevealSideDirectionBottom | PPRevealSideDirectionLeft | PPRevealSideDirectionRight | PPRevealSideDirectionTop;
        self.directionsToShowBounce = PPRevealSideDirectionNone;
        
        _viewControllers = [[NSMutableDictionary alloc] init];
        _viewControllersOffsets = [[NSMutableDictionary alloc] init];
		
        _gestures = [[NSMutableArray alloc] init];
        
        [self setRootViewController:rootViewController];
    }
    return self;
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    CGRect rect  = PPScreenBounds();
    rect.size.height -= PPStatusBarHeight();
    self.view = PP_AUTORELEASE([[UIView alloc] initWithFrame:rect]);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.clipsToBounds = YES;
    self.view.autoresizesSubviews = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewWillAppear:animated];
    
    PPRevealSideDirection direction = [self getSideToClose];
    if (direction != PPRevealSideDirectionNone) [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewDidAppear:animated];
    
    PPRevealSideDirection direction = [self getSideToClose];
    if (direction != PPRevealSideDirectionNone) [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewWillDisappear:animated];
    
    PPRevealSideDirection direction = [self getSideToClose];
    if (direction != PPRevealSideDirectionNone) [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewDidDisappear:animated];
    
    PPRevealSideDirection direction = [self getSideToClose];
    if (direction != PPRevealSideDirectionNone) [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewDidDisappear:animated];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad{
    [super viewDidLoad];
    
    if (_rootViewController && !_rootViewController.view.superview)
    {
        // Then we have probably received memory warning
        UIViewController *newRoot = PP_RETAIN(_rootViewController);
        // Just a little hack to reset the root
        self.rootViewController = nil;
        self.rootViewController = newRoot;
        PP_RELEASE(newRoot);
    }
    _oldStatusBarHeight = PPStatusBarHeight();
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarFrameWillChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
}

#pragma mark - Push methods
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated{
	[self pushViewController:controller onDirection:direction animated:animated completion:nil];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated completion:(void(^)())completionBlock{
    [self pushViewController:controller onDirection:direction withOffset:DefaultOffset animated:animated completion:completionBlock];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush{
	[self pushViewController:controller onDirection:direction animated:animated forceToPopPush:forcePopPush completion:nil];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush completion:(void(^)())completionBlock{
    [self pushViewController:controller onDirection:direction withOffset:DefaultOffset animated:animated forceToPopPush:forcePopPush completion:completionBlock];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated{
	[self pushViewController:controller onDirection:direction withOffset:offset animated:animated completion:nil];
}

- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)())completionBlock{
    [self pushViewController:controller onDirection:direction withOffset:offset animated:animated forceToPopPush:NO completion:completionBlock];
}

- (void) pushViewController:(UIViewController *)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush{
	[self pushViewController:controller onDirection:direction withOffset:offset animated:animated forceToPopPush:forcePopPush completion:nil];
}

- (void) pushViewController:(UIViewController *)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush completion:(void(^)())completionBlock{
    
    if (_animationInProgress) return;
	
    _rootViewController.view.alpha = 1.0;
		
    // get the side direction to close
    PPRevealSideDirection directionToClose = [self getSideToClose];
    
    // if this is the same direction, then close it
    if (directionToClose == direction && !_shouldNotCloseWhenPushingSameDirection) {
        if (!forcePopPush) {
            // then pop
            [self popViewControllerWithNewCenterController:_rootViewController animated:animated completion:completionBlock];
        }
        else{
            // pop and push
            [self popViewControllerWithNewCenterController:_rootViewController animated:animated andPresentNewController:controller withDirection:direction andOffset:offset completion:completionBlock];
        }
        return;
    }
    else if (directionToClose != PPRevealSideDirectionNone && [self isOptionEnabled:PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection] && !_shouldNotCloseWhenPushingSameDirection) {
		// if the direction is different, and we close completely before opening, then pop / push !
		[self popViewControllerWithNewCenterController:_rootViewController animated:animated andPresentNewController:controller withDirection:direction andOffset:offset completion:completionBlock];
		return;
	}
    
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPushController:) withParam:controller];

    _animationInProgress = YES;
    
    NSNumber *directionNumber = [NSNumber numberWithInt:direction];
    
    // save the offset
    [self setOffset:offset forDirection:direction];
    
    // get the offset with orientation aware stuff
    offset = [self getOffsetForDirection:direction];
    
    // save the controller and remove the old one from the view
    UIViewController *oldController = [_viewControllers objectForKey:directionNumber];
    
    if (controller != oldController) [self removeControllerFromView:oldController animated:animated];
    
    [_viewControllers setObject:controller forKey:directionNumber];
    
    // set the container controller to self
    controller.revealSideViewController = self;
    
    // Place the controller juste below the rootviewcontroller
    controller.view.frame = self.view.bounds; // handle layout issue with navigation bar. Comment to see the crap, then push a nav controller
    
    [self removeControllerFromView:controller animated:animated];
    
    // TODO remove then adding not so good ... Maybe do something different
    if (PPSystemVersionGreaterOrEqualThan(5.0))
    {
        [self addChildViewController:controller];
    }
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [controller viewWillAppear:animated];
    [self.view insertSubview:controller.view belowSubview:_rootViewController.view];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [controller viewDidAppear:animated];
    
    // if bounces is activated and the push is animated, calculate the first frame with the bounce
    CGRect rootFrame = CGRectZero;
    if ([self canCrossOffsets] && animated && offset != 0.0f) // then we make an offset
        rootFrame = [self getSlidingRectForOffset:offset- ((_bouncingOffset == - 1.0) ? DefaultOffsetBouncing : _bouncingOffset) forDirection:direction];
    else
        rootFrame = [self getSlidingRectForOffset:offset forDirection:direction];
    
    void (^openAnimBlock)(void) = ^(void) {
        controller.view.hidden = NO;
        _rootViewController.view.frame = rootFrame;
    };
    
    // replace the view since IB add some offsets with the status bar if enabled
    controller.view.frame = [self getSideViewFrameFromRootFrame:rootFrame
                                                   andDirection:direction
                                        alreadyFullScreenLayout:controller.wantsFullScreenLayout];
    
    NSTimeInterval animationTime = OpenAnimationTime;
	//    if ([self canCrossOffsets]) animationTime = OpenAnimationTime;
	//    else animationTime = OpenAnimationTime;
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionLayoutSubviews;
    
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
                                                      if (offset == 0.0) {
                                                          [UIView animateWithDuration:0.1
                                                                           animations:^{
                                                                               _rootViewController.view.alpha = 0.0;
                                                                           }
																		   completion:^(BOOL finished) {
																			   _animationInProgress = NO;
																			   if (completionBlock) completionBlock();
																		   }];
                                                      }
                                                      else{
                                                          _animationInProgress = NO;
													  }
                                                      
                                                      if (PPSystemVersionGreaterOrEqualThan(5.0)) [controller didMoveToParentViewController:self];
                                                      if (completionBlock) completionBlock();

                                                      [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
                                                  }];
                             }
                             else
                             {
                                 _animationInProgress = NO;
                                 if (PPSystemVersionGreaterOrEqualThan(5.0)) [controller didMoveToParentViewController:self];
								 if (completionBlock) completionBlock();
                                 [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
                             }
                             
                         }];
    }
    else {
        openAnimBlock();
        _animationInProgress = NO;
        if (PPSystemVersionGreaterOrEqualThan(5.0)) [controller didMoveToParentViewController:self];
		if (completionBlock) completionBlock();
        [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
    }
    
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated{
	[self pushOldViewControllerOnDirection:direction animated:animated completion:nil];
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated completion:(void(^)())completionBlock{
    [self pushOldViewControllerOnDirection:direction withOffset:DefaultOffset animated:animated completion:completionBlock];
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated{
	[self pushOldViewControllerOnDirection:direction withOffset:offset animated:animated completion:nil];
}

- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)())completionBlock{
    UIViewController *oldController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (oldController) {
		[self pushViewController:oldController onDirection:direction withOffset:offset animated:animated forceToPopPush:NO completion:completionBlock];
    }
    else {
        if ((_directionsToShowBounce & direction) == direction) {
            // make a small animation to indicate that there is not yet a controller
            CGRect originalFrame = _rootViewController.view.frame;
            _animationInProgress = YES;
            [UIView animateWithDuration:OpenAnimationTime*0.15
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 CGFloat offsetBounce;
                                 if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight)
                                     offsetBounce = CGRectGetWidth(_rootViewController.view.frame)-BOUNCE_ERROR_OFFSET;
                                 else
                                     offsetBounce = CGRectGetHeight(_rootViewController.view.frame)-BOUNCE_ERROR_OFFSET;
                                 
                                 _rootViewController.view.frame = [self getSlidingRectForOffset:offsetBounce
                                                                                   forDirection:direction];
                             } completion:^(BOOL finished) {
                                 [UIView animateWithDuration:OpenAnimationTime*0.15
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseInOut
                                                  animations:^{
                                                      _rootViewController.view.frame = originalFrame;
                                                  } completion:^(BOOL finished) {
                                                      _animationInProgress = NO;
													  if (completionBlock) completionBlock();
                                                  }];
                             }];
        }
    }
}

#pragma mark - Pop methods
- (void) popViewControllerAnimated:(BOOL)animated{
	[self popViewControllerAnimated:animated completion:nil];
}

- (void) popViewControllerAnimated:(BOOL)animated completion:(void(^)())completionBlock{
    [self popViewControllerWithNewCenterController:_rootViewController animated:animated completion:completionBlock];
}

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated{
	[self popViewControllerWithNewCenterController:centerController animated:animated completion:nil];
}

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated completion:(void(^)())completionBlock {
    [self popViewControllerWithNewCenterController:centerController animated:animated andPresentNewController:nil withDirection:PPRevealSideDirectionNone andOffset:0.0 completion:completionBlock];
}

- (void) popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController *)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset {
	[self popViewControllerWithNewCenterController:centerController animated:animated andPresentNewController:controllerToPush withDirection:direction andOffset:offset completion:nil];
}

- (void) popViewControllerWithNewCenterController:(UIViewController *)centerController animated:(BOOL)animated andPresentNewController:(UIViewController *)controllerToPush withDirection:(PPRevealSideDirection)direction andOffset:(CGFloat)offset completion:(void(^)())completionBlock{
	
    if (_animationInProgress) return;
    
    _rootViewController.view.alpha = 1.0f;
    
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPopToController:) withParam:centerController];
	
    PPRevealSideDirection directionToClose = [self getSideToClose];
    if (directionToClose == PPRevealSideDirectionNone && _popFromPanGesture)
    {
        directionToClose = _currentPanDirection;
        _popFromPanGesture = NO;
    }
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseOut;
    
    _animationInProgress = YES;
    
    // define the close anim block
    void (^bigAnimBlock)(BOOL) = ^(BOOL finished) {
        if (finished) {
            CGRect oldFrame = _rootViewController.view.frame;
            centerController.view.frame = oldFrame;
            [self setRootViewController:centerController replaceToOrigin:NO];
			
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
                    
                    [self removeControllerFromView:oldController animated:animated];
                    
                    _animationInProgress = NO;
					
                    if (controllerToPush) {
                        [self pushViewController:controllerToPush onDirection:direction withOffset:offset animated:animated completion:completionBlock];
                    }
					else{
						if (completionBlock) completionBlock();
					}
                }
            };
            
            // execute the blocks depending on animated or not
            if (animated) {
                NSTimeInterval animationTime = OpenAnimationTime;
				//                if ([self canCrossOffsets]) animationTime = OpenAnimationTime;
				//                else animationTime = OpenAnimationTime;
                
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
    if ([self canCrossOffsets] && animated && centerController != _rootViewController) {
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
    else{
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
        else{
            bigAnimBlock(YES);
		}
    }
}

#pragma mark - Open methods
- (void) openCompletelySide:(PPRevealSideDirection)direction animated:(BOOL)animated{
	[self openCompletelySide:direction animated:animated completion:nil];
}

- (void) openCompletelySide:(PPRevealSideDirection)direction animated:(BOOL)animated completion:(void(^)())completionBlock{
	_shouldNotCloseWhenPushingSameDirection = YES;
    [self pushOldViewControllerOnDirection:direction withOffset:0.0 animated:YES completion:completionBlock];
}

- (void) openCompletelyAnimated:(BOOL)animated{
	[self openCompletelyAnimated:animated completion:nil];
}

- (void) openCompletelyAnimated:(BOOL)animated completion:(void(^)())completionBlock{
    PPRevealSideDirection direction = [self getSideToClose];
    [self openCompletelySide:direction animated:animated completion:completionBlock];
}

#pragma mark - Replace methods
- (void) replaceAfterOpenedCompletelyAnimated:(BOOL)animated{
	[self replaceAfterOpenedCompletelyAnimated:animated completion:nil];
}

- (void) replaceAfterOpenedCompletelyAnimated:(BOOL)animated completion:(void(^)())completionBlock{
    [self replaceAfterOpenedCompletelyWithOffset:DefaultOffset animated:animated completion:completionBlock];
}

- (void) replaceAfterOpenedCompletelyWithOffset:(CGFloat)offset animated:(BOOL)animated{
	[self replaceAfterOpenedCompletelyWithOffset:offset animated:animated completion:nil];
}

- (void) replaceAfterOpenedCompletelyWithOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)())completionBlock{
    _shouldNotCloseWhenPushingSameDirection = YES;
    PPRevealSideDirection direction = [self getSideToClose];
    [self pushOldViewControllerOnDirection:direction withOffset:offset animated:animated completion:completionBlock];
}

- (void) replaceCentralViewControllerWithNewController:(UIViewController*)newCenterController animated:(BOOL)animated animationDirection:(PPRevealSideDirection)direction completion:(void(^)())completionBlock{
	__block __typeof(&*self) weakSelf = self;
	[self openCompletelySide:direction animated:animated completion:^{
		[weakSelf popViewControllerWithNewCenterController:newCenterController animated:animated completion:completionBlock];
	}];
}

#pragma mark - Other useful methods
- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction {
    [self preloadViewController:controller
                        forSide:direction
                     withOffset:DefaultOffset];
}

- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset
{
    [self preloadViewController:controller
                        forSide:direction
                     withOffset:offset
                   forceRemoval:NO];
}

- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset forceRemoval:(BOOL)force
{
    if (direction == [self sideDirectionOpened] && !force) return;
    
    UIViewController *existingController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (existingController != controller) {
        
        if (existingController.view.superview) [self removeControllerFromView:existingController animated:NO];
        
        [_viewControllers setObject:controller forKey:[NSNumber numberWithInt:direction]];
        if (![controller isViewLoaded]) {
            if (PPSystemVersionGreaterOrEqualThan(5.0)) [controller willMoveToParentViewController:self];
            
            [self.view insertSubview:controller.view atIndex:0];
            
            if (PPSystemVersionGreaterOrEqualThan(5.0))
            {
                [self addChildViewController:controller];
                [controller didMoveToParentViewController:self];
            }
            controller.view.hidden = YES;
        }
        controller.view.frame = self.view.bounds;
    }
    [self setOffset:offset forDirection:direction];
}

- (void) unloadViewControllerForSide:(PPRevealSideDirection)direction
{
    NSNumber *key = [NSNumber numberWithInt:direction];
    UIViewController *controller = [_viewControllers objectForKey:key];
    
    [self removeControllerFromView:controller animated:NO];
    
    [_viewControllers removeObjectForKey:key];
}

- (void) changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
    [self changeOffset:offset forDirection:direction animated:NO];
}

- (void) changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self setOffset:offset forDirection:direction];
    
    if ([self getSideToClose] == direction ) {
        if (animated)
            [UIView animateWithDuration:0.3
                             animations:^{
                                 _rootViewController.view.frame = [self getSlidingRectForOffset:offset
                                                                                   forDirection:direction];
                             }];
        else
            _rootViewController.view.frame = [self getSlidingRectForOffset:offset
                                                              forDirection:direction];
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

- (void) statusBarFrameWillChange:(NSNotification*)notif {
    // Could be needed in future bug fixes
	//    NSValue* rectValue = [[notif userInfo] valueForKey:UIApplicationStatusBarFrameUserInfoKey];
	//    CGRect newFrame;
	//    [rectValue getValue:&newFrame];
	
    // PPRSLog(@"old %f new %f", _oldStatusBarHeight, PPStatusBarHeight());
    if (PPStatusBarHeight() != _oldStatusBarHeight)
    {
        _oldStatusBarHeight = PPStatusBarHeight();
        // Replace the views
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             PPRevealSideDirection direction = [self getSideToClose];
                             UIViewController *openedController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
                             CGRect newFrame = [self getSideViewFrameFromRootFrame:_rootViewController.view.frame
                                                                      andDirection:direction
                                                           alreadyFullScreenLayout:openedController.wantsFullScreenLayout];
                             openedController.view.frame = newFrame;
                             
                             CGFloat offset = [[_viewControllersOffsets objectForKey:[NSNumber numberWithInt:direction]] floatValue];
                             CGRect rootFrame = [self getSlidingRectForOffset:offset forDirection:direction];
                             _rootViewController.view.frame = rootFrame;
                             PPRSLog(@"%@", NSStringFromCGRect(rootFrame));
                         }
                         completion:nil];
    }
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

- (void) setPanInteractionsWhenClosed:(PPRevealSideInteractions)panInteractionsWhenClosed {
    [self willChangeValueForKey:@"panInteractionsWhenClosed"];
    _panInteractionsWhenClosed = panInteractionsWhenClosed;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"panInteractionsWhenClosed"];
}

- (void) setPanInteractionsWhenOpened:(PPRevealSideInteractions)panInteractionsWhenOpened {
    [self willChangeValueForKey:@"panInteractionsWhenOpened"];
    _panInteractionsWhenOpened = panInteractionsWhenOpened;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"panInteractionsWhenOpened"];
}

- (void) setTapInteractionsWhenOpened:(PPRevealSideInteractions)tapInteractionsWhenOpened {
    [self willChangeValueForKey:@"tapInteractionsWhenOpened"];
    _tapInteractionsWhenOpened = tapInteractionsWhenOpened;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"tapInteractionsWhenOpened"];
}

#pragma mark - Getters

- (PPRevealSideDirection) sideDirectionOpened
{
    return [self getSideToClose];
}

- (UIViewController*)controllerForSide:(PPRevealSideDirection)side
{
    return [_viewControllers objectForKey:[NSNumber numberWithInt:side]];
}
#pragma mark - Private methods

- (void) setRootViewController:(UIViewController *)controller replaceToOrigin:(BOOL)replace
{
    if (_rootViewController != controller) {
        [self willChangeValueForKey:@"rootViewController"];
        
        [self removeAllGestures];
		
        [self tryToRemoveObserverOnFrame];
        
        [self removeControllerFromView:_rootViewController animated:NO];
        
        PP_RELEASE(_rootViewController);
        _rootViewController = PP_RETAIN(controller);
        
        if (_rootViewController) {
            _rootViewController.revealSideViewController = self;
            
            if (PPSystemVersionGreaterOrEqualThan(5.0))
            {
                [self addChildViewController:_rootViewController];
            }
            
            [self handleShadows];
            
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewWillAppear:NO];
            [self.view addSubview:_rootViewController.view];
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController viewDidAppear:NO];
            
            if (PPSystemVersionGreaterOrEqualThan(5.0))
                [_rootViewController didMoveToParentViewController:self];
            
            [_rootViewController addObserver:self
                                  forKeyPath:@"view.frame"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];
            
            [self addGesturesToCenterController];
            
            if (replace)
                _rootViewController.view.frame = self.view.bounds;
            
            [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didChangeCenterController:) withParam:_rootViewController];
        }
        
        [self didChangeValueForKey:@"rootViewController"];
    }
}
- (void) setRootViewController:(UIViewController *)controller
{
    [self setRootViewController:controller replaceToOrigin:YES];
}

- (void) addShadow
{
    _rootViewController.view.layer.shadowOffset = CGSizeZero;
    _rootViewController.view.layer.shadowOpacity = 0.75f;
    _rootViewController.view.layer.shadowRadius = 10.0f;
    _rootViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    _rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
    _rootViewController.view.clipsToBounds = NO;
}

- (void) removeShadow
{
    _rootViewController.view.layer.shadowPath = nil;
    _rootViewController.view.layer.shadowOpacity = 0.0f;
    _rootViewController.view.layer.shadowRadius = 0.0;
    _rootViewController.view.layer.shadowColor = nil;
}

- (void) handleShadows {
    if ([self isOptionEnabled:PPRevealSideOptionsShowShadows]) {
        [self addShadow];
    }
    else
    {
        [self removeShadow];
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
    
    if (selector == @selector(pprevealSideViewController:didPushController:)
        ||
        selector == @selector(pprevealSideViewController:didPopToController:)) {
        [self addGesturesToCenterController];
    }
}

- (void) resizeCurrentView {
    PPRevealSideDirection direction = [self getSideToClose];
    
    if (
        ([self isOptionEnabled:PPRevealSideOptionsKeepOffsetOnRotation] && (direction == PPRevealSideDirectionRight || direction == PPRevealSideDirectionLeft))
        ||
        (direction == PPRevealSideDirectionBottom || direction == PPRevealSideDirectionTop)
        ) {
        _rootViewController.view.frame = [self getSlidingRectForOffset:[self getOffsetForDirection:direction]
                                                          forDirection:direction];
    }
}

- (UIViewController*) getControllerForGestures
{
    UIViewController *controllerForGestures = _rootViewController;
    if ([self.delegate respondsToSelector:@selector(controllerForGesturesOnPPRevealSideViewController:)]) {
        UIViewController *specialController = [self.delegate controllerForGesturesOnPPRevealSideViewController:self];
        if (specialController) controllerForGestures = specialController;
    }
    return controllerForGestures;
}

- (void) addPanGestureToView:(UIView*)view
{
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureRecognizerDidPan:)];
    panGesture.cancelsTouchesInView = YES;
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    [_gestures addObject:panGesture];
    PP_RELEASE(panGesture);
}

- (void) addPanGestureToController:(UIViewController*)controller {
    
    BOOL isClosed = ([self getSideToClose] == PPRevealSideDirectionNone) ? YES : NO;
    PPRevealSideInteractions interactions = isClosed ? _panInteractionsWhenClosed : _panInteractionsWhenOpened;
    
    // Nav Bar
    if (interactions & PPRevealSideInteractionNavigationBar && ([controller isKindOfClass:[UINavigationController class]] || controller.navigationController)) {
		
        UINavigationController *nav;
        if ([controller isKindOfClass:[UINavigationController class]])
            nav = (UINavigationController*)controller;
        else
            nav = controller.navigationController;
        
        [self addPanGestureToView:nav.navigationBar];
    }
    
    // Content View
    if (interactions & PPRevealSideInteractionContentView) {
		
        UIViewController *c;
        if ([controller isKindOfClass:[UINavigationController class]]) {
            c = [((UINavigationController*)controller).viewControllers lastObject];
        }
        else
            if (controller.navigationController)
                c = [controller.navigationController.viewControllers lastObject];
            else
                c = controller;
		
        [self addPanGestureToView:c.view];
    }
    
    // Customs views
    if ([self.delegate respondsToSelector:@selector(customViewsToAddPanGestureOnPPRevealSideViewController:)]) {
        NSArray *views = [self.delegate customViewsToAddPanGestureOnPPRevealSideViewController:self];
        if (views)
            for (UIView *vi in views)
                if ([vi isKindOfClass:[UIView class]])
                    [self addPanGestureToView:vi];
    }
}

- (void) addTapGestureToView:(UIView*)view
{
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureRecognizerDidTap:)];
    tapGesture.cancelsTouchesInView = YES;
    tapGesture.delegate = self;
    [view addGestureRecognizer:tapGesture];
    [_gestures addObject:tapGesture];
    PP_RELEASE(tapGesture);
}

- (void) addTapGestureToController:(UIViewController *)controller {
    BOOL isClosed = ([self getSideToClose] == PPRevealSideDirectionNone) ? YES : NO;
    if (isClosed)
    {
        // no tap gesture required when closed. So remove the old ones
        [self removeAllTapGestures];
        return;
    }
	
    // Nav Bar
    if (_tapInteractionsWhenOpened & PPRevealSideInteractionNavigationBar && ([controller isKindOfClass:[UINavigationController class]] || controller.navigationController)) {
        UINavigationController *nav;
        if ([controller isKindOfClass:[UINavigationController class]])
            nav = (UINavigationController*)controller;
        else
            nav = controller.navigationController;
        
        [self addTapGestureToView:nav.navigationBar];
    }
    
    // Content View
    if (_tapInteractionsWhenOpened & PPRevealSideInteractionContentView) {
        UIViewController *c;
        if ([controller isKindOfClass:[UINavigationController class]]) {
            c = [((UINavigationController*)controller).viewControllers lastObject];
        }
        else
            if (controller.navigationController)
                c = [controller.navigationController.viewControllers lastObject];
            else
                c = controller;
        
        [self addTapGestureToView:c.view];
    }
    
    // Customs views
    if ([self.delegate respondsToSelector:@selector(customViewsToAddTapGestureOnPPRevealSideViewController:)]) {
        NSArray *views = [self.delegate customViewsToAddTapGestureOnPPRevealSideViewController:self];
        if (views)
            for (UIView *vi in views)
                if ([vi isKindOfClass:[UIView class]])
                    [self addTapGestureToView:vi];
    }
}

- (void) addGesturesToController:(UIViewController*)controller {
    [self removeAllGestures];
    [self addPanGestureToController:controller];
    [self addTapGestureToController:controller];
}

- (void) addGesturesToCenterController
{
    [self addGesturesToController:[self getControllerForGestures]];
}

- (void) removeAllPanGestures {
    NSMutableArray *array = [NSMutableArray arrayWithArray:_gestures];
    for (UIGestureRecognizer* panGest in array) {
        if ([panGest isKindOfClass:[UIPanGestureRecognizer class]]) {
            [panGest.view removeGestureRecognizer:panGest];
            [_gestures removeObject:panGest];
        }
    }
}

- (void) removeAllTapGestures {
    NSMutableArray *array = [NSMutableArray arrayWithArray:_gestures];
    for (UIGestureRecognizer* tapGest in array) {
        if ([tapGest isKindOfClass:[UITapGestureRecognizer class]]) {
            [tapGest.view removeGestureRecognizer:tapGest];
            [_gestures removeObject:tapGest];
        }
    }
}

- (void) removeAllGestures {
    for (UIGestureRecognizer* gest in _gestures) {
        [gest.view removeGestureRecognizer:gest];
    }
    [_gestures removeAllObjects];
}

- (void) updateViewWhichHandleGestures
{
    [self addGesturesToCenterController];
}

- (void) setOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction
{
    // This is always an offset for portrait
    [_viewControllersOffsets setObject:[NSNumber numberWithFloat:offset] forKey:[NSNumber numberWithInt:direction]];
}

- (void) removeControllerFromView:(UIViewController*)controller animated:(BOOL)animated
{
    if (PPSystemVersionGreaterOrEqualThan(5.0)) [controller willMoveToParentViewController:nil];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [controller viewWillDisappear:animated];
    
    [controller.view removeFromSuperview];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [controller viewDidDisappear:animated];
    if (PPSystemVersionGreaterOrEqualThan(5.0))
    {
        [controller removeFromParentViewController];
    }
}

- (void) tryToRemoveObserverOnFrame
{
    @try {
        [_rootViewController removeObserver:self forKeyPath:@"view.frame"];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
}

#pragma mark - Closed Controllers

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

- (BOOL) isOptionEnabled:(PPRevealSideOptions)option {
    return ((_options & option) == option);
}

- (BOOL) canCrossOffsets {
    return ![self isOptionEnabled:PPRevealSideOptionsResizeSideView] && [self isOptionEnabled:PPRevealSideOptionsBounceAnimations];
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
    //if (_wasClosed)
    // Don't know why I limited this test to the case pan from close. The same set min should happen when from open.
    // That's probably a failed attempt to handle slide from left to right when having controllers on both side. This works fine without this test
    if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) offset = MIN(CGRectGetWidth(PPScreenBounds()), offset);
    
    if (direction == PPRevealSideDirectionTop || direction == PPRevealSideDirectionBottom) offset = MIN(CGRectGetHeight(self.view.frame), offset);
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


- (CGRect) getSideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction alreadyFullScreenLayout:(BOOL)alreadyFullScreenLayout{
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
        CGFloat offset = [self getOffsetForDirection:direction];
        
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
	
    return inset;
}

- (CGFloat) getOffsetForDirection:(PPRevealSideDirection)direction andInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGFloat offset = [[_viewControllersOffsets objectForKey:[NSNumber numberWithInt:direction]] floatValue];
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        if (![self isOptionEnabled:PPRevealSideOptionsKeepOffsetOnRotation])
        {
            // Take an orientation free rect
            CGRect portraitBounds = [UIScreen mainScreen].bounds;
            // Get the difference between width and height
            CGFloat diff = 0.0;
            if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight)
                diff = portraitBounds.size.height - portraitBounds.size.width;
            if (direction == PPRevealSideDirectionTop)
                diff = -(portraitBounds.size.height - portraitBounds.size.width);
			
            // Store the offset + the diff
            offset += diff;
        }
    }
	
    return offset;
}

- (CGFloat) getOffsetForDirection:(PPRevealSideDirection)direction
{
    return [self getOffsetForDirection:direction andInterfaceOrientation:PPInterfaceOrientation()];
}

#pragma mark - Gesture recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    _panOrigin = _rootViewController.view.frame.origin;
    gestureRecognizer.enabled = YES;
    _currentPanDirection = [self getSideToClose];
    if (_currentPanDirection == PPRevealSideDirectionNone) _wasClosed = YES;
    else _wasClosed = NO;
	
    BOOL hasExceptionTouch = NO;
    if ([touch.view isKindOfClass:[UIControl class]] && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        if (![touch.view isKindOfClass:NSClassFromString(@"UINavigationButton")]) hasExceptionTouch = YES;
    }
	
    BOOL hasExceptionDelegate = NO;
    if ([self.delegate respondsToSelector:@selector(pprevealSideViewController:shouldDeactivateGesture:forView:)])
        hasExceptionDelegate = [self.delegate pprevealSideViewController:self
                                                 shouldDeactivateGesture:gestureRecognizer
                                                                 forView:touch.view];
    
    if ([self.delegate respondsToSelector:@selector(pprevealSideViewController:directionsAllowedForPanningOnView:)]) {
        _disabledPanGestureDirection = [self.delegate pprevealSideViewController:self directionsAllowedForPanningOnView:touch.view];
    }
    else
        _disabledPanGestureDirection = PPRevealSideDirectionLeft | PPRevealSideDirectionRight | PPRevealSideDirectionTop | PPRevealSideDirectionBottom;
    
    return !_animationInProgress && !hasExceptionTouch && !hasExceptionDelegate;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

    // If there is a scroll view gesture recognised, save it, we may cancel it in the future
    if ([otherGestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
        PP_RELEASE(_tableViewSwipeGestureRecognizer);
        _tableViewSwipeGestureRecognizer = PP_RETAIN(otherGestureRecognizer);
    }
    return YES;
}



- (void) gestureRecognizerDidPan:(UIPanGestureRecognizer*)panGesture {
    
    if(_animationInProgress) return;
    
    CGPoint currentPoint = [panGesture translationInView:self.view];
    
    CGFloat x = currentPoint.x + _panOrigin.x;
    CGFloat y = currentPoint.y + _panOrigin.y;
	
    CGFloat offset = 0;
	
    // if the center view controller is closed, then get the direction we want to Open
    if (_currentPanDirection == PPRevealSideDirectionNone) {
        CGFloat panDiffX = currentPoint.x - _panOrigin.x;
        CGFloat panDiffY = currentPoint.y - _panOrigin.y;
		
        if (panDiffX > 0 && panDiffX > OFFSET_TRIGGER_CHOSE_DIRECTION)
            _currentPanDirection = PPRevealSideDirectionLeft;
        else
            if (panDiffX < 0 && panDiffX < OFFSET_TRIGGER_CHOSE_DIRECTION)
                _currentPanDirection = PPRevealSideDirectionRight;
            else
                if (panDiffY > 0 && panDiffY > OFFSET_TRIGGER_CHOSE_DIRECTION)
                    _currentPanDirection = PPRevealSideDirectionTop;
                else
                    if (panDiffY < 0 && panDiffY < OFFSET_TRIGGER_CHOSE_DIRECTION)
                        _currentPanDirection = PPRevealSideDirectionBottom;
        
    }
    
    if (_currentPanDirection == PPRevealSideDirectionNone) return;
    
    // if the direction is disabled, then cancel the gesture
    if ((_currentPanDirection & _disabledPanGestureDirection) != _currentPanDirection) {
        // little trick to cancel the gesture. Otherwise, as long as we pan, we continue to pass here ...
        panGesture.enabled = NO;
        panGesture.enabled = YES;
        return;
    }
    
    // If the direction is left or right, then cancel the swipe gesture to avoid double scrolling
    if (
        (_currentPanDirection == PPRevealSideDirectionLeft && [self controllerForSide:PPRevealSideDirectionLeft])
        ||
        (_currentPanDirection == PPRevealSideDirectionRight && [self controllerForSide:PPRevealSideDirectionRight])
        )
    {
        // This is a simple way to cancel a gesture
        _tableViewSwipeGestureRecognizer.enabled = NO;
        _tableViewSwipeGestureRecognizer.enabled = YES;
        PP_RELEASE(_tableViewSwipeGestureRecognizer);
    }
    
    // see if there is a controller or not for the direction. If yes, then add it.
    UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:_currentPanDirection]];
    if (c) {
        if (!c.view.superview)
        {
            c.view.frame = self.rootViewController.view.bounds;
            if (PPSystemVersionGreaterOrEqualThan(5.0))
            {
                [self addChildViewController:c];
            }
            
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) [c viewWillAppear:NO];
            [self.view insertSubview:c.view belowSubview:_rootViewController.view];
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) [c viewDidAppear:NO];
            
            if (PPSystemVersionGreaterOrEqualThan(5.0)) [c didMoveToParentViewController:self];
        }
        c.view.hidden = NO;
    }
    else // we use the bounce animation
    {
        PPRSLog(@"****** No controller to push ****** Think to preload controller ! ******");
        [self pushOldViewControllerOnDirection:_currentPanDirection animated:YES completion:nil];
        // little trick to cancel the gesture. Otherwise, as long as we pan, we continue to pass here ...
        panGesture.enabled = NO;
        panGesture.enabled = YES;
        return;
    }
	
    switch (_currentPanDirection) {
        case PPRevealSideDirectionLeft:
            offset = CGRectGetWidth(self.rootViewController.view.frame) - x;
            break;
        case PPRevealSideDirectionRight:
            offset = x + CGRectGetWidth(self.rootViewController.view.frame);
            break;
        case PPRevealSideDirectionBottom:
            offset = y + CGRectGetHeight(self.rootViewController.view.frame);
            break;
        case PPRevealSideDirectionTop:
            offset = CGRectGetHeight(self.rootViewController.view.frame) - y;
            break;
        default:
            break;
    }
    CGFloat oldOffsetBeforeMax = offset;
    offset = MAX(offset, [self getOffsetForDirection:_currentPanDirection]);
	
    // test if whe changed direction
    if (_currentPanDirection == PPRevealSideDirectionRight || _currentPanDirection == PPRevealSideDirectionLeft) {
        if (offset >= CGRectGetWidth(self.rootViewController.view.frame)-OFFSET_TRIGGER_CHANGE_DIRECTION) {
            // change direction if possible
            PPRevealSideDirection newDirection;
            if (_currentPanDirection == PPRevealSideDirectionLeft)
                newDirection = PPRevealSideDirectionRight;
            else
                newDirection = PPRevealSideDirectionLeft;
            
            if ([_viewControllers objectForKey:[NSNumber numberWithInt:newDirection]]) {
                UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:_currentPanDirection]];
                
                [self removeControllerFromView:c animated:YES];
                
                _currentPanDirection = newDirection;
                _wasClosed = !_wasClosed;
                return;
            }
            
            
        }
    }
    else
    {
        if (offset >= CGRectGetHeight(self.rootViewController.view.frame) - OFFSET_TRIGGER_CHANGE_DIRECTION) {
            // change direction if possible
            PPRevealSideDirection newDirection;
            if (_currentPanDirection == PPRevealSideDirectionBottom)
                newDirection = PPRevealSideDirectionTop;
            else
                newDirection = PPRevealSideDirectionBottom;
            
            if ([_viewControllers objectForKey:[NSNumber numberWithInt:newDirection]]) {
                UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:_currentPanDirection]];
                
                [self removeControllerFromView:c animated:YES];
                
                _currentPanDirection = newDirection;
                _wasClosed = !_wasClosed;
                return;
            }
        }
    }
    
    if (!_wasClosed)
        offset = oldOffsetBeforeMax;
    
    self.rootViewController.view.frame = [self getSlidingRectForOffset:offset
                                                          forDirection:_currentPanDirection];
    
    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        
        CGFloat offsetController = [self getOffsetForDirection:_currentPanDirection];
		
        CGFloat triggerStep;
        if (_currentPanDirection == PPRevealSideDirectionLeft || _currentPanDirection == PPRevealSideDirectionRight)
            triggerStep = (CGRectGetWidth(self.rootViewController.view.frame) - offsetController)/divisionNumber;
        else
            triggerStep = (CGRectGetHeight(self.rootViewController.view.frame) - offsetController)/divisionNumber;
        
        
        BOOL shouldClose;
        
        CGFloat sizeToTest;
        CGFloat offsetTriggered;
        
        // set a max trigger
        triggerStep = MIN(triggerStep, MAX_TRIGGER_OFFSET);
        
        if (_currentPanDirection == PPRevealSideDirectionLeft || _currentPanDirection == PPRevealSideDirectionRight)
        {
            sizeToTest = CGRectGetWidth(self.rootViewController.view.frame);
        }
        else
        {
            sizeToTest = CGRectGetHeight(self.rootViewController.view.frame);
        }
        
        if (_wasClosed)
        {
            offsetTriggered = sizeToTest - triggerStep;
        }
        else
        {
            offsetTriggered = triggerStep+offsetController;
        }
        
        //PPRSLog(@"offset %f ** sizeToTest %f ** triggerStep %f ** - %f", offset, sizeToTest, triggerStep, offsetTriggered);
        if (offset > offsetTriggered)
            shouldClose = YES;
        else
            shouldClose = NO;
        
        if (shouldClose) {
            _popFromPanGesture = YES;
            [self popViewControllerAnimated:YES completion:nil];
        }
        else
        {
            _shouldNotCloseWhenPushingSameDirection = YES;
            [self pushOldViewControllerOnDirection:_currentPanDirection
                                        withOffset:[self getOffsetForDirection:_currentPanDirection andInterfaceOrientation:UIInterfaceOrientationPortrait] // we get the interface orientation for Portrait since we set it just after.
                                          animated:YES
										completion:nil];
            _shouldNotCloseWhenPushingSameDirection = NO;
        }
    }
}

- (void) gestureRecognizerDidTap:(UITapGestureRecognizer*)tapGesture {
    PPRSLog(@"Yes, the tap gesture is animated, this is normal, not a bug! Is there anybody here with a non animate interface? :P");
    [self popViewControllerAnimated:YES completion:nil];
}

#pragma mark - Orientation stuff

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
    [self resizeCurrentView];
	
    for (id key in _viewControllers.allKeys)
    {
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        
        if (controller.view.superview) {
            controller.view.frame = [self getSideViewFrameFromRootFrame:_rootViewController.view.frame
                                                           andDirection:[key intValue]
                                                alreadyFullScreenLayout:controller.wantsFullScreenLayout];
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self removeShadow];
    //_rootViewController.view.layer.shouldRasterize = YES;
    
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    return;
    
    for (id key in _viewControllers.allKeys)
    {
        // optimisation
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        if (controller.view.superview && !PPSystemVersionGreaterOrEqualThan(5.0))
            [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    //_rootViewController.view.layer.shouldRasterize = NO;
    [self handleShadows];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) [_rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    for (id key in _viewControllers.allKeys)
    {
        // optimisation
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        if (controller.view.superview && !PPSystemVersionGreaterOrEqualThan(5.0))
            [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [_rootViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark iOS 6 rotation
// Not sure about that (asking the root view controller), but at least it should work.
// I was looking for something more complicated/sophisticated, but that's maybe that easy

- (BOOL) shouldAutorotate{
    return [_rootViewController shouldAutorotate];
}

- (NSUInteger) supportedInterfaceOrientations{
    return [_rootViewController supportedInterfaceOrientations];
}

#pragma mark - Memory management things

- (void) viewWillUnload
{
    [super viewWillUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if (!PPSystemVersionGreaterOrEqualThan(6.0)) {
        // Because the view will load. In iOS 6, there is no such behavior of load / unload
        // I could have put it in didUnload, but I probably place it here for a good reason (don't remember which)
        [self tryToRemoveObserverOnFrame];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarFrameNotification
                                                  object:nil];
}

- (void) dealloc {
    PPRSLog();
    [self tryToRemoveObserverOnFrame];
    
    PP_RELEASE(_rootViewController);
    PP_RELEASE(_viewControllers);
    PP_RELEASE(_viewControllersOffsets);
    [self removeAllGestures];
    PP_RELEASE(_gestures);
    PP_RELEASE(_tableViewSwipeGestureRecognizer);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarFrameNotification
                                                  object:nil];
#if !PP_ARC_ENABLED
    [super dealloc];
#endif
}

@end



#pragma mark -
@implementation UIViewController (PPRevealSideViewController)
static char revealSideViewControllerKey;

- (void) setRevealSideViewController:(PPRevealSideViewController *)revealSideViewController {
    [self willChangeValueForKey:@"revealSideViewController"];
    objc_setAssociatedObject( self,
                             &revealSideViewControllerKey,
                             revealSideViewController,
                             OBJC_ASSOCIATION_ASSIGN );
    [self didChangeValueForKey:@"revealSideViewController"];
}

- (PPRevealSideViewController*) revealSideViewController {
    id controller = objc_getAssociatedObject( self,
                                             &revealSideViewControllerKey );
    
    // because we can't ask the navigation controller to set to the pushed controller the revealSideViewController !
    if (!controller && self.navigationController)
        controller = self.navigationController.revealSideViewController;
    
    if (!controller && self.tabBarController)
        controller = self.tabBarController.revealSideViewController;
    
    return controller;
}

@end

#pragma mark -
@implementation UIView (PPRevealSideViewController)
static char revealSideInsetKey;

- (void) setRevealSideInset:(UIEdgeInsets)revealSideInset {
    [self willChangeValueForKey:@"revealSideInset"];
    NSString *stringInset = NSStringFromUIEdgeInsets(revealSideInset);
    objc_setAssociatedObject( self,
                             &revealSideInsetKey,
                             stringInset,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC );
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

CGFloat PPStatusBarHeight(void) {
    if ([[UIApplication sharedApplication] isStatusBarHidden]) return 0.0;
    if (UIInterfaceOrientationIsLandscape(PPInterfaceOrientation()))
        return [[UIApplication sharedApplication] statusBarFrame].size.width;
    else
        return [[UIApplication sharedApplication] statusBarFrame].size.height;
}