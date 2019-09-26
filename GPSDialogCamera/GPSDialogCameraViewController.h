//
//  GPSDialogCameraViewController.h
//  GPSDialogCamera
//
//  Created by 涼平 西村 on 11/08/30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GPSDialogCameraViewController : UIViewController<UIApplicationDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, UIAccelerometerDelegate, UIImagePickerControllerDelegate>
{
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UIImageView *imageView;

    CLLocationManager *locationManager;
    UIImagePickerController *imagePickerController;
    CLLocation *location;
    CLLocation *takenLocation;
    CLHeading *heading;
    CLHeading *takenHeading;
    UIImage *originalImage;
}

- (void)clearVariables;
- (void)resetImagePicker;

@end
