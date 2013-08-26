//
//  PPRevealSideViewController.m
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import "PPRevealSideViewController.h"
#import "PPRevealSideViewController+Protected.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>



// Define constant values
const CGFloat        PPRevealSideDefaultOffset                   = 70.0;
const CGFloat        PPRevealSideDefaultOffsetBouncing           = 5.0;
const CGFloat        PPRevealSideDefaultResizeOverlap            = 8.0;
const NSTimeInterval PPRevealSideOpenAnimationTime               = 0.3;
const NSTimeInterval PPRevealSideOpenAnimationTimeBouncingRatio  = 0.3;
const NSTimeInterval PPRevealSideOpenAnimationTimeErrorRatio     = 0.15;
const CGFloat        PPRevealSideBounceErrorOffset               = 14.0;
const CGFloat        PPRevealSideTriggerChooseDirection          = 3.0;
const CGFloat        PPRevealSideTriggerChangeDirection          = 0.0;
const CGFloat        PPRevealSideMaxTriggerOffset                = 100.0;
const CGFloat        PPRevealSideMinTouchableSize                = 44.0;
const CGFloat        PPRevealSideStatusbarHeight                 = 20.0;
const double         PPRevealSideTriggerStepFactor               = 5.0;
const CGFloat        PPRevealSideNavigationControllerPopTreshold = 100.0;



@implementation PPRevealSideViewController

@synthesize rootViewController = _rootViewController;
@synthesize panInteractionsWhenClosed = _panInteractionsWhenClosed;
@synthesize panInteractionsWhenOpened = _panInteractionsWhenOpened;
@synthesize tapInteractionsWhenOpened = _tapInteractionsWhenOpened;
@synthesize directionsToShowBounce = _directionsToShowBounce;
@synthesize options = _options;
@synthesize resizeSides = _resizeSides;
@synthesize resizeOverlap = _resizeOverlap;
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
        self.tapInteractionsWhenOpened = PPRevealSideInteractionNavigationBar | PPRevealSideInteractionContentView;
        
        self.directionsToShowBounce = PPRevealSideDirectionsAll;
        
        _viewControllers        = [NSMutableDictionary dictionaryWithCapacity:5];
        _viewControllersOffsets = [NSMutableDictionary dictionaryWithCapacity:5];
        _resizeOverlap          = [NSMutableDictionary dictionaryWithCapacity:5];
        
        _gestures = [NSMutableArray new];
        
        [self setRootViewController:rootViewController];
    }
    return self;
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    CGRect rect  = PPScreenBounds();
    rect.size.height -= PPStatusBarHeight();
    self.view = PP_AUTORELEASE([[UIView alloc] initWithFrame:rect]);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.clipsToBounds = YES;
    self.view.autoresizesSubviews = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController viewWillAppear:animated];
    }
    
    PPRevealSideDirection direction = self.sideToClose;
    if (direction != PPRevealSideDirectionNone) {
        [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController viewDidAppear:animated];
    }
    
    PPRevealSideDirection direction = self.sideToClose;
    if (direction != PPRevealSideDirectionNone) {
        [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewDidAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController viewWillDisappear:animated];
    }
    
    PPRevealSideDirection direction = self.sideToClose;
    if (direction != PPRevealSideDirectionNone) {
        [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController viewDidDisappear:animated];
    }
    
    PPRevealSideDirection direction = self.sideToClose;
    if (direction != PPRevealSideDirectionNone) {
        [[_viewControllers objectForKey:[NSNumber numberWithInt:direction]] viewDidDisappear:animated];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_rootViewController && !_rootViewController.view.superview) {
        // Then we have probably received memory warning
        UIViewController *newRoot = PP_RETAIN(_rootViewController);
        // Just a little hack to reset the root
        self.rootViewController = nil;
        self.rootViewController = newRoot;
        PP_RELEASE(newRoot);
    }
}


#pragma mark - Push and pop methods

- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self pushViewController:controller
                 onDirection:direction
                  withOffset:[self offsetForDirection:direction]
                    animated:animated];
}

- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush {
    [self pushViewController:controller
                 onDirection:direction
                  withOffset:[self offsetForDirection:direction]
                    animated:animated
              forceToPopPush:forcePopPush];
}

- (void)pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self pushOldViewControllerOnDirection:direction
                                withOffset:[self offsetForDirection:direction]
                                  animated:animated];
}

- (void)pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated {
    UIViewController *oldController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (oldController) {
        [self pushViewController:oldController
                     onDirection:direction
                      withOffset:offset
                        animated:animated];
    } else {
        if ((_directionsToShowBounce & direction) == direction) {
            // make a small animation to indicate that there is not yet a controller
            CGRect originalFrame = _rootViewController.view.frame;
            _animationInProgress = YES;
            [UIView animateWithDuration:PPRevealSideOpenAnimationTime * PPRevealSideOpenAnimationTimeErrorRatio
                                  delay:0.0
                                options:UIViewAnimationCurveEaseInOut
                             animations:^{
                                 CGFloat offsetBounce;
                                 if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) {
                                     offsetBounce = CGRectGetWidth(_rootViewController.view.frame) - PPRevealSideBounceErrorOffset;
                                 } else {
                                     offsetBounce = CGRectGetHeight(_rootViewController.view.frame) - PPRevealSideBounceErrorOffset;
                                 }
                                 _rootViewController.view.frame = [self slidingRectForOffset:offsetBounce
                                                                                forDirection:direction];
                             } completion:^(BOOL finished) {
                                 [UIView animateWithDuration:PPRevealSideOpenAnimationTime * PPRevealSideOpenAnimationTimeErrorRatio
                                                       delay:0.0
                                                     options:UIViewAnimationCurveEaseInOut
                                                  animations:^{
                                                      _rootViewController.view.frame = originalFrame;
                                                  } completion:^(BOOL finished) {
                                                      _animationInProgress = NO;
                                                  }];
                             }];
        }
    }
}

- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated {
    [self pushViewController:controller
                 onDirection:direction 
                  withOffset:offset
                    animated:animated
              forceToPopPush:NO];   
}

- (void)pushViewController:(UIViewController *)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush {
    if (_animationInProgress) {
        return;
    }

    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPushController:) withParam:controller];
    
    // Get the side direction to close
    PPRevealSideDirection directionToClose = self.sideToClose;
    
    // If this is the same direction, then close it
    if (directionToClose == direction && !_shouldNotCloseWhenPushingSameDirection) {
        if (!forcePopPush) {
            // then pop
            [self popViewControllerWithNewCenterController:_rootViewController animated:animated];
        } else {
            // pop and push
            [self popViewControllerWithNewCenterController:_rootViewController 
                                                  animated:animated 
                                   andPresentNewController:controller
                                             withDirection:direction 
                                                 andOffset:offset];
        }
        return;
    } else {
        // If the direction is different, and we close completely before opening, then pop / push !
        if (directionToClose != PPRevealSideDirectionNone && [self isOptionEnabled:PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection] && !_shouldNotCloseWhenPushingSameDirection) {
            [self popViewControllerWithNewCenterController:_rootViewController 
                                                  animated:animated 
                                   andPresentNewController:controller withDirection:direction andOffset:offset];
            return;
        }
    }
    
    _animationInProgress = YES;
    
    NSNumber *directionNumber = [NSNumber numberWithInt:direction];
    
    // Save the offset
    [self setOffset:offset forDirection:direction];
    
    // Get the offset with orientation aware stuff
    offset = [self offsetForDirection:direction];
    
    // Remove the old controller from the view
    UIViewController *oldController = [_viewControllers objectForKey:directionNumber];
    if (controller != oldController) {
        [self removeControllerFromView:oldController animated:animated];
    }
    
    [_viewControllers setObject:controller forKey:directionNumber];
    
    // Set the container controller to self
    controller.revealSideViewController = self;
    
    // Place the controller juste below the rootviewcontroller
    controller.view.frame = self.view.bounds; // handle layout issue with navigation bar. Comment to see the crap, then push a nav controller
    
    
    // TODO remove then adding not so good ... Maybe do something different
    [self removeControllerFromView:controller animated:animated];
    if (PPSystemVersionGreaterOrEqualThan(5.0)) {
        [self addChildViewController:controller];
    }
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [controller viewWillAppear:animated];
    }
    
    [self.view insertSubview:controller.view belowSubview:_rootViewController.view];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [controller viewDidAppear:animated];
    }
    
    
    // If bounces is activated and the push is animated, calculate the first frame with the bounce
    CGRect rootFrame = CGRectZero;
    if ([self canCrossOffsets] && animated) {
        // then we make an offset
        rootFrame = [self slidingRectForOffset:offset - ((_bouncingOffset == - 1.0) ? PPRevealSideDefaultOffsetBouncing : _bouncingOffset) forDirection:direction];
    } else {
        rootFrame = [self slidingRectForOffset:offset forDirection:direction];
    }
    
    void (^openAnimBlock)(void) = ^(void) {
        controller.view.hidden = NO;        
        _rootViewController.view.frame = rootFrame;
    };
    
    void (^innerCompletion)(BOOL) = ^(BOOL finished){
        _animationInProgress = NO;
        if (PPSystemVersionGreaterOrEqualThan(5.0)) {
            [controller didMoveToParentViewController:self];
        }
        [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPushController:) withParam:controller];
    };
    
    // Replace the view since IB add some offsets with the status bar if enabled
    controller.view.frame = [self sideViewFrameFromRootFrame:rootFrame
                                                   andDirection:direction];
    
    NSTimeInterval animationTime = PPRevealSideOpenAnimationTime;
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionLayoutSubviews;
    
    if (animated) {
        [UIView animateWithDuration:animationTime
                              delay:0.0
                            options:options
                         animations:openAnimBlock
                         completion:^(BOOL finished) {
                             if (self.canCrossOffsets) {
                                 // then we come to normal
                                 [UIView animateWithDuration:animationTime * PPRevealSideOpenAnimationTimeBouncingRatio
                                                       delay:0.0
                                                     options:options
                                                  animations:^{
                                                      _rootViewController.view.frame = [self slidingRectForOffset:offset forDirection:direction];
                                                  } completion:innerCompletion];
                             } else {
                                 innerCompletion(YES);
                             }
                         }];
    } else {
        openAnimBlock();
        innerCompletion(YES);
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
    if (_animationInProgress) {
        return;
    }
    
    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:willPopToController:) withParam:centerController];

    PPRevealSideDirection directionToClose = self.sideToClose;
    if (directionToClose == PPRevealSideDirectionNone && _popFromPanGesture) {
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

            // This is the anim block to center the controller to the default position
            void(^smallAnimBlock)(void) = ^(void) {
                CGRect newFrame = _rootViewController.view.frame;
                newFrame.origin.x = 0.0;
                newFrame.origin.y = 0.0;
                _rootViewController.view.frame = newFrame;
            };
            
            // This is the completion block to pop and then push the new controller
            void (^smallAnimBlockCompletion)(BOOL) = ^(BOOL finished) {
                if (finished) {
                    [self informDelegateWithOptionalSelector:@selector(pprevealSideViewController:didPopToController:) withParam:centerController];
                    
                    // Remove the view (don't need to surcharge (not english this word ? ... ) all the interface).
                    UIViewController *oldController = (UIViewController*)[_viewControllers objectForKey:[NSNumber numberWithInt:directionToClose]];
                    [self removeControllerFromView:oldController animated:animated];
                    
                    _animationInProgress = NO;

                    if (controllerToPush) {
                        [self pushViewController:controllerToPush
                                     onDirection:direction
                                      withOffset:offset
                                        animated:animated];
                    }
                }
            };
            
            // Execute the blocks depending on animated or not
            if (animated) {
                NSTimeInterval animationTime = PPRevealSideOpenAnimationTime;
                
                [UIView animateWithDuration:animationTime
                                      delay:0.0
                                    options:options
                                 animations:smallAnimBlock
                                 completion:smallAnimBlockCompletion];
            } else {
                smallAnimBlock();
                smallAnimBlockCompletion(YES);
            }
        }
    };
    
    // Now we are gonna use the big block !!
    if (self.canCrossOffsets && animated && centerController != _rootViewController) {
        PPRevealSideDirection directionToOpen = self.sideToClose;
        
        // Open completely and then close it
        [UIView animateWithDuration:PPRevealSideOpenAnimationTime * PPRevealSideOpenAnimationTimeBouncingRatio
                              delay:0.0
                            options:options
                         animations:^{
                             // this will open completely the view
                             _rootViewController.view.frame = [self slidingRectForOffset:0.0 forDirection:directionToOpen];
                         } completion:bigAnimBlock];
    } else {
        // We just execute the close anim block
        if (animated) {
            [UIView animateWithDuration:PPRevealSideOpenAnimationTime
                                  delay:0.0
                                options:options
                             animations:^{
                                 bigAnimBlock(YES);
                             } completion:^(BOOL finished) {
                             }];
            
        } else {
            bigAnimBlock(YES);
        }
    }
}

- (void)preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction {
    [self preloadViewController:controller
                        forSide:direction
                     withOffset:PPRevealSideDefaultOffset];
}

- (void)preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset {
    [self preloadViewController:controller
                        forSide:direction
                     withOffset:offset
                   forceRemoval:NO];
}

- (void)preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset forceRemoval:(BOOL)force {
    if (direction == [self sideDirectionOpened] && !force) {
        return;
    }
    
    UIViewController *existingController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
    if (existingController != controller) {
        if (existingController.view.superview) {
            [self removeControllerFromView:existingController animated:NO];
        }
        
        [_viewControllers setObject:controller forKey:[NSNumber numberWithInt:direction]];
        controller.revealSideViewController = self;
        
        if (![controller isViewLoaded]) {
            if (PPSystemVersionGreaterOrEqualThan(5.0)) {
                [controller willMoveToParentViewController:self];
            }
            
            [self.view insertSubview:controller.view atIndex:0];
            
            if (PPSystemVersionGreaterOrEqualThan(5.0)) {
                [self addChildViewController:controller];
                [controller didMoveToParentViewController:self];
            }
            controller.view.hidden = YES;
        }
        controller.view.frame = self.view.bounds;
    }    
    [self setOffset:offset forDirection:direction];
}

- (void)unloadViewControllerForSide:(PPRevealSideDirection)direction {
    NSNumber *key = [NSNumber numberWithInt:direction];
    UIViewController *controller = [_viewControllers objectForKey:key];
    
    [self removeControllerFromView:controller animated:NO];
    
    [_viewControllers removeObjectForKey:key];
}

- (void)removeControllerFromView:(UIViewController*)controller animated:(BOOL)animated {
    if (PPSystemVersionGreaterOrEqualThan(5.0)) {
        [controller willMoveToParentViewController:nil];
    } else {
        [controller viewWillDisappear:animated];
    }
    
    [controller.view removeFromSuperview];
    
    if (PPSystemVersionGreaterOrEqualThan(5.0)) {
        [controller removeFromParentViewController];
    } else {
        [controller viewDidDisappear:animated];
    }
}

- (void)changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
    [self changeOffset:offset forDirection:direction animated:NO];
}

- (void)changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction animated:(BOOL)animated {
    [self setOffset:offset forDirection:direction];
    
    if (self.sideToClose == direction) {
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 _rootViewController.view.frame = [self slidingRectForOffset:offset
                                                                                forDirection:direction];
                             }];
        } else {
            _rootViewController.view.frame = [self slidingRectForOffset:offset
                                                           forDirection:direction];
        }
    }
}


#pragma mark - Observation method

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"view.frame"]) {
        PPRevealSideDirection direction = self.sideToClose;
        UIViewController *openedController = [_viewControllers objectForKey:[NSNumber numberWithInt:direction]];
        if (openedController) {
            openedController.view.revealSideInset = [self edgeInsetsForDirection:direction];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Setters

- (void)setOptions:(PPRevealSideOptions)options {
    [self willChangeValueForKey:@"options"];
    _options = options;
    [self handleShadows];
    [self didChangeValueForKey:@"options"];
}

- (void)setOption:(PPRevealSideOptions)option {
    _options |= option;
    if (option == PPRevealSideOptionsShowShadows) [self handleShadows];
}

- (void)resetOption:(PPRevealSideOptions)option {
    _options ^= option;
    if (option == PPRevealSideOptionsShowShadows) [self handleShadows];
}

- (void)setResizeSides:(PPRevealSideDirection)resizeSides {
    [self willChangeValueForKey:@"resizeSides"];
    _resizeSides = resizeSides;
    [self didChangeValueForKey:@"resizeSides"];
}

- (void)setResizeSide:(PPRevealSideDirection)direction {
    _resizeSides |= direction;
}

- (void)resetResizeSide:(PPRevealSideDirection)direction {
    _resizeSides ^= direction;
}

- (void)setResizeOverlap:(CGFloat)overlap forSide:(PPRevealSideDirection)direction {
    [self setResizeSide:direction];
    [_resizeOverlap setObject:[NSNumber numberWithFloat:overlap] forKey:[NSNumber numberWithInt:direction]];
}

- (void)setPanInteractionsWhenClosed:(PPRevealSideInteractions)panInteractionsWhenClosed {
    [self willChangeValueForKey:@"panInteractionsWhenClosed"];
    _panInteractionsWhenClosed = panInteractionsWhenClosed;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"panInteractionsWhenClosed"];
}

- (void)setPanInteractionsWhenOpened:(PPRevealSideInteractions)panInteractionsWhenOpened {
    [self willChangeValueForKey:@"panInteractionsWhenOpened"];
    _panInteractionsWhenOpened = panInteractionsWhenOpened;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"panInteractionsWhenOpened"];
}

- (void)setTapInteractionsWhenOpened:(PPRevealSideInteractions)tapInteractionsWhenOpened {
    [self willChangeValueForKey:@"tapInteractionsWhenOpened"];
    _tapInteractionsWhenOpened = tapInteractionsWhenOpened;
    [self addGesturesToCenterController];
    [self didChangeValueForKey:@"tapInteractionsWhenOpened"];
}

- (void)setOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
    // This is always an offset for portrait
    [_viewControllersOffsets setObject:[NSNumber numberWithDouble:offset] forKey:[NSNumber numberWithInt:direction]];
}


#pragma mark - Getters

- (UIViewController *)controllerForSide:(PPRevealSideDirection)side {
    return [_viewControllers objectForKey:[NSNumber numberWithInt:side]];
}

- (BOOL)isOptionEnabled:(PPRevealSideOptions)option {
    return ((_options & option) == option);
}

- (BOOL)canCrossOffsets {
    return ![self isOptionEnabled:PPRevealSideOptionsResizeSideView] && [self isOptionEnabled:PPRevealSideOptionsBounceAnimations];
}

- (PPRevealSideDirection)sideDirectionOpened {
    return self.sideToClose;
}

- (PPRevealSideDirection)sideToClose {
    PPRevealSideDirection sideToReturn = PPRevealSideDirectionNone;
    if (!self.isRightControllerClosed)  sideToReturn = PPRevealSideDirectionRight;
    if (!self.isLeftControllerClosed)   sideToReturn = PPRevealSideDirectionLeft;
    if (!self.isTopControllerClosed)    sideToReturn = PPRevealSideDirectionTop;
    if (!self.isBottomControllerClosed) sideToReturn = PPRevealSideDirectionBottom;
    return sideToReturn;
}


#pragma mark Closed Controllers

- (BOOL)isLeftControllerClosed {
    return CGRectGetMinX(_rootViewController.view.frame) <= 0;
}

- (BOOL)isRightControllerClosed {
    return CGRectGetMaxX(_rootViewController.view.frame) >= CGRectGetWidth(_rootViewController.view.frame);
}

- (BOOL)isTopControllerClosed {
    return CGRectGetMinY(_rootViewController.view.frame) <= 0;
}

- (BOOL)isBottomControllerClosed {
    return CGRectGetMaxY(_rootViewController.view.frame) >= CGRectGetHeight(_rootViewController.view.frame);
}


#pragma mark - Private methods

- (void)tryToRemoveObserverOnFrame {
    @try {
        [_rootViewController removeObserver:self forKeyPath:@"view.frame"];
    } @catch (NSException *exception) {
    } @finally {
    }
}

- (void)setRootViewController:(UIViewController *)controller replaceToOrigin:(BOOL)replace {
    if (_rootViewController != controller) {
        [self willChangeValueForKey:@"rootViewController"];
        
        [self removeAllGestures];

        [self tryToRemoveObserverOnFrame];
        
        [self removeControllerFromView:_rootViewController animated:NO];
        
        PP_RELEASE(_rootViewController);
        _rootViewController = PP_RETAIN(controller);
        _rootViewController.revealSideViewController = self;
        
        if (PPSystemVersionGreaterOrEqualThan(5.0)) {
            [self addChildViewController:_rootViewController];
        }
        
        [self handleShadows];
        
        if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
            [_rootViewController viewWillAppear:NO];
        }
        [self.view addSubview:_rootViewController.view];
        if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
            [_rootViewController viewDidAppear:NO];
            [_rootViewController didMoveToParentViewController:self];
        }
        
        [_rootViewController addObserver:self
                              forKeyPath:@"view.frame"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
        
        [self addGesturesToCenterController];
        
        if (replace) {
            _rootViewController.view.frame = self.view.bounds;
        }
        
        [self didChangeValueForKey:@"rootViewController"];
    }
}

- (void)setRootViewController:(UIViewController *)controller  {
    [self setRootViewController:controller replaceToOrigin:YES];
}

- (void)addShadow {
    _rootViewController.view.layer.shadowOffset  = CGSizeZero;
    _rootViewController.view.layer.shadowOpacity = 0.75f;
    _rootViewController.view.layer.shadowRadius  = 10.0f;
    _rootViewController.view.layer.shadowColor   = UIColor.blackColor.CGColor;
    _rootViewController.view.layer.shadowPath    = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
    _rootViewController.view.clipsToBounds       = NO;
}

- (void)removeShadow {
    _rootViewController.view.layer.shadowOpacity = 0.0f;
    _rootViewController.view.layer.shadowRadius  = 0.0;
    _rootViewController.view.layer.shadowColor   = nil;
    _rootViewController.view.layer.shadowPath    = nil;
}

- (void)handleShadows {
    if ([self isOptionEnabled:PPRevealSideOptionsShowShadows]) {
        [self addShadow];       
    } else {
        [self removeShadow];
    }
}

- (void)informDelegateWithOptionalSelector:(SEL)selector withParam:(id)param {
    if ([self.delegate respondsToSelector:selector]) {
        // suppression of 'performSelector may cause a leak because its selector is unknown' warning
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.delegate performSelector:selector withObject:self withObject:param];
        #pragma clang diagnostic pop
    }
    
    if (   selector == @selector(pprevealSideViewController:didPushController:)
        || selector == @selector(pprevealSideViewController:didPopToController:)) {
        [self addGesturesToCenterController];
    }
}

- (void)resizeCurrentView {
    PPRevealSideDirection direction = self.sideToClose;
    
    if (([self isOptionEnabled:PPRevealSideOptionsKeepOffsetOnRotation]
            && (direction == PPRevealSideDirectionRight || direction == PPRevealSideDirectionLeft)
         ) || (direction == PPRevealSideDirectionBottom || direction == PPRevealSideDirectionTop)
        ) {
        _rootViewController.view.frame = [self slidingRectForOffset:[self offsetForDirection:direction]
                                                       forDirection:direction];
    }
}


#pragma mark - Gesture recognizer

- (UIViewController *)controllerForGestures {
    UIViewController* controllerForGestures = _rootViewController;
    if ([self.delegate respondsToSelector:@selector(controllerForGesturesOnPPRevealSideViewController:)]) {
        UIViewController *specialController = [self.delegate controllerForGesturesOnPPRevealSideViewController:self];
        if (specialController) controllerForGestures = specialController;
    }
    return controllerForGestures;
}

- (UIViewController *)topControllerFromController:(UIViewController *)controller {
    /*if ([controller isKindOfClass:UINavigationController.class]) {
        return ((UINavigationController*)controller).viewControllers.lastObject;
    } else {
        if (controller.navigationController) {
            return controller.navigationController.viewControllers.lastObject;
        } else {
            return controller;
        }
    }*/
    return controller;
}

- (void)addPanGestureToView:(UIView *)view {
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureRecognizerDidPan:)];
    panGesture.cancelsTouchesInView = YES;
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    [_gestures addObject:panGesture];
    PP_RELEASE(panGesture);
}

- (void)addPanGestureToController:(UIViewController *)controller {
    BOOL isClosed = (self.sideToClose == PPRevealSideDirectionNone) ? YES : NO;
    PPRevealSideInteractions interactions = isClosed ? _panInteractionsWhenClosed : _panInteractionsWhenOpened;
    
    // Nav Bar
    if (interactions & PPRevealSideInteractionNavigationBar && ([controller isKindOfClass:UINavigationController.class]
                                                                || controller.navigationController)) {
        UINavigationController *nav;
        if ([controller isKindOfClass:UINavigationController.class]) {
            nav = (UINavigationController*)controller;
        } else {
            nav = controller.navigationController;
        }
        
        [self addPanGestureToView:nav.navigationBar];
        [self addPanGestureToView:nav.toolbar];
    }
    
    // Content View
    if (interactions & PPRevealSideInteractionContentView) {
        UIViewController *c = [self topControllerFromController:controller];
        [self addPanGestureToView:c.view];
    }
    
    // Customs views
    if ([self.delegate respondsToSelector:@selector(customViewsToAddPanGestureOnPPRevealSideViewController:)]) {
        NSArray *views = [self.delegate customViewsToAddPanGestureOnPPRevealSideViewController:self];
        if (views) {
            for (UIView *vi in views) {
                if ([vi isKindOfClass:[UIView class]]) {
                    [self addPanGestureToView:vi];
                }
            }
        }
    }
}

- (void)addTapGestureToView:(UIView*)view {
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureRecognizerDidTap:)];
    tapGesture.cancelsTouchesInView = YES;
    tapGesture.delegate = self;
    [view addGestureRecognizer:tapGesture];
    [_gestures addObject:tapGesture];
    PP_RELEASE(tapGesture);
}

- (void)addTapGestureToController:(UIViewController *)controller {
    BOOL isClosed = (self.sideToClose == PPRevealSideDirectionNone) ? YES : NO;
    if (isClosed) {
        // no tap gesture required when closed. So remove the old ones
        [self removeAllTapGestures];
        return; 
    }

    // Nav Bar
    if (_tapInteractionsWhenOpened & PPRevealSideInteractionNavigationBar && ([controller isKindOfClass:UINavigationController.class] || controller.navigationController)) {
        UINavigationController *nav;
        if ([controller isKindOfClass:UINavigationController.class]) {
            nav = (UINavigationController*)controller;
        } else {
            nav = controller.navigationController;
        }
        [self addTapGestureToView:nav.navigationBar];
    }
    
    // Content View
    if (_tapInteractionsWhenOpened & PPRevealSideInteractionContentView) {
        UIViewController *c = [self topControllerFromController:controller];
        [self addTapGestureToView:c.view];
    }
    
    // Customs views
    if ([self.delegate respondsToSelector:@selector(customViewsToAddTapGestureOnPPRevealSideViewController:)]) {
        NSArray* views = [self.delegate customViewsToAddTapGestureOnPPRevealSideViewController:self];
        if (views) {
            for (UIView* subView in views) {
                if ([subView isKindOfClass:UIView.class]) {
                    [self addTapGestureToView:subView];
                }
            }
        }
    }
}

- (void)addGesturesToController:(UIViewController*)controller {
    [self removeAllGestures];
    [self addPanGestureToController:controller];
    [self addTapGestureToController:controller];
}

- (void)addGesturesToCenterController {
    [self addGesturesToController:[self controllerForGestures]];
}

- (void)removeAllPanGestures {
    NSArray *array = _gestures.copy;
    for (UIGestureRecognizer* panGest in array) {
        if ([panGest isKindOfClass:UIPanGestureRecognizer.class]) {
            [panGest.view removeGestureRecognizer:panGest];
            [_gestures removeObject:panGest];
        }
    }
}

- (void)removeAllTapGestures {
    NSArray *array = _gestures.copy;
    for (UIGestureRecognizer* tapGest in array) {
        if ([tapGest isKindOfClass:UITapGestureRecognizer.class]) {
            [tapGest.view removeGestureRecognizer:tapGest];
            [_gestures removeObject:tapGest];
        }
    }
}

- (void)removeAllGestures {
    for (UIGestureRecognizer* gest in _gestures) {
        [gest.view removeGestureRecognizer:gest];
    }
    [_gestures removeAllObjects];
}

- (void)updateViewWhichHandleGestures {
    [self addGesturesToCenterController];
}


#pragma mark - Layout calculations

- (CGRect)slidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction andOrientation:(UIInterfaceOrientation)orientation {
    if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) {
        offset = MIN(CGRectGetWidth(PPScreenBounds()), offset);
    }
    if (direction == PPRevealSideDirectionTop || direction == PPRevealSideDirectionBottom) {
        offset = MIN(CGRectGetHeight(self.view.frame), offset);
    }
    
    CGRect rectToReturn = CGRectZero;
    rectToReturn.size = _rootViewController.view.frame.size;
    
    CGFloat width  = CGRectGetWidth(_rootViewController.view.frame);
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

- (CGRect)slidingRectForOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction {
    return [self slidingRectForOffset:offset forDirection:direction andOrientation:PPInterfaceOrientation()];
}

- (CGRect)sideViewFrameFromRootFrame:(CGRect)rootFrame andDirection:(PPRevealSideDirection)direction {
    CGRect slideFrame = CGRectZero;

    CGFloat rootHeight = CGRectGetHeight(rootFrame);
    CGFloat rootWidth  = CGRectGetWidth(rootFrame);
    
    if ([self isOptionEnabled:PPRevealSideOptionsResizeSideView] || self.resizeSides & direction) {
        /*// Resize by taking custom overlapping(, custom offset) or default overlapping in to account
        CGFloat   overlap       = DEFAULT_RESIZE_OVERLAP;
        NSNumber* sideKey       = [NSNumber numberWithInt:direction];
        NSNumber* customOverlap = [self.resizeOverlap objectForKey:sideKey];
        if (customOverlap != nil) {
            overlap = customOverlap.doubleValue;
        } else {
            NSNumber* customOffset = [_viewControllersOffsets objectForKey:sideKey];
            if (customOffset != nil) {
                overlap = customOffset.doubleValue;
            }
        }
        */
        CGFloat overlap = 0;
        
        switch (direction) {
            case PPRevealSideDirectionLeft:
                slideFrame.size.height = rootHeight;
                slideFrame.size.width  = CGRectGetMinX(rootFrame) - overlap;
                break;
            case PPRevealSideDirectionRight:
                slideFrame.origin.x    = CGRectGetMaxX(rootFrame) + overlap;
                slideFrame.size.height = rootHeight;
                slideFrame.size.width  = rootWidth - CGRectGetMaxX(rootFrame) - overlap;
                break; 
            case PPRevealSideDirectionTop:
                slideFrame.size.height = CGRectGetMinY(rootFrame) - overlap;
                slideFrame.size.width  = rootWidth;
                break;
            case PPRevealSideDirectionBottom:
                slideFrame.origin.y    = CGRectGetMaxY(rootFrame) + overlap;
                slideFrame.size.height = rootHeight - CGRectGetMaxY(rootFrame) - overlap;
                slideFrame.size.width  = rootWidth;
                break;
            default:
                break;
        }
    } else {
        // No resizing
        slideFrame.size.width  = rootWidth;
        slideFrame.size.height = rootHeight;
    }
    
    return slideFrame;
}

- (UIEdgeInsets)edgeInsetsForDirection:(PPRevealSideDirection)direction {
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (![self isOptionEnabled:PPRevealSideOptionsResizeSideView]) {
        CGFloat offset = [self offsetForDirection:direction];
        
        switch (direction) {
            case PPRevealSideDirectionLeft:
                inset.right  = offset;
                break;
            case PPRevealSideDirectionRight:
                inset.left   = offset;
                break;
            case PPRevealSideDirectionTop:
                inset.bottom = offset;
                break;
            case PPRevealSideDirectionBottom:
                inset.top    = offset;
                break;
            default:
                break;
        }
    }

    return inset;
}

- (CGFloat)offsetForDirection:(PPRevealSideDirection)direction andInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSNumber* offsetNumber = [_viewControllersOffsets objectForKey:[NSNumber numberWithInt:direction]];
    CGFloat offset = offsetNumber ? offsetNumber.doubleValue : PPRevealSideDefaultOffset;
    
    // TODO This can cause wrong values
    /*if (self.resizeSides & direction) {
        // Resize is active for this direction so we must enlarge the offset
        CGFloat   overlap       = DEFAULT_RESIZE_OVERLAP;
        NSNumber* sideKey       = [NSNumber numberWithInt:direction];
        NSNumber* customOverlap = [self.resizeOverlap objectForKey:sideKey];
        if (customOverlap != nil) {
            overlap = customOverlap.doubleValue;
        }
        offset += overlap;
    }*/
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        if (![self isOptionEnabled:PPRevealSideOptionsKeepOffsetOnRotation]) {
            // Take an orientation free rect
            CGRect portraitBounds = UIScreen.mainScreen.bounds;
            
            // Get the difference between width and height
            CGFloat diff = 0.0;
            if (direction == PPRevealSideDirectionLeft || direction == PPRevealSideDirectionRight) {
                diff = portraitBounds.size.height - portraitBounds.size.width;
            } else if (direction == PPRevealSideDirectionTop) {
                diff = -(portraitBounds.size.height - portraitBounds.size.width);
            }
            
            // Store the offset + the diff
            offset += diff;
        }
    }
    
    return offset;
}

- (CGFloat)offsetForDirection:(PPRevealSideDirection)direction {
    return [self offsetForDirection:direction andInterfaceOrientation:PPInterfaceOrientation()];
}


#pragma mark - Gesture recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    _panOrigin = _rootViewController.view.frame.origin;
    gestureRecognizer.enabled = YES;
    _currentPanDirection = self.sideToClose;
    _wasClosed = _currentPanDirection == PPRevealSideDirectionNone;
    
    BOOL hasExceptionTouch = NO;
    if ([touch.view isKindOfClass:UIControl.class] && [gestureRecognizer isKindOfClass:UITapGestureRecognizer.class]) {
        if (![touch.view isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            hasExceptionTouch = YES;
        }
    }
    
    if (self.panInteractionsWhenClosed & PPRevealSideInteractionNavigationBar) {
        /*
         +------------+   +------------+
         |   status   |   | min region |
         +------------+   |            |
                          |   44x44    |
         +------------+   |            |
         | navigation |   +------------+
         +------------+   | min region |
                          |            |
                          |   44x44    |
                          |            |
                          +------------+
         */
        UIView* navigationBar = self.navigationController.navigationBar;
        const CGFloat offset = MIN(0, PPRevealSideMinTouchableSize - PPRevealSideStatusbarHeight);
        const CGFloat bottom = CGRectGetMaxY(navigationBar.frame) + offset;
        const CGFloat y      = [touch locationInView:navigationBar].y;
        if (y < bottom) {
            return YES;
        }
    }
    
    BOOL hasExceptionDelegate = NO;
    if ([self.delegate respondsToSelector:@selector(pprevealSideViewController:shouldDeactivateGesture:forView:)]) {
        hasExceptionDelegate = [self.delegate pprevealSideViewController:self
                                                 shouldDeactivateGesture:gestureRecognizer
                                                                 forView:touch.view];
    }
    
    if ([self.delegate respondsToSelector:@selector(pprevealSideViewController:directionsAllowedForPanningOnView:)]) {
        PPRSLog(@"touched: %@", touch.view.class);
        
        // "~" means binary negation and ensures that we do what the method name say. 
        _disabledPanGestureDirection = ~[self.delegate pprevealSideViewController:self directionsAllowedForPanningOnView:touch.view];
        
        // Cut all bits over the most significant for our directions enumeration
        _disabledPanGestureDirection &= PPRevealSideDirectionsAll;
    } else {
        _disabledPanGestureDirection = PPRevealSideDirectionNone;
    }
    
    // If all directions are already disabled, we don't need to handle the pan event
    // further to see if user moved in an enabled direction, because there is not any.
    hasExceptionDelegate |= _disabledPanGestureDirection == PPRevealSideDirectionsAll;
    
    return !_animationInProgress && !hasExceptionTouch && !hasExceptionDelegate;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // If there is a scroll view gesture recognised, save it, we may cancel it in the future
    if ([otherGestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
        PP_RELEASE(_scrollViewPanGestureRecognizer);
        _scrollViewPanGestureRecognizer = PP_RETAIN(otherGestureRecognizer);
    }
    return YES;
}

- (void)gestureRecognizerDidPan:(UIPanGestureRecognizer *)panGesture {
    if (_animationInProgress) {
        return;
    }
    
    CGPoint currentPoint = [panGesture translationInView:self.view];
    
    CGFloat x = currentPoint.x + _panOrigin.x;
    CGFloat y = currentPoint.y + _panOrigin.y;
    
    // If the center view controller is closed, then get the direction we want to open
    if (_currentPanDirection == PPRevealSideDirectionNone) {
        CGFloat panDiffX = currentPoint.x - _panOrigin.x;
        CGFloat panDiffY = currentPoint.y - _panOrigin.y;
        
        if (panDiffX > 0 && panDiffX > PPRevealSideTriggerChooseDirection) {
            _currentPanDirection = PPRevealSideDirectionLeft;
        } else if (panDiffX < 0 && panDiffX < PPRevealSideTriggerChooseDirection) {
            _currentPanDirection = PPRevealSideDirectionRight;
        } else if (panDiffY > 0 && panDiffY > PPRevealSideTriggerChooseDirection) {
            _currentPanDirection = PPRevealSideDirectionTop;
        } else if (panDiffY < 0 && panDiffY < PPRevealSideTriggerChooseDirection) {
            _currentPanDirection = PPRevealSideDirectionBottom;
        }
    }
    
    if (_currentPanDirection == PPRevealSideDirectionNone) {
        return;
    }
    
    BOOL disabled = _currentPanDirection & _disabledPanGestureDirection;
    
    // See if there is a controller or not for the direction.
    UIViewController *newVC = [_viewControllers objectForKey:[NSNumber numberWithInt:_currentPanDirection]];
    if (disabled || !newVC) {
        UINavigationController* navController;
        if ([self.rootViewController isKindOfClass:UINavigationController.class]) {
            navController = (UINavigationController *)self.rootViewController;
        } else {
            navController = self.rootViewController.navigationController;
        }
        if (ABS([panGesture translationInView:self.view].x) < 100 && ABS([panGesture velocityInView:self.view].x) < 300) {
            return;
        }
        if (navController && !_usedNavFromPanGesture) {
            UIViewController* topVC = navController.viewControllers.lastObject;
            if (_currentPanDirection == PPRevealSideDirectionLeft
                && !topVC.navigationItem.hidesBackButton
                && navController.viewControllers.count > 1) {
                // We swiped to left and have a navigation controller in the center and have multiple controllers
                // on the stack and backButton is not hidden, so lets pop the top-most one.
                if (x < PPRevealSideNavigationControllerPopTreshold) {
                    // This must be done inside, because we won't cancel the gesture.
                    return;
                }
                
                _usedNavFromPanGesture = YES;
                if (topVC.navigationItem.leftBarButtonItem
                    && topVC.navigationItem.leftBarButtonItem.action
                    && !topVC.navigationItem.leftItemsSupplementBackButton) {
                    PPRSLog(@"****** Special case: use left item! ******");
                    [self executeBarButtonItem:topVC.navigationItem.leftBarButtonItem];
                } else {
                    PPRSLog(@"****** Special case: pop! ******");
                    [navController popViewControllerAnimated:YES];
                }
            } else if (_currentPanDirection == PPRevealSideDirectionRight
                       && topVC.navigationItem.rightBarButtonItem
                       && topVC.navigationItem.rightBarButtonItem.action
                       && !topVC.navigationItem.rightSwipeDisabled) {
                PPRSLog(@"****** Special case: use right item! ******");
                _usedNavFromPanGesture = YES;
                [self executeBarButtonItem:topVC.navigationItem.rightBarButtonItem];
            }
        } else if (!disabled && !_usedNavFromPanGesture) {
            // We use the bounce animation
            PPRSLog(@"****** No controller to push ****** Think to preload controller ! ******");
            [self pushOldViewControllerOnDirection:_currentPanDirection animated:YES];
        }
        
        // Little trick to cancel the gesture. Otherwise, as long as we pan, we continue to pass here ...
        panGesture.enabled = NO;
        panGesture.enabled = YES;
        _usedNavFromPanGesture = NO;
        return;
    }
    
    // Add new view controller to the view hierachy if needed.
    if (!newVC.view.superview) {
        newVC.view.frame = self.rootViewController.view.bounds;
        if (PPSystemVersionGreaterOrEqualThan(5.0)) {
            [self addChildViewController:newVC];
        } else {
            [newVC viewWillAppear:NO];
        }
        
        [self.view insertSubview:newVC.view belowSubview:_rootViewController.view];
        
        if (PPSystemVersionGreaterOrEqualThan(5.0)) {
            [newVC didMoveToParentViewController:self];
        } else {
            [newVC viewDidAppear:NO];
        }
    }
    newVC.view.hidden = NO;
    
    // If the direction is left or right, then cancel the swipe gesture to avoid double scrolling
    if (_currentPanDirection == PPRevealSideDirectionLeft || _currentPanDirection == PPRevealSideDirectionRight) {
        // This is a simple way to cancel a gesture
        _scrollViewPanGestureRecognizer.enabled = NO;
        _scrollViewPanGestureRecognizer.enabled = YES;
        PP_RELEASE(_scrollViewPanGestureRecognizer);
    }
    
    // Get size dimension to compare for triggering events
    CGFloat sizeToCompare;
    if (PPRevealSideDirectionIsHorizontal(_currentPanDirection)) {
        sizeToCompare = self.rootViewController.view.frame.size.width;
    } else {
        sizeToCompare = self.rootViewController.view.frame.size.height;
    }
    
    // Get offset for current direction
    CGFloat offset = sizeToCompare;
    switch (_currentPanDirection) {
        case PPRevealSideDirectionLeft:
            offset -= x;
            break;
        case PPRevealSideDirectionRight:
            offset += x;
            break;
        case PPRevealSideDirectionBottom:
            offset += y;
            break;
        case PPRevealSideDirectionTop:
            offset -= y;
            break;
        default:
            break;
    }
    offset = MAX(offset, [self offsetForDirection:_currentPanDirection]);
    
    // Test if we changed direction
    if (offset >= sizeToCompare - PPRevealSideTriggerChangeDirection) {
        // Change direction if possible
        PPRevealSideDirection newDirection = PPRevealSideDirectionGetOpposite(_currentPanDirection);
        if (newDirection != PPRevealSideDirectionUndefined
              && [_viewControllers objectForKey:[NSNumber numberWithInt:newDirection]]) {
            UIViewController *c = [_viewControllers objectForKey:[NSNumber numberWithInt:_currentPanDirection]];
            
            [self removeControllerFromView:c animated:YES];
            
            _currentPanDirection = newDirection;
            _wasClosed = !_wasClosed;
            return;
        }
    }
    
    self.rootViewController.view.frame = [self slidingRectForOffset:offset
                                                       forDirection:_currentPanDirection];  
    
    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        const CGFloat offsetController = [self offsetForDirection:_currentPanDirection];
        const CGFloat triggerStep      = MIN((sizeToCompare - offsetController) * PPRevealSideTriggerStepFactor, PPRevealSideMaxTriggerOffset);
        
        // Get the offset which is needed to trigger
        CGFloat offsetToTrigger;
        if (_wasClosed)  {
            offsetToTrigger = sizeToCompare - triggerStep;
        } else {
            offsetToTrigger = triggerStep + offsetController;
        }
        
        //PPRSLog(@"offset %f ** sizeToTest %f ** triggerStep %f ** - %f", offset, sizeToTest, triggerStep, offsetTriggered);
        
        // Should close?
        if (offset > offsetToTrigger) {
            _popFromPanGesture = YES;
            [self popViewControllerAnimated:YES];
        } else {
            _shouldNotCloseWhenPushingSameDirection = YES;
            [self pushOldViewControllerOnDirection:_currentPanDirection 
                                        withOffset:[self offsetForDirection:_currentPanDirection andInterfaceOrientation:UIInterfaceOrientationPortrait] // we get the interface orientation for Portrait since we set it just after.
                                          animated:YES];
            _shouldNotCloseWhenPushingSameDirection = NO;
        }
    }
}

- (void)executeBarButtonItem:(UIBarButtonItem *)barItem {
    // Invoke barItems action on its target
    NSMethodSignature* signature = [barItem.target methodSignatureForSelector:barItem.action];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target   = barItem.target;
    invocation.selector = barItem.action;
    if (signature.numberOfArguments >= 3) {
        // Set self as first true argument, which is used as sender argument, if given.
        // The first two arguments are the hidden arguments self and _cmd.
        id this = self;
        [invocation setArgument:&this atIndex:2];
    }
    [invocation invoke];
}

- (void)gestureRecognizerDidTap:(UITapGestureRecognizer*)tapGesture {
    //PPRSLog(@"Yes, the tap gesture is animated, this is normal, not a bug! Is there anybody here with a non animate interface? :P");
    [self popViewControllerAnimated:YES];
}


#pragma mark - Allowed orientations & animations

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    [self resizeCurrentView];
        
    for (NSString* key in _viewControllers.allKeys) {
        UIViewController *controller = (UIViewController *)[_viewControllers objectForKey:key];
        
        if (controller.view.superview) {
            controller.view.frame = [self sideViewFrameFromRootFrame:_rootViewController.view.frame
                                                        andDirection:key.intValue];
            if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
                [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
            }
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self removeShadow];
    //_rootViewController.view.layer.shouldRasterize = YES;
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
        /*for (UIViewController* controller in _viewControllers.allValues) {
            if (controller.view.superview && !PPSystemVersionGreaterOrEqualThan(5.0)) {
                [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
            }
        }*/
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    //_rootViewController.view.layer.shouldRasterize = NO;
    [self handleShadows];
    
    if (!PPSystemVersionGreaterOrEqualThan(5.0)) {
        [_rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        
        for (UIViewController* controller in _viewControllers.allValues) {
            if (controller.view.superview && !PPSystemVersionGreaterOrEqualThan(5.0)) {
                [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
            }
        }
    }
}

// iOS 2+
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [_rootViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

// iOS 6+
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [_rootViewController preferredInterfaceOrientationForPresentation];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return [_rootViewController supportedInterfaceOrientations];
}


#pragma mark - Memory management

- (void)viewWillUnload {
    [super viewWillUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if (!PPSystemVersionGreaterOrEqualThan(6.0)) {
        [self tryToRemoveObserverOnFrame];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    PP_RELEASE(_rootViewController);
    PP_RELEASE(_viewControllers);
    PP_RELEASE(_viewControllersOffsets);
    [self removeAllGestures];
    PP_RELEASE(_gestures);
    
    #if !PP_ARC_ENABLED
        [super dealloc];
    #endif
}

@end



@implementation UIViewController (PPRevealSideViewController)

- (void)setRevealSideViewController:(PPRevealSideViewController *)revealSideViewController {
    [self willChangeValueForKey:@"revealSideViewController"];
    objc_setAssociatedObject(self, @selector(revealSideViewController), revealSideViewController, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"revealSideViewController"];
}

- (PPRevealSideViewController *)revealSideViewController {
    id controller = objc_getAssociatedObject(self, @selector(revealSideViewController));
    
    // Because we can't ask the navigation controller to set to the pushed controller the revealSideViewController!
    if (!controller && self.navigationController) {
        controller = self.navigationController.revealSideViewController;
    }
    if (!controller && self.tabBarController) {
        controller = self.tabBarController.revealSideViewController;
    }
    
    return controller;
}

@end



@implementation UIView (PPRevealSideViewController)

- (void)setRevealSideInset:(UIEdgeInsets)revealSideInset {
    [self willChangeValueForKey:@"revealSideInset"];
    objc_setAssociatedObject(self, @selector(revealSideInset), NSStringFromUIEdgeInsets(revealSideInset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"revealSideInset"];
}

- (UIEdgeInsets)revealSideInset {
    NSString *stringInset = objc_getAssociatedObject(self, @selector(revealSideInset));
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (stringInset) {
        inset = UIEdgeInsetsFromString(stringInset);
    } else {
        inset = self.superview.revealSideInset;
    }
    return inset;
}

@end



@implementation UINavigationItem (PPRevealSideViewController)

- (void)setRightSwipeDisabled:(BOOL)rightSwipeDisabled {
    [self willChangeValueForKey:@"rightSwipeDisabled"];
    objc_setAssociatedObject(self, @selector(rightSwipeDisabled), @(rightSwipeDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"rightSwipeDisabled"];
}

- (BOOL)rightSwipeDisabled {
    return objc_getAssociatedObject(self, @selector(rightSwipeDisabled));
}

@end



#pragma mark - Helper functions

UIInterfaceOrientation PPInterfaceOrientation() {
	return UIApplication.sharedApplication.statusBarOrientation;
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

CGFloat PPStatusBarHeight() {
    if (UIApplication.sharedApplication.isStatusBarHidden) {
        return 0.0;
    }
    if (UIInterfaceOrientationIsLandscape(PPInterfaceOrientation())) {
        return UIApplication.sharedApplication.statusBarFrame.size.width;
    } else {
        return UIApplication.sharedApplication.statusBarFrame.size.height;
    }
}
