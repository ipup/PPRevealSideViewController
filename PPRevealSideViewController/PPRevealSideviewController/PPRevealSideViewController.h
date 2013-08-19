//
//  PPRevealSideViewController.h
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 Marian PAUL aka ipodishima — iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>


// Define some compatibility macros 
#ifndef __has_feature
    #define __has_feature(x) 0
#endif

#ifndef __has_extension
    #define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
    #define PP_ARC_ENABLED 1
#endif

#define PPSystemVersionGreaterOrEqualThan(version) ([[[UIDevice currentDevice] systemVersion] floatValue] >= version)

#if PP_ARC_ENABLED
    #define PP_RETAIN(xx)           (xx)
    #define PP_RELEASE(xx)          xx = nil
    #define PP_AUTORELEASE(xx)      (xx)
#else
    #define PP_RETAIN(xx)           [xx retain]
    #define PP_RELEASE(xx)          [xx release], xx = nil
    #define PP_AUTORELEASE(xx)      [xx autorelease]
#endif


// Define a conditional logging macro
//#define PPRS_DEBUG 1

#ifndef PPRSLog
    #if PPRS_DEBUG
        #define PPRSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
    #else
        #define PPRSLog(fmt, ...)
    #endif
#endif


/**
 @enum PPRevealSideDirection
 The direction to push !
 */
typedef enum {
    /** These cannot be used as directions. Only for internal use ! */
    PPRevealSideDirectionUndefined  = -1,
    PPRevealSideDirectionNone       =  0,
    /*PPRevealSideDirectionHorizontal = 1 << 1 | 1 << 2,
    PPRevealSideDirectionVertical   = 1 << 3 | 1 << 4,
    PPRevealSideDirectionAll        = 0xF,*/
    
    /** Left direction */
    PPRevealSideDirectionLeft       = 1 << 1,
    
    /** Right direction */
    PPRevealSideDirectionRight      = 1 << 2,
    
    /** Top direction */
    PPRevealSideDirectionTop        = 1 << 3,
    
    /** Bottom direction */
    PPRevealSideDirectionBottom     = 1 << 4,
} PPRevealSideDirection;


/**
 PPRevealSideDirection's combinations
 Do not use them to push/pop/... !
 */
#define PPRevealSideDirectionsHorizontal (PPRevealSideDirectionLeft        | PPRevealSideDirectionRight)
#define PPRevealSideDirectionsVertical   (PPRevealSideDirectionTop         | PPRevealSideDirectionBottom)
#define PPRevealSideDirectionsAll        (PPRevealSideDirectionsHorizontal | PPRevealSideDirectionsVertical)

#define PPRevealSideDirectionIsHorizontal(X) ((X & PPRevealSideDirectionsHorizontal) > 0)
#define PPRevealSideDirectionIsVertical(X)   ((X & PPRevealSideDirectionsVertical)   > 0)

static inline PPRevealSideDirection PPRevealSideDirectionGetOpposite(PPRevealSideDirection direction) {
    switch (direction) {
        case PPRevealSideDirectionLeft:   return PPRevealSideDirectionRight;
        case PPRevealSideDirectionRight:  return PPRevealSideDirectionLeft;
        case PPRevealSideDirectionTop:    return PPRevealSideDirectionBottom;
        case PPRevealSideDirectionBottom: return PPRevealSideDirectionTop;
        default:                          return PPRevealSideDirectionUndefined;
    }
}


/**
 @enum PPRevealSideInteractions 
 The interactions availabled 
 */
typedef enum {
    PPRevealSideInteractionNone          = 0,
    PPRevealSideInteractionNavigationBar = 1 << 1,
    PPRevealSideInteractionContentView   = 1 << 2,
    
} PPRevealSideInteractions;


/**
 @enum PPRevealSideOptions 
 Some options 
 */
typedef enum {
    PPRevealSideOptionsNone = 0,
    PPRevealSideOptionsShowShadows = 1 << 1, /// Disable or enable the shadows. Enabled by default
    PPRevealSideOptionsBounceAnimations = 1 << 2, /// Decide if the animations are boucing or not. By default, they are
    PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection = 1 << 3, /// Decide if we close completely the old direction, for the new one or not. Set to YES by default
    PPRevealSideOptionsKeepOffsetOnRotation = 1 << 4, /// Keep the same offset when rotating. By default, set to no
    PPRevealSideOptionsResizeSideView = 1 << 5, /// Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default
} PPRevealSideOptions;


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
 
 # Pushing from a side
 If you are for example on the up side, and you want to push a controller on the left, you could call a method on your center controller asking him to display a left controller. But I thought it would be more convenient to provide a way to push an old controller directly. So, using the following will do the trick 
 
    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft animated:YES];
 
 If you are on top, and you want to push a new controller on top (why not), the default behavior of the controller would be to close the top side since it's open. But you can force it to pop push :
 
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionTop animated:YES forceToPopPush:YES];
 
 # Note if you don't have controllers for all the sides
 If you want to present only a controller on the left and the right for example, you probably don't want the bouncing animation which shows that there is not yet a controller to present. This animation comes when you do a panning gesture with no preloaded controller, or no controller pushed yet on the triggered side.
 In that case, do the following 
 
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionLeft | PPRevealSideDirectionRight];
 
 You could also don't want these animations at all. Disabled these like it 
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionNone];
 
 */

@interface PPRevealSideViewController : UIViewController <UIGestureRecognizerDelegate> {
    NSMutableDictionary*    _viewControllers;
    NSMutableDictionary*    _viewControllersOffsets;
    
    NSMutableArray*         _gestures;
    
    CGPoint                 _panOrigin;
    PPRevealSideDirection   _currentPanDirection;
    PPRevealSideDirection   _disabledPanGestureDirection;
    CGFloat                 _currentVelocity;
    UIGestureRecognizer*    _scrollViewPanGestureRecognizer;
    
    BOOL                    _animationInProgress;
    BOOL                    _shouldNotCloseWhenPushingSameDirection;
    BOOL                    _wasClosed;
    BOOL                    _popFromPanGesture;
    BOOL                    _usedNavFromPanGesture;
}

/**
 Getter for the rootViewController
 */
@property (nonatomic, readonly, retain) UIViewController *rootViewController;

/**
 The Reveal options. Possible values are :
 
 - PPRevealSideOptionsNone = 0
 - PPRevealSideOptionsShowShadows = 1 << 1
 Disable or enable the shadows. Enabled by default
 - PPRevealSideOptionsBounceAnimations = 1 << 2
 Decide if the animations are boucing or not. By default, they are
 - PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection = 1 << 3
 Decide if we close completely the old direction, for the new one or not. Set to YES by default
 - PPRevealSideOptionsKeepOffsetOnRotation = 1 << 4
 Keep the same offset when rotating. By default, set to no
 - PPRevealSideOptionsResizeSideView = 1 << 5
 Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default
 
 */
@property (nonatomic, assign) PPRevealSideOptions options;

/**
 Does the same as the option PPRevealSideOptionsResizeSideView,
 but only for specific directions.
 */
@property (nonatomic, assign) PPRevealSideDirection resizeSides;

/**
 Specify the size of invisible overlapping region
 */
@property (nonatomic, retain) NSMutableDictionary* resizeOverlap;

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
 Define the side you want them to bounce if there is no controller. By default, all the side are enabled
 */
@property (nonatomic, assign) PPRevealSideDirection directionsToShowBounce;

/**
 The delegate which will receive events from the controller. See PPRevealSideViewControllerDelegate for more informations.
 */
@property (nonatomic, assign) id <PPRevealSideViewControllerDelegate> delegate;

@property (nonatomic, readonly) PPRevealSideDirection sideDirectionOpened;

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
- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Push controller with a direction and a default offset and force to pop then push.
 @param controller The controller to push
 @param direction This parameter allows you to choose the direction to push the controller
 @param animated Animated or not
 @param forcePopPush This parameter is needed when you want to push a new controller in the same direction.
 For example, you could push a new left controller from the left. In this case, setting forcePopPush to YES will pop to center view controller, then push the new controller.
 @see pushViewController:onDirection:withOffset:animated:forceToPopPush:
 */
- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush;

/**
 Push the old controller if exists for the direction with a default offset.
 This allows you for example to go directly on an another side from a controller in a side. 
 @param direction The direction
 @param animated Animated or not
 @see pushOldViewControllerOnDirection:withOffset:animated:
 */
- (void)pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Same as pushViewController:onDirection:animated: but with an offset
 @param controller The controller to push
 @param direction The direction of the push
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 */
- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Same as pushViewController:onDirection:animated:forceToPopPush: but with an offset
 @param controller The controller to push
 @param direction This parameter allows you to choose the direction to push the controller
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 @param forcePopPush This parameter is needed when you want to push a new controller in the same direction.
 For example, you could push a new left controller from the left. In this case, setting forcePopPush to YES will pop to center view controller, then push the new controller.
 */
- (void)pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated forceToPopPush:(BOOL)forcePopPush;

/**
 Same as pushOldViewControllerOnDirection:animated: but with an offset
 @param direction The direction
 @param offset The offset when the side view is pushed
 @param animated Animated or not
 */
- (void)pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Pop controller with a new Center controller.
 @param centerController The new center controller
 @param animated Animated or not
 @see popViewControllerAnimated:
 */

- (void)popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated;

/**
 Go back to the center controller.
 @param animated Animated or not
 @see popViewControllerWithNewCenterController:animated:
 */
- (void)popViewControllerAnimated:(BOOL)animated;


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
 
    - (void)viewDidAppear:(BOOL)animated {
        [super viewDidAppear:animated];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preloadLeft) object:nil];
        [self performSelector:@selector(preloadLeft) withObject:nil afterDelay:0.3];
    }
 
    - (void)preloadLeft {
        TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.revealSideViewController preloadViewController:c
                                                     forSide:PPRevealSideDirectionLeft
                                                  withOffset:_offset];
    }
 
 @param controller The controller to preload
 @param direction The direction for the future controller
 @see preloadViewController:forSide:withOffset:
 */
- (void)preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction;

/**
 Same as preloadViewController:forSide: but with an offset.
 @param controller The controller to preload
 @param direction The direction for the future controller
 @param offset The offset
 @see changeOffset:forDirection:
 */
- (void)preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction withOffset:(CGFloat)offset;

/**
 Remove the controller for a direction. This a convenient method when you use for example a Container view controller like Tab bar controller. When you switch from tabs, you probably want some tabs not to have side controllers. In that case, unload in view will disappear of the tab's controller, then preload on view will appear.
 @param direction The direction for which to unload the controller
 */
- (void)unloadViewControllerForSide:(PPRevealSideDirection)direction;

/**
 Change the offset for a direction. Not animated.
 @param offset The offset
 @param direction The direction for which to change the offset
 @see changeOffset:forDirection:animated:
 */
- (void)changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction;

/**
 Same as - (void)changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction but animated
 @param offset The offset
 @param direction The direction for which to change the offset
 @param animated Animated or not
 */
- (void)changeOffset:(CGFloat)offset forDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Set Option.
 @param option The option to set
 */
- (void)setOption:(PPRevealSideOptions)option;

/**
 Reset Option.
 @param option The option to reset
 */
- (void)resetOption:(PPRevealSideOptions)option;

/**
 Set resize sides
 @param resizeSides     Bit set of sides which should be resized
 */
- (void)setResizeSides:(PPRevealSideDirection)resizeSides;

/**
 Set that a side should be resized
 @param direction       Direction which should be resized
 */
- (void)setResizeSide:(PPRevealSideDirection)direction;

/**
 Reset, which will cause that a side will not be resized
 @param direction       Direction which should not be resized
 */
- (void)resetResizeSide:(PPRevealSideDirection)direction;

/**
 Set resize overlapping.
 @param overlap    The size of the overlapping region
 @param direction  The direction for which to change the overlap
 */
- (void)setResizeOverlap:(CGFloat)overlap forSide:(PPRevealSideDirection)direction;

/**
 Update the view with gestures. Should be called for example when used with controllerForGesturesOnPPRevealSideViewController delegate method when using a container controller as the root. For example with a UITabBarController, call this method when the selected controller has been updated
 */
- (void)updateViewWhichHandleGestures;

/**
 Get the controller for a side. It is useful when you are for example on the left, and you want to update the right controller. You could use a reference to the root controller but it is more convenient like this.
 Please be aware that this getter does asume that you already displayed at least once the controller you are trying to reach, or you preloaded it. It will return nil otherwise !
 @param side The side of the controller you requested
 @return The controller on the side parameter
 */
- (UIViewController*)controllerForSide:(PPRevealSideDirection)side;


- (CGFloat)offsetForDirection:(PPRevealSideDirection)direction andInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (CGFloat)offsetForDirection:(PPRevealSideDirection)direction;

@end

/**
 UIViewController category for the PPRevealSideViewController
 */
@interface UIViewController (PPRevealSideViewController)
/**
 The parent revealSideViewController
 */
@property (nonatomic, assign) IBOutlet PPRevealSideViewController *revealSideViewController;
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
- (void)pprevealSideViewController:(PPRevealSideViewController *)controller didChangeCenterController:(UIViewController*)newCenterController;

/** Called when a controller will be pushed
 @param controller The reveal side view controller
 @param pushedController The controller pushed
 */
- (void)pprevealSideViewController:(PPRevealSideViewController *)controller willPushController:(UIViewController *)pushedController;

/** Called when a controller has been pushed
 @param controller The reveal side view controller
 @param pushedController The controller pushed
 */
- (void)pprevealSideViewController:(PPRevealSideViewController *)controller didPushController:(UIViewController *)pushedController;

/** Called when a controller will be poped
 @param controller The reveal side view controller
 @param centerController The center controller poped
 */
- (void)pprevealSideViewController:(PPRevealSideViewController *)controller willPopToController:(UIViewController *)centerController;

/** Called when a controller has been poped
 @param controller The reveal side view controller
 @param centerController The center controller poped
 */
- (void)pprevealSideViewController:(PPRevealSideViewController *)controller didPopToController:(UIViewController *)centerController;

/** Called when a gesture will start. Typically, if you would use a class like the UISlider (handled by default in the class), you don't want to activate the pan gesture on the slider since it will not be functional.
 @param controller The reveal side view controller
 @param gesture The gesture which triggered the event
 @param view The view
 @return Return YES or NO for the view you want to deactivate gesture. Please return NO by default.
 @see pprevealSideViewController:directionsAllowedForPanningOnView:
 
 */
- (BOOL)pprevealSideViewController:(PPRevealSideViewController *)controller shouldDeactivateGesture:(UIGestureRecognizer *)gesture forView:(UIView *)view;

/**
 Called when a gesture will start
 
 You could need to deactivate gesture for specific direction on a web view for example. If your web view fits the screen on width, then you probably want to deactivate gestures on top and bottom. In this case, you can do
    - (PPRevealSideDirection)pprevealSideViewController:(PPRevealSideViewController*)controller directionsAllowedForPanningOnView:(UIView*)view {
 
        if ([view isKindOfClass:NSClassFromString(@"UIWebBrowserView")]) return PPRevealSideDirectionLeft | PPRevealSideDirectionRight;
 
        return PPRevealSideDirectionLeft | PPRevealSideDirectionRight | PPRevealSideDirectionTop | PPRevealSideDirectionBottom;
    }
 
 @param controller The reveal side view controller
 @param view The view
 @return Return directions allowed for panning
 @see pprevealSideViewController:shouldDeactivateGesture:forView:
 */
- (PPRevealSideDirection)pprevealSideViewController:(PPRevealSideViewController *)controller directionsAllowedForPanningOnView:(UIView *)view;

/**
 Implement this method if you have some custom views in which to add pan gestures, for example a custom navigation bar (not a UINavigationBar)
 
 @param controller The reveal side view controller
 @return an array of views
 */
- (NSArray *)customViewsToAddPanGestureOnPPRevealSideViewController:(PPRevealSideViewController *)controller;

/**
 Implement this method if you have some custom views in which to add Tap gestures, for example a custom navigation bar (not a UINavigationBar)
 
 @param controller The reveal side view controller
 @return an array of views
 */
- (NSArray *)customViewsToAddTapGestureOnPPRevealSideViewController:(PPRevealSideViewController *)controller;

/**
 Implement this method if you have for example a container as the rootViewController (like UITabBarController). If you do not implement this method, the gestures are added to the RootViewController (the center view controller)
 
 @param controller The reveal side view controller
 @return the controller in which we will add gestures
 */
- (UIViewController *)controllerForGesturesOnPPRevealSideViewController:(PPRevealSideViewController *)controller;
@end

/**
 A convenient function which get the current interface orientation based on the status bar.
 */
UIInterfaceOrientation PPInterfaceOrientation(void);
/**
 A convenient function which get the screen bounds. Also handle the size in both landscape and portrait.
 */
CGRect PPScreenBounds(void);

/**
 A convenient function which get the status bar height
 */
CGFloat PPStatusBarHeight(void);
