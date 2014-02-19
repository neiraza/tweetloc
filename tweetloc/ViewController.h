//
//  ViewController.h
//  tweetloc_sample
//
//  Created by togu on 2014/02/13.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocationManager.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

- (IBAction)longPressGesture:(UILongPressGestureRecognizer *)recognizer;
@end
