//
//  GPSDialogCameraViewController.m
//  GPSDialogCamera
//
//  Created by 涼平 西村 on 11/08/30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <AssetsLibrary/ALAssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>

#import "GPSDialogCameraViewController.h"

static void
showGPSError()
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Error", nil)
                              message:NSLocalizedString(@"GPS is not Available.", nil)
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

@implementation GPSDialogCameraViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [activityIndicator stopAnimating];
    locationManager = nil;
    imagePickerController = nil;
    location = nil;
    heading = nil;
    if (![CLLocationManager locationServicesEnabled] && ![CLLocationManager headingAvailable]) {
        showGPSError();
        return;
    }
    [imageView setCenter:CGPointMake([[self view] bounds].size.width * 0.5f,
                                     [[self view] bounds].size.height * 0.5f)];
    [activityIndicator startAnimating];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([CLLocationManager locationServicesEnabled]) {
        [locationManager startUpdatingLocation];
    }
    if ([CLLocationManager headingAvailable]) {
        [locationManager startUpdatingHeading];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self clearVariables];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLLocation *releaseLocation = location;
    location = [newLocation retain];
    if (releaseLocation) {
        [releaseLocation release];
    }
    if ((![CLLocationManager headingAvailable] || heading) && !imagePickerController) {
        [self resetImagePicker];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    CLHeading *releaseHeading = heading;
    heading = [newHeading retain];
    if (releaseHeading) {
        [releaseHeading release];
    }
    if ((![CLLocationManager locationServicesEnabled] || location) && !imagePickerController) {
        [self resetImagePicker];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied) {
        showGPSError();
        [self clearVariables];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissModalViewControllerAnimated:NO];
    [activityIndicator startAnimating];
    if (location) {
        takenLocation = [location retain];
    }
    if (heading) {
        takenHeading = [heading retain];
    }
    originalImage = [[info objectForKey:UIImagePickerControllerOriginalImage] retain];
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            [imageView setTransform:CGAffineTransformMakeRotation(0.0f)];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [imageView setTransform:CGAffineTransformMakeRotation((float) (-1.0 * M_PI / 2.0))];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [imageView setTransform:CGAffineTransformMakeRotation((float) (-2.0 * M_PI / 2.0))];
            break;
        case UIDeviceOrientationLandscapeRight:
            [imageView setTransform:CGAffineTransformMakeRotation((float) (-3.0 * M_PI / 2.0))];
            break;
        default:
            break;
    }
    UIScreen *screen = [UIScreen mainScreen];
    CGRect imageRect;
    if ([screen bounds].size.width * originalImage.size.height <=
        originalImage.size.width * [screen bounds].size.height) {
        imageRect.size =
        CGSizeMake([screen bounds].size.width,
                   [screen bounds].size.width * originalImage.size.height / originalImage.size.width);
    } else {
        imageRect.size =
        CGSizeMake([screen bounds].size.height * originalImage.size.width / originalImage.size.height,
                   [screen bounds].size.height);
    }
    imageRect.origin = CGPointMake(([screen bounds].size.width - imageRect.size.width) * 0.5f,
                                   ([screen bounds].size.height - imageRect.size.height) * 0.5f);
    [imageView setBounds:imageRect];
    [imageView setImage:originalImage];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"GPS", nil)
                              message:NSLocalizedString(@"Do you Embed GPS Data?", nil)
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Yes", nil)
                              otherButtonTitles:NSLocalizedString(@"No", nil), nil];
    [alertView show];
    [alertView release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self resetImagePicker];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    const NSString *halfValue= @"0.5";
    NSString *pictureQualityKey = @"picture_quality";
    const NSString *yesValue = @"YES";
    NSString *latitudeKey = @"latitude";
    NSString *longitudeKey = @"longitude";
    NSString *altitudeKey = @"altitude";
    NSString *courseKey = @"course";
    NSString *speedKey = @"speed";
    NSString *timestampKey = @"timestamp";
    NSString *datestampKey = @"datestamp";
    NSString *exifdatetimeKey = @"exifdatetime";
    NSString *headingKey = @"heading";
    NSDictionary *registeredDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        halfValue, pictureQualityKey,
                                        yesValue, latitudeKey,
                                        yesValue, longitudeKey,
                                        yesValue, altitudeKey,
                                        yesValue, courseKey,
                                        yesValue, speedKey,
                                        yesValue, timestampKey,
                                        yesValue, datestampKey,
                                        yesValue, exifdatetimeKey,
                                        yesValue, headingKey,
                                        nil];
    [userDefaults registerDefaults:registeredDefaults];
    float pictureQualityFloat = fminf(fmaxf([userDefaults floatForKey:pictureQualityKey] / 8.0f, 0.0f), 1.0f);
    NSData *data = UIImageJPEGRepresentation(originalImage, pictureQualityFloat);
    NSMutableDictionary *metadata = nil;
    if (buttonIndex == 0) {
        NSMutableDictionary *exif = nil;
        NSMutableDictionary *gps = nil;
        NSLocale *posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        if (takenLocation) {
            if ([userDefaults boolForKey:latitudeKey]) {
                NSString *latituderef;
                CLLocationDegrees latitudedegree;
                if (takenLocation.coordinate.latitude < (CLLocationDegrees) 0.0) {
                    latituderef = @"S";
                    latitudedegree = -takenLocation.coordinate.latitude;
                } else {
                    latituderef = @"N";
                    latitudedegree = takenLocation.coordinate.latitude;
                }
                NSNumber *latitude = [NSNumber numberWithDouble:latitudedegree];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:latituderef forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
                [gps setObject:latitude forKey:(NSString *)kCGImagePropertyGPSLatitude];
            }
            if ([userDefaults boolForKey:longitudeKey]) {
                NSString *longituderef;
                CLLocationDegrees longitudedegree;
                if (takenLocation.coordinate.longitude < (CLLocationDegrees) 0.0) {
                    longituderef = @"W";
                    longitudedegree = -takenLocation.coordinate.longitude;
                } else {
                    longituderef = @"E";
                    longitudedegree = takenLocation.coordinate.longitude;
                }
                NSNumber *longitude = [NSNumber numberWithDouble:longitudedegree];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:longituderef forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
                [gps setObject:longitude forKey:(NSString *)kCGImagePropertyGPSLongitude];
            }
            if ([userDefaults boolForKey:altitudeKey]) {
                NSString *altituderef;
                CLLocationDistance altitudedegree;
                if (takenLocation.altitude < (CLLocationDistance) 0.0) {
                    altituderef = @"1";
                    altitudedegree = -takenLocation.altitude;
                } else {
                    altituderef = @"0";
                    altitudedegree = takenLocation.altitude;
                }
                NSNumber *altitude = [NSNumber numberWithDouble:altitudedegree];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:altituderef forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
                [gps setObject:altitude forKey:(NSString *)kCGImagePropertyGPSAltitude];
            }
            if ([userDefaults boolForKey:courseKey]) {
                NSNumber *course = [NSNumber numberWithDouble:fmax(takenLocation.course, (CLLocationDirection) 0.0)];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
                [gps setObject:course forKey:(NSString *)kCGImagePropertyGPSTrack];
            }
            if ([userDefaults boolForKey:speedKey]) {
                NSNumber *speed = [NSNumber numberWithDouble:fmax(takenLocation.speed, (CLLocationSpeed) 0.0) * (CLLocationSpeed) 3.6];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
                [gps setObject:speed forKey:(NSString *)kCGImagePropertyGPSSpeed];
            }
            if ([userDefaults boolForKey:timestampKey]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setLocale:posixLocale];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
                NSString *timestamp = [formatter stringFromDate:takenLocation.timestamp];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:timestamp forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
                [formatter release];
            }
            if ([userDefaults boolForKey:datestampKey]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setLocale:posixLocale];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [formatter setDateFormat:@"yyyy:MM:dd"];
                NSString *datestamp = [formatter stringFromDate:takenLocation.timestamp];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:datestamp forKey:(NSString *)kCGImagePropertyGPSDateStamp];
                [formatter release];
            }
            if ([userDefaults boolForKey:exifdatetimeKey]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setLocale:posixLocale];
                [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
                NSString* datetime = [formatter stringFromDate:takenLocation.timestamp];
                if (exif == nil) {
                    exif = [[NSMutableDictionary alloc] init];
                }
                [exif setObject:datetime forKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
                [exif setObject:datetime forKey:(NSString *)kCGImagePropertyExifDateTimeDigitized];
                [formatter release];
            }
            [posixLocale release];
        }
        if (takenHeading) {
            if ([userDefaults boolForKey:headingKey]) {
                NSNumber *trueHeading = [NSNumber numberWithDouble:fmax(takenHeading.trueHeading, (CLLocationDirection) 0.0)];
                if (gps == nil) {
                    gps = [[NSMutableDictionary alloc] init];
                }
                [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSImgDirectionRef];
                [gps setObject:trueHeading forKey:(NSString *)kCGImagePropertyGPSImgDirection];
            }
        }
        if (gps != nil || exif != nil) {
            metadata = [[NSMutableDictionary alloc] init];
        }
        if (gps != nil) {
            [metadata setObject:gps forKey:(NSString *)kCGImagePropertyGPSDictionary];
            [gps release];
        }
        if (exif != nil) {
            [metadata setObject:exif forKey:(NSString *)kCGImagePropertyExifDictionary];
            [exif release];
        }
    }
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary
     writeImageDataToSavedPhotosAlbum:data
     metadata:metadata
     completionBlock:^(NSURL *assetURL, NSError *error) {
         [self resetImagePicker];
     }];
    if (metadata) {
        [metadata release];
    }
    [registeredDefaults release];
    if (takenLocation) {
        [takenLocation release];
    }
    if (takenHeading) {
        [takenHeading release];
    }
    [originalImage release];
}

- (void)clearVariables
{
    if (imagePickerController) {
        [imagePickerController dismissModalViewControllerAnimated:NO];
        [imagePickerController release];
        imagePickerController = nil;
    }
    if (locationManager) {
        [locationManager stopUpdatingLocation];
        [locationManager stopUpdatingHeading];
        [locationManager release];
        locationManager = nil;
    }
    if (location) {
        [location release];
        location = nil;
    }
    if (heading) {
        [heading release];
        heading = nil;
    }
}

- (void)resetImagePicker
{
    if (imagePickerController) {
        [imagePickerController dismissModalViewControllerAnimated:NO];
        [imagePickerController release];
        imagePickerController = nil;
    }
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Error", nil)
                                  message:NSLocalizedString(@"Camera is not Available.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.allowsEditing = NO;
    [activityIndicator stopAnimating];
    [self presentModalViewController:imagePickerController animated:NO];
}

@end
