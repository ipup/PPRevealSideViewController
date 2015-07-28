PPRevealSideViewController
==========================

This is a new controller container, showing views on the side like the Facebook or Path app. It is as easy to use as a navigation controller.
Sometimes, you need to push a new controller to show some options, but a small controller would be enough … PPRevealSideViewController is THE controller you need.

Pan and Tap gestures are also included !

[See a demo on Youtube!](http://www.youtube.com/watch?v=lsc7RQvyy20)

# Installation
The easiest way to install PPRevealSideViewController is via the [CocoaPods](http://cocoapods.org/) package manager, since it's really flexible and provides easy installation.

## Via CocoaPods

If you don't have cocoapods yet (shame on you), install it:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Go to the directory of your Xcode project, and Create and/or Edit your Podfile and add PPRevealSideViewController:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
# Edit the podfile using your favorite editor
$ edit Podfile
platform :ios 
pod 'PPRevealSideViewController', '~> 1.2.1'
```

Run the install:

``` bash
$ pod install
```

Finally, open your project in Xcode from the .xcworkspace file (not the usual project file! This is really important)

``` bash
$ open MyProject.xcworkspace
```

Import *PPRevealSideViewController.h* file to your PCH file or your AppDelegate file.

You are ready to go.

## Old fashionned way

1. Add PPRevealSideViewController as a submodule to your project

``` bash
$ cd /path/to/MyApplication
# If this is a new project, initialize git...
$ git init
$ git submodule add git://github.com/ipup/PPRevealSideViewController.git vendor/PPRevealSideViewController
$ git submodule update --init --recursive
```

2. In your XCode Project, take the *PPRevealSideViewController.h and .m* from PPRevealSideViewController folder and drag them into your project. 
3. Import *PPRevealSideViewController.h* file to your PCH file or your AppDelegate file.
4. Add the QuartzCore Framework.
5. Start using this new controller!

# ARC Support

PPRevealSideViewController fully supports ARC *and* non-ARC modes out of the box, there is no configuration necessary. This is really convenient when you have older projects, or do no want to use ARC.  ARC support has been tested with the Apple LLVM 3.0 compiler.

# Compatibility

The class if fully compatible from iOS 7. I recently dropped support for previous version. So if needed, please grab a previous commit / version than [this one](https://github.com/ipup/PPRevealSideViewController/commit/6ae0c43278ec251c2d22c897d610d017bbd47dec).

## State preservation and restoration
PPReveal supports state preservation and restoration. All you need is to set a `restorationIdentifier` to all the controllers you want to restore, maybe a `restorationClass` and you're all set

## Status bar style / hidden
The status bar style and hidden are forwarded to the child controllers. If you want to remove this behavior, simply subclasse PPReveal and override both `childViewControllerForStatusBarStyle` and `childViewControllerForStatusBarHidden` to return `nil`.

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

## Open Completely
 You can open completely a side (take the example of Facebook app when you tap on search bar). 
 When you are on an opened side :
    
    [self.revealSideViewController openCompletelyAnimated:YES];
    
 Or when you want to open from the center controller (think to preload the controller)
    
    [self.revealSideViewController openCompletelySide:PPRevealSideDirectionLeft animated:YES];

## Completion API
 Every calls to PPRevealSide methods like pushing or poping can be agremented with completion block like
 
     PopedViewController *c = [[PopedViewController alloc] initWithNibName:@"PopedViewController" bundle:nil ];
	 [self.revealSideViewController pushViewController:c onDirection:PPRevealSideDirectionBottom withOffset:_offset animated:_animated completion:^{
         PPRSLog(@"This is the end!");
     }];

## iOS 7 and status bar

Yeah, this status bar on iOS 7. Well, you now have two options (fading is set as default).
`PPRevealSideOptionsiOS7StatusBarFading` and `PPRevealSideOptionsiOS7StatusBarMoving`

Try them! (using `setOption:`)

Please also note that if you want to change the background color of the status bar when using the fading option, change value of `fakeiOS7StatusBarColor` (default is black).
	 	
    [self.revealSideViewController resetOption:PPRevealSideOptionsiOS7StatusBarFading];
    [self.revealSideViewController setOption:PPRevealSideOptionsiOS7StatusBarMoving];

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

You now have a great method to replace a center controller with an other from center (thanks to [xOr-developer](https://github.com/x0r-developer))

    SecondViewController *c = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
    [self.revealSideViewController replaceCentralViewControllerWithNewController:c animated:YES animationDirection:PPRevealSideDirectionLeft completion:^{
		PPRSLog(@"Poped with new controller");
	}];
	
## Options
You have some options availabled defined in PPRevealSideOptions

* PPRevealSideOptionsShowShadows : Disable or enable the shadows. Enabled by default.
* PPRevealSideOptionsBounceAnimations : Decide if the animations are boucing or not. By default, they are.
* PPRevealSideOptionsCloseCompletlyBeforeOpeningNewDirection : Decide if we close completely the old direction, for the new one or not. Set to YES by default.
* PPRevealSideOptionsKeepOffsetOnRotation : Keep the same offset when rotating. By default, set to no.
* PPRevealSideOptionsResizeSideView : Resize the side view. If set to yes, this disabled the bouncing stuff since the view behind is not large enough to show bouncing correctly. Set to NO by default.

You can find it on
-------

This control is used in these apps we developped at iPuP:

[Les Ardoises](https://itunes.apple.com/fr/app/lesardoises/id535572649?mt=8)
![Preview](http://a1918.phobos.apple.com/us/r1000/092/Purple/v4/20/2b/c9/202bc95a-5e37-4b5a-a64a-fe2a5e9e5cc5/mzl.bonbayen.320x480-75.jpg)

[iAddict V3](https://itunes.apple.com/fr/app/iaddict-v2/id473749663?mt=8)
![Preview](http://cdn.iphoneaddict.fr/wp-content/uploads/2013/02/iAddict-v3.jpg)

[JDGeek](https://itunes.apple.com/fr/app/journal-du-geek-officiel/id541881667?mt=8)
![Preview](http://a845.phobos.apple.com/us/r1000/097/Purple/v4/dd/c3/c6/ddc3c674-6371-2e1b-cf1a-37af9e2b584f/mzl.uonfdwvp.320x480-75.jpg)

[JDGamer](https://itunes.apple.com/fr/app/journal-du-gamer-officiel/id541883168?mt=8)
![Preview](http://a99.phobos.apple.com/us/r1000/096/Purple2/v4/0d/d2/5a/0dd25ac5-ef5a-621f-07ec-8832a207ace2/mzl.jkbdncdn.320x480-75.jpg)

Please feel free to PR the readme for adding your app!

Other contributors
-------

For the methods with completion block [xOr-developer](https://github.com/x0r-developer)
For the iOS 7 moving status bar [cvknage](https://github.com/cvknage)

Big thanks to them!

License
-------

This Code is released under the MIT License by [Marian Paul for iPuP SARL](http://www.ipup.pro)

Please tell me when you use this controller in your project !

Regards,  
Marian Paul aka ipodishima
  
http://www.ipup.pro
