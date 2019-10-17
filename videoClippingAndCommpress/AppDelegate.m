//
//  AppDelegate.m
//  videoClippingAndCommpress
//
//  Created by Summer on 2019/10/16.
//  Copyright © 2019 Summer. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
@interface AppDelegate ()
{
     UIWindow * window;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [window  makeKeyAndVisible];
    ViewController * vc = [[ViewController alloc]init];
    window .rootViewController = vc;
    return YES;
}





@end
