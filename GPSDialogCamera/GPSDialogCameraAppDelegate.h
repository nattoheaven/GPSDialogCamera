//
//  GPSDialogCameraAppDelegate.h
//  GPSDialogCamera
//
//  Created by 涼平 西村 on 11/08/30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPSDialogCameraViewController;

@interface GPSDialogCameraAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet GPSDialogCameraViewController *viewController;

@end
