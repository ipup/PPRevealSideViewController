//
//  PPRevealSideViewController.h
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>

// define some macros 
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define PP_ARC_ENABLED 1
#endif // __has_feature(objc_arc)

#if PP_ARC_ENABLED
#define PP_RETAIN(xx) (xx)
#define PP_RELEASE(xx)  xx = nil
#define PP_AUTORELEASE(xx)  (xx)
#else
#define PP_RETAIN(xx)           [xx retain]
#define PP_RELEASE(xx)          [xx release], xx = nil
#define PP_AUTORELEASE(xx)      [xx autorelease]
#endif

#ifndef PPLog
    #if !DEBUG
    # define PPLog(fmt, ...) NSLog((@"%s [Line %d] " fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
        #else
    #define PPLog(fmt, ...)
    #endif
#endif

/** 
 @enum PPRevealSideDirection
 The direction to push !
 */
typedef enum {
    /** Left direction */
    PPRevealSideDirectionLeft = 0,
    /** Right direction */
    PPRevealSideDirectionRight,
    /** Top direction */
    PPRevealSideDirectionTop,
    /** Bottom direction */
    PPRevealSideDirectionBottom,
    /** This cannot be used as a direction. Only for internal use ! */
    PPRevealSideDirectionNone = -1
} PPRevealSideDirection;

/** @enum PPRevealSideInteractions 
 The interactions availabled 
 */
enum {
    PPRevealSideInteractionNone = 0,
    PPRevealSideInteractionNavigationBar = 1 << 1,
    PPRevealSideInteractionContentView = 1 << 2,
    
};
typedef NSUInteger PPRevealSideInteractions;

/** @enum PPRevealSideOptions 
 Some options 
 */

enum {
    PPRevealSideOptionsNone = 0,
    PPRevealSideOptionsShowShadows = 1 << 1, /// Disable or enable the shadows. Enabled by default
    PPRevealSideOptionsBounceAnimations = 1 << 2, /// Decide if the animations are boucing or not. By default, they are
    PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection = 1 << 3, /// Decide if we close completely the old direction, for the new one or not. Set to YES by default
    PPRevealSideOptionsKeepOffsetOnRotation = 1 << 4, /// Keep the same offset when rotating. By default, set to no
    PPRevealSideOptionsResizeSideView = 1 << 5, /// Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default
};
typedef NSUInteger PPRevealSideOptions;


@protocol PPRevealSideViewControllerDelegate;

/** Allow pushing controllers on side views.
 
 This controller allows you to push views on sides. It is just as easy as a UINavigationController to use. It works on _both iPhone and iPad_, is fully compatible with non ARC and ARC projects.
 
 # Initializing
 
    MainViewController *main = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:main];
    
    _revealSideViewController = [[PPRevealSideViewController alloc] initWithRootViewController:nav];
 
    self.window.rootViewController = _revealSideViewController;
 
 # Pushing a controller
 You have several options to push a controller. The easiest way is : 
 
    PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom animated:YES];
 
 This will push the controller on bottom, with a default offset.
 You have four directions : 
 
    PPRevealSideDirectionBottom
    PPRevealSideDirectionTop
    PPRevealSideDirectionLeft
    PPRevealSideDirectionRight
 
 # Popping
 To go back to your center controller from a side controller, you can pop :
 
    [self.revealSideViewController popViewControllerAnimated:YES];
 
 If you want to pop a new center controller, then do the following :
 
    MainViewController *c = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
    [self.revealSideViewController popViewControllerWithNewCenterController:n animated:YES];
    
 */

@interface PPRevealSideViewController : UIViewController <UIGestureRecognizerDelegate>
{
    NSMutableDictionary     *_viewControllers;
    NSMutableDictionary     *_viewControllersOffsets;
    
    NSMutableArray          *_gestures;
    
    CGPoint                 _panOrigin;
    PPRevealSideDirection   _currentPanDirection;
    CGFloat                 _currentVelocity;
    
    BOOL                    _animationInProgress;
    BOOL                    _shouldNotCloseWhenPushingSameDirection;
    BOOL                    _wasClosed;
}

/**
 Getter for the rootViewController
 
 */
@property (nonatomic, readonly, retain) UIViewController *rootViewController;

/**
 The Reveal options. Possible values are :
 
 * PPRevealSideOptionsNone = 0,
 * PPRevealSideOptionsShowShadows = 1 << 1, /// Disable or enable the shadows. Enabled by default
 * PPRevealSideOptionsBounceAnimations = 1 << 2, /// Decide if the animations are boucing or not. By default, they are
 * PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection = 1 << 3, /// Decide if we close completely the old direction, for the new one or not. Set to YES by default
 * PPRevealSideOptionsKeepOffsetOnRotation = 1 << 4, /// Keep the same offset when rotating. By default, set to no
 * PPRevealSideOptionsResizeSideView = 1 << 5, /// Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default

 */
@property (nonatomic, assign) PPRevealSideOptions options;

/**
 The offset bouncing. 
 When opening, if set to -1.0, then the animation will bounce with a default offset
 When closing, if set to -1.0, then the animation open completely before closing. 
 Set to -1.0 by default
 */
@property (nonatomic, assign) CGFloat bouncingOffset;

/**
 For panning gestures
 Define the interactions to display the side views when closed. By default, only the navigation bar is enabled
 Possible values are :
 
 - PPRevealSideInteractionNone = 0
 - PPRevealSideInteractionNavigationBar = 1 << 1
 - PPRevealSideInteractionContentView = 1 << 2
 
 @see panInteractionsWhenOpened
 @see tapInteractionsWhenOpened
 */
@property (nonatomic, assign) PPRevealSideInteractions panInteractionsWhenClosed;

/**
 For panning gestures
 Define the interactions to close the side view when opened. By default, all the view is enabled
 @see panInteractionsWhenClosed
 @see tapInteractionsWhenOpened
 */
@property (nonatomic, assign) PPRevealSideInteractions panInteractionsWhenOpened;

/**
 For tapping gestures
 Define the interactions to close the side view when opened. By default, all the view is enabled
 @see panInteractionsWhenClosed
 @see panInteractionsWhenOpened
 */
@property (nonatomic, assign) PPRevealSideInteractions tapInteractionsWhenOpened;

/**
 The delegate which will receive events from the controller. See PPRevealSideViewControllerDelegate for more informations.
 */
@property (nonatomic, assign) id <PPRevealSideViewControllerDelegate> delegate;

/**---------------------------------------------------------------------------------------
 * @name Init method
 *  ---------------------------------------------------------------------------------------
 */

/**
 Initialize the reveal controller with a rootViewController. This rootViewController will be in the center.
 @param rootViewController The center view controller.
 @return the controller initialized
 */

- (id) initWithRootViewController:(UIViewController*)rootViewController;


/**---------------------------------------------------------------------------------------
 * @name Pushing and popping methods
 *  ---------------------------------------------------------------------------------------
 */

/**
 Push controller with a direction and a default offset.
 @param controller The controller to push
 @param direction This parameter allows you to choose the direction to push the controller
 @param animated Animated or not
 @see pushViewController:onDirection:withOffset:animated:
 @see pushOldViewControllerOnDirection:animated:
 @see pushViewController:onDirection:animated:forceToPopPush:
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Push controller with a direction and a default offset and force to pop then push.
 @param controller The controller to push
 @param direction This parameter allows you to choose the direction to push the controller
 @param animated Animated or not
 @param forcePopPush This parameter is needed when you want to push a new controller in the same direction.
 For example, you could push a new left controller from the left. In this case, setting forcePopPush to YES will pop to center view controller, then push the new controller.
 @see pushViewController:onDirection:withOffset:animated:forceToPopPush:
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush;

/**
 Push the old controller if exists for the direction with a default offset.
 This allows you for example to go directly on an another side from a controller in a side. 
 @param direction The direction
 @param animated Animated or not
 @see pushOldViewControllerOnDirection:withOffset:animated:
 */
- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Same as pushViewController:onDirection:animated: but with an offset
 @param controller The controller to push
 @param direction The direction of the push
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Same as pushViewController:onDirection:animated:forceToPopPush: but with an offset
 @param controller The controller to push
 @param direction This parameter allows you to choose the direction to push the controller
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 @param forcePopPush This parameter is needed when you want to push a new controller in the same direction.
 For example, you could push a new left controller from the left. In this case, setting forcePopPush to YES will pop to center view controller, then push the new controller.
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush;

/**
 Same as pushOldViewControllerOnDirection:animated: but with an offset
 @param direction The direction
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 */
- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Pop controller with a new Center controller.
 @param centerController The new center controller
 @param animated Animated or not
 @see popViewControllerAnimated:
 */

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated;

/**
 Go back to the center controller.
 @param animated Animated or not
 @see popViewControllerWithNewCenterController:animated:
 */
- (void) popViewControllerAnimated:(BOOL)animated;


/**---------------------------------------------------------------------------------------
 * @name More functionalities
 *  ---------------------------------------------------------------------------------------
 */

/**
 Preload a controller.
 Use only if the animation scratches OR if you want to have gestures on the center view controller without pushing first.
 Preloading is not good for performances since it uses RAM for nothing.
 Preload long before pushing the controller (ex : in the view did load)
 Offset set to Default Offset
 
 For example, you will use as it, with a performSelector:afterDelay: (because of some interferences with the push/pop methods)
 
    - (void) viewDidAppear:(BOOL)animated {
        [super viewDidAppear:animated];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preloadLeft) object:nil];
        [self performSelector:@selector(preloadLeft) withObject:nil afterDelay:0.3];
    }
 
    - (void) preloadLeft {
        TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.revealSideViewController preloadViewController:c
                                                    forSide:PPRevealSideDirectionLeft
                                                withOffset:_offset];
    }
 
 @param controller The controller to preload
 @param direction The direction for the future controller
 @see preloadViewController:forSide:withOffset:
 */
- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction;

/**
 Same as preloadViewController:forSide: but with an offset.
 @param controller The controller to preload
 @param direction The direction for the future controller
 @param offset The offset
 @see changeOffset:forDirection:
 */
- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset;

/**
 Change the offset for a direction. Not animated.
 @param offset The offset
 @param direction The direction for which to change the offset
 @see changeOffset:forDirection:animated:
 */
- (void) changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;

/**
 Same as - (void) changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction but animated
 @param offset The offset
 @param direction The direction for which to change the offset
 @param animated Animated or not
 */
- (void) changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Set Option.
 @param option The option to set
 */
- (void) setOption:(PPRevealSideOptions)option;

/**
 Reset Option.
 @param option The option to reset
 */
- (void) resetOption:(PPRevealSideOptions)option;

@end

/**
 UIViewController category for the PPRevealSideViewController
 */
@interface UIViewController (PPRevealSideViewController)
/**
 The parent revealSideViewController
 */
@property (nonatomic, retain) PPRevealSideViewController *revealSideViewController;
@end

/**
 UIView category to add a content inset when you push a view with an offset
 */
@interface UIView (PPRevealSideViewController)
/**
 Content inset when you push a view with an offset
 */
@property (nonatomic, assign) UIEdgeInsets revealSideInset;
@end

/**
 PPRevealSideViewControllerDelegate protocol
 */
@protocol PPRevealSideViewControllerDelegate <NSObject>
@optional

/** Called when the center controller has changed 
 @param controller The reveal side view controller
 @param newCenterController The new center controller
 */
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller didChangeCenterController:(UIViewController*)newCenterController;

/** Called when a controller will be pushed
 @param controller The reveal side view controller
 @param pushedController The controller pushed
 */
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller willPushController:(UIViewController *)pushedController;

/** Called when a controller has been pushed
 @param controller The reveal side view controller
 @param pushedController The controller pushed
 */
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller didPushController:(UIViewController *)pushedController;

/** Called when a controller will be poped
 @param controller The reveal side view controller
 @param centerController The center controller poped
 */
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller willPopToController:(UIViewController *)centerController;

/** Called when a controller has been poped
 @param controller The reveal side view controller
 @param centerController The center controller poped
 */
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller didPopToController:(UIViewController *)centerController;

/** Called when a gesture will start. Typically, if you would use a class like the UISlider (handled by default in the class), you don't want to activate the pan gesture on the slider since it will not be functional.
 
 @param controller The reveal side view controller
 @param view The view
 @return Return YES or NO for the view you want to deactivate gesture. Please return NO by default.
 */
- (BOOL) pprevealSideViewController:(PPRevealSideViewController *)controller shouldDeactivateGestureForView:(UIView*)view;
@end

/**
 A convenient function which get the current interface orientation based on the status bar.
 */
UIInterfaceOrientation PPInterfaceOrientation(void);
/**
 A convenient function which get the screen bounds. Also handle the size in both landscape and portrait.
 */
CGRect PPScreenBounds(void);