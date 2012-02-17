//
//  PPRevealSideViewController.h
//  PPRevealSideViewController
//
//  Created by Marian PAUL on 16/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
# define PPLog(fmt, ...) NSLog((@"%s [Line %d] " fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define PPLog(fmt, ...)
#endif

typedef enum {
    PPRevealSideDirectionLeft = 0,
    PPRevealSideDirectionRight,
    PPRevealSideDirectionTop,
    PPRevealSideDirectionBottom,
    PPRevealSideDirectionNone = -1 // this cannot be used
} PPRevealSideDirection;

enum {
    PPRevealSideInteractionNone = 0,
    PPRevealSideInteractionNavigationBar = 1 << 1,
    PPRevealSideInteractionContentView = 1 << 2,
    
};
typedef NSUInteger PPRevealSideInteraction;

enum {
    PPRevealSideOptionsNone = 0,
    PPRevealSideOptionsShowShadows = 1 << 1, //Disable or enable the shadows. Enabled by default
    PPRevealSideOptionsBounceAnimations = 1 << 2, // Decide if the animations are boucing or not. By default, they are
    PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection = 1 << 3, // Decide if we close completely the old direction, for the new one or not. Set to YES by default
    PPRevealSideOptionsKeepOffsetOnRotation = 1 << 4, // Keep the same offset when rotating. By default, set to no
    PPRevealSideOptionsResizeSideView = 1 << 5, // Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default
};
typedef NSUInteger PPRevealSideOptions;


@protocol PPRevealSideViewControllerDelegate;

@interface PPRevealSideViewController : UIViewController
{
    NSMutableDictionary *_viewControllers;
    NSMutableDictionary *_viewControllersOffsets;
}
/**
 Initialize the reveal controller with a rootViewController. This rootViewController will be in the center
 @param rootViewController the center view controller
 */
- (id) initWithRootViewController:(UIViewController*)rootViewController;


/**
 Getter for the rootViewController
 */
@property (nonatomic, readonly, retain) UIViewController *rootViewController;

/**
The Reveal options. See type def for the default values 
 */
@property (nonatomic, assign) PPRevealSideOptions options;

/**
 The offset bouncing. 
 When opening, if set to -1.0, the the animation will bounce with a default offset
 When closing, if set to -1.0, then the animation open completely before closing. 
 Set to -1.0 by default
 */
@property (nonatomic, assign) CGFloat bouncingOffset;

/**
 Define the interactions to display the side views. By default, only the navigation bar is enabled
 */
@property (nonatomic, assign) PPRevealSideDirection interactions;

@property (nonatomic, assign) id <PPRevealSideViewControllerDelegate> delegate;

/**
 Push controller with a direction and a default offset
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Push the old controller if exists for the direction with a default offset
 */
- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction animated:(BOOL)animated;

/**
 Push controller with a direction and an offset
 */
- (void) pushViewController:(UIViewController*)controller onDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Push the old controller if exists for the direction  an offset
 */
- (void) pushOldViewControllerOnDirection:(PPRevealSideDirection)direction withOffset:(CGFloat)offset animated:(BOOL)animated;

/**
 Pop controller with a new Center controller
 */

- (void) popViewControllerWithNewCenterController:(UIViewController*)centerController animated:(BOOL)animated;

/**
 go back to the center controller
 */
- (void) popViewControllerAnimated:(BOOL)animated;

/**
 Preload a controller (Use only if the animation scratches). Preloading is not good for performances since it uses RAM for nothing.
 Preload long before pushing the controller (ex in the view did load
 */
- (void) preloadViewController:(UIViewController*)controller forSide:(PPRevealSideDirection)direction;

/**
 Set and reset options
 */
- (void) setOption:(PPRevealSideOptions)option;
- (void) resetOption:(PPRevealSideOptions)option;
@end

/**
 UIViewController Category
 */
@interface UIViewController (PPRevealSideViewController)
@property (nonatomic, retain) PPRevealSideViewController *revealSideViewController;
@end

/**
 UIView category
 */
@interface UIView (PPRevealSideViewController)
@property (nonatomic, assign) UIEdgeInsets revealSideInset;
@end

/**
 PPRevealSideViewControllerDelegate protocol
 */
@protocol PPRevealSideViewControllerDelegate <NSObject>
@optional
- (void) pprevealSideViewController:(PPRevealSideViewController*)controller didChangeCenterController:(UIViewController*)newCenterController;
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller willPushController:(UIViewController *)pushedController;
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller didPushController:(UIViewController *)pushedController;
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller willPopToController:(UIViewController *)centerController;
- (void) pprevealSideViewController:(PPRevealSideViewController *)controller didPopToController:(UIViewController *)centerController;
@end

UIInterfaceOrientation PPInterfaceOrientation(void);
CGRect PPScreenBounds(void);