//
//  MKMapView+ZoomLevel.h
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

- (MKCoordinateRegion)coordinateRegionWithMapView:(MKMapView *)mapView
                                 centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                     andZoomLevel:(NSUInteger)zoomLevel;
- (NSUInteger)zoomLevel;
@end
