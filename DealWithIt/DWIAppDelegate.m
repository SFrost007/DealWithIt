//
//  DWIAppDelegate.m
//  DealWithIt
//
//  Created by Simon Frost on 03/04/2013.
//  Copyright (c) 2013 Orangeninja. All rights reserved.
//

#import "DWIAppDelegate.h"
#import "DWIMainViewController.h"

@implementation DWIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    DWIMainViewController *vc = [[DWIMainViewController alloc] init];
    self.window.rootViewController = vc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
