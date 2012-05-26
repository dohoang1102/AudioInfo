//
//  AppDelegate.h
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate > {
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainViewController *viewController;


@end
