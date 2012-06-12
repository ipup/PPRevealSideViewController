PPRevealSideViewController
==========================

This is a new controller container, showing views on the side like the Facebook or Path app. It is as easy to use as a navigation controller.
Sometimes, you need to push a new controller to show some options, but a small controller would be enough … PPRevealSideViewController is THE controller you need.

Pan and Tap gestures are also included !

[See a demo on Youtube!](http://www.youtube.com/watch?v=lsc7RQvyy20)

# Installation

1. In your XCode Project, take the *PPRevealSideViewController.h and .m* from PPRevealSideViewController folder and drag them into your project. 
2. Import *PPRevealSideViewController.h* file to your PCH file or your AppDelegate file.
3. Add the QuartzCore Framework.
4. Start using this new controller!

# ARC Support

PPRevealSideViewController fully supports ARC *and* non-ARC modes out of the box, there is no configuration necessary. This is really convenient when you have older projects, or do no want to use ARC.  ARC support has been tested with the Apple LLVM 3.0 compiler.

# Compatibility

The class if fully compatible from iOS 4 to iOS 5. Not tested yet on iOS 6 nor older versions like iOS 3, but there is no reasons it doesn't work.
Please note that this class use the new container methods of UIViewController since iOS 5. By using this class on iOS 4 for example, you need to be careful with rotation handling, and presentModalViewController stuff.
Some things you need to be aware on iOS 4 or older :

* the currentOrientation property is not passed to child controllers, so only the window rootViewController knows the currentOrientation. Always use the status bar orientation from UIApplication
* override willAnimateRotationToInterfaceOrientation method to relayout the subviews
* ALWAYS present modal view controller from reveal side view controller, not from the controller itself. Otherwise, you will see strange bug with memory warning and/or rotation (bad layout)
* There is no support on iOS 4 and older of hiding and showing status bar in the app. It's ok if the status bar is initially hidden or not

# Documentation 

The class is documented. You can either browse into documentation/html folder and then open index.html (or found it online : http://ipup.github.com/PPRevealSideViewController or install the doc set into Xcode.

There are two sample codes :

* The first one is very simple, open it in EasySample
* The second one show all the configuration aspects : Open PPRevealSideViewController.xcodeproj

Two ways : 
1. Go to Xcode, preferences, Downloads, + then enter the feed url http://ipup.github.com/PPRevealSideViewController/PPRevealSideViewController.atom

2.Follow these steps

* Quit Xcode
* Go to ~/Library/Developer/Shared/Documentation/DocSets and copy the Documentation/PPRevealSideViewController.docset file.
* Launch Xcode and Voilà !

## Use The BuildDocumentation Scheme
If you want to create the documentation, before running this target, you need to install AppleDoc : 
https://github.com/tomaz/appledoc

# Usage

## Creating your controller
Somewhere, for example in your app delegate, alloc and init the controller :

    _revealSideViewController = [[PPRevealSideViewController alloc] initWithRootViewController:rootController];

Then, add it to the window

	self.window.rootViewController = _revealSideViewController;

or to a view 

	[self.view addSubview:_revealSideViewController.view];
	

You can add a navigation controller on top, for example : 

	MainViewController *main = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:main];
    _revealSideViewController = [[PPRevealSideViewController alloc] initWithRootViewController:nav];
    
    self.window.rootViewController = _revealSideViewController;
    
## Pushing a controller
You have several options to push a controller (see the documentation or the sample)
The easiest way is : 

	PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom animated:YES];

This will push the controller on bottom, with a default offset.
You have four directions : 

	PPRevealSideDirectionBottom
	PPRevealSideDirectionTop
	PPRevealSideDirectionLeft
	PPRevealSideDirectionRight
	
## Popping
To go back to your center controller from a side controller, you can pop :

    [self.revealSideViewController popViewControllerAnimated:YES];

If you want to pop a new center controller, then do the following :

	MainViewController *c = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
    [self.revealSideViewController popViewControllerWithNewCenterController:n animated:YES];

## Note if you don't have controllers for all the sides
 If you want to present only a controller on the left and the right for example, you probably don't want the bouncing animation which shows that there is not yet a controller to present. This animation comes when you do a panning gesture with no preloaded controller, or no controller pushed yet on the triggered side.
 In that case, do the following 
 
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionLeft | PPRevealSideDirectionRight];
 
 You could also don't want these animations at all. Disabled these like it 
 
    [self.revealSideViewController setDirectionsToShowBounce:PPRevealSideDirectionNone];

## Pushing from a side
 If you are for example on the up side, and you want to push a controller on the left, you could call a method on your center controller asking him to display a left controller. But I thought it would be more convenient to provide a way to push an old controller directly. So, using the following will do the trick 

    [self.revealSideViewController pushOldViewControllerOnDirection:PPRevealSideDirectionLeft animated:YES];

 If you are on top, and you want to push a new controller on top (why not), the default behavior of the controller would be to close the top side since it's open. But you can force it to pop push :
 
    [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionTop animated:YES forceToPopPush:YES];

  
## To go deeper 
By default, the side views are not loaded. This means that even if you interface have a button to push a side view, the panning gesture won't show the controller. If you want so, you need to preload the controller you want to present.

	TableViewController *c = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.revealSideViewController preloadViewController:c
                                                 forSide:PPRevealSideDirectionLeft
                                              withOffset:_offset];
                                              
Please not that there can be some interferences with the preload method, when you pop a center controller with a preload controller on the same side that the one you pop from… For that reason, I highly recommand you to delay the preload method. For example : 

	- (void) viewDidAppear:(BOOL)animated {
	    [super viewDidAppear:animated];
	    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preloadLeft) object:nil];
	    [self performSelector:@selector(preloadLeft) withObject:nil afterDelay:0.3];
	}
	
If needed, you also have an unload method. This is useful when you use a tab bar controller as a root of your reveal side view controller. The first item can have a left side, but not the second one !

	- (void) unloadViewControllerForSide:(PPRevealSideDirection)direction;
	
If you have some view whith pan gestures already configured, you have several options. 
Remember that, for the UIWebView for example, the best thing to do is to fit the width on the screen, and disabled zooming. This is typically what you would do on a mobile aware web page.
 
1. Disable the panning gesture on the content view
	
	self.revealSideViewController.panInteractionsWhenClosed = PPRevealSideInteractionNavigationBar;
	self.revealSideViewController.panInteractionsWhenOpened = PPRevealSideInteractionNavigationBar;

2. Implement the delegate method 
	
	- (PPRevealSideDirection)pprevealSideViewController:(PPRevealSideViewController*)controller directionsAllowedForPanningOnView:(UIView*)view {
        
    	if ([view isKindOfClass:NSClassFromString(@"UIWebBrowserView")]) return PPRevealSideDirectionLeft | PPRevealSideDirectionRight;

    	return PPRevealSideDirectionLeft | PPRevealSideDirectionRight | PPRevealSideDirectionTop | PPRevealSideDirectionBottom;
	}

3. In the case you do not have controllers on all sides, you can also disable the bouncing animation which show that there is no controller.

## Options
You have some options availabled defined in PPRevealSideOptions

* PPRevealSideOptionsShowShadows : Disable or enable the shadows. Enabled by default.
* PPRevealSideOptionsBounceAnimations : Decide if the animations are boucing or not. By default, they are.
* PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection : Decide if we close completely the old direction, for the new one or not. Set to YES by default.
* PPRevealSideOptionsKeepOffsetOnRotation : Keep the same offset when rotating. By default, set to no.
* PPRevealSideOptionsResizeSideView : Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default.


                                                
License
-------

This Code is released under the MIT License by [Marian Paul for iPuP SARL](http://www.ipup.pro)

Please tell me when you use this controller in your project !

Regards,  
Marian Paul aka ipodishima
  
http://www.ipup.pro
