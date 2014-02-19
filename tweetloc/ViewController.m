//
//  ViewController.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/13.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "ViewController.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "TestAnnotation.h"
#import "TwitterAPIClient.h"

#import "NSUserDefaultsUtil.h"
#import "MKMapView+ZoomLevel.h"
#import "NSDateComponents+WeekDayString.h"
#import "NSString+ToString.h"

#define searchTimeInterval 1.0

@interface ViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation ViewController

@synthesize mapView, locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self startUpdateLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startUpdateLocation
{
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
    }
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

//現在地取得
- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
    
    //TODO 最初に止めてみるか
    [manager stopUpdatingLocation];
    
    CLLocation *currentLocation = [locations lastObject];
    
    NSString *lat = [NSString toString:currentLocation.coordinate.latitude];
    NSString *lon = [NSString toString:currentLocation.coordinate.longitude];
    NSDictionary *currentData = @{@"coordinate":@{@"latitude":lat, @"longitude":lon},
                                  @"createdAt": [self getStrDateNow], @"createdAtDate": [NSDate date]};
    
    NSLog(@"currentData %@", currentData);
    
    if (![self isUpdatedLocationData:currentData]) {
        NSLog(@"位置がさっきと一緒やん?");
        return;
    }
    
    //ロケーション情報をローカルに保存
    setLocationData(currentData);
    
    [mapView setCenterCoordinate:currentLocation.coordinate zoomLevel:14 animated:YES];
    
    //マップをきれいにしよか
    [mapView removeAnnotations:mapView.annotations];
    
    //TODO TwitterAPI
    NSDictionary *twitterAPIParams = @{@"geocodeParam" : [[TwitterAPIClient sharedManager] getGeocodeParam:@{@"lat" : lat, @"lon" : lon}]};
    [[TwitterAPIClient sharedManager] fetchNearbyTweets:twitterAPIParams
                                               callback:^(NSArray *results, NSError *error) {
                                                   if (error) {
                                                       NSLog(@"エラーかよ %@", error);
                                                       return;
                                                   }
                                                   
                                                   NSArray *statuses = [results valueForKeyPath:@"statuses"];
                                                   NSLog(@"search count %ld", statuses.count);
                                                   
                                                   //TODO 位置情報から位置付きのtweet get
                                                   if (statuses.count > 0) {
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           for (NSDictionary *dic in statuses) {
                                                               NSLog(@"name : %@", [dic valueForKeyPath:@"user.name"]);
                                                               NSLog(@"text : %@", [dic objectForKey:@"text"]);
                                                               
                                                               NSArray *coordinates = [dic valueForKeyPath:@"coordinates.coordinates"];
                                                               
                                                               NSLog(@"coordinates : %@", coordinates);
                                                               if (coordinates && ![coordinates isEqual:[NSNull null]] && [coordinates count] == 2) {
                                                                   NSString *lat = [coordinates objectAtIndex:1];
                                                                   NSString *lon = [coordinates objectAtIndex:0];
                                                                   NSLog(@"coordinates(%@, %@)", lat, lon);
                                                                   
                                                                   if (lat && lon) {
                                                                       TestAnnotation *annotation = [[TestAnnotation alloc] initWithCoordinate:[self getCoordinate:@{@"lat":[coordinates objectAtIndex:1], @"lon":[coordinates objectAtIndex:0]}]];
                                                                       annotation.title = [dic valueForKey:@"text"];
                                                                       annotation.subtitle = [dic valueForKeyPath:@"user.name"];
                                                                       [mapView addAnnotation:annotation];
                                                                   }
                                                               }
                                                           }
                                                       });
                                                   }
                                               }];
}

#pragma mark -

// 位置情報取得のコールバックが連続で戻ってくる事があるので、同じ場所、同じ時間に連続した取得処理防止
- (BOOL)isUpdatedLocationData:(NSDictionary *)dst
{
    NSDictionary *src = getLocationData();

    NSLog(@"src %@", src);
    NSLog(@"dst %@", dst);
    
    //基準となるデータが存在しない場合は保持しとかなきゃ
    if (!src) {
        NSLog(@"saveしません");
        return YES;
    }
    
    NSString *srcLat = [src valueForKeyPath:@"coordinate.latitude"];
    NSString *dstLat = [dst valueForKeyPath:@"coordinate.latitude"];
    NSString *srcLon = [src valueForKeyPath:@"coordinate.longitude"];
    NSString *dstLon = [dst valueForKeyPath:@"coordinate.longitude"];
    
    NSLog(@"src lat %@", srcLat);
    NSLog(@"dst lat %@", srcLon);
    NSLog(@"src lat %@", dstLat);
    NSLog(@"dst lat %@", dstLon);
    
    if (!srcLat || !srcLon) {
        NSLog(@"saveします");
        return YES;
    }
    
    if (!dstLat || !dstLon) {
        NSLog(@"saveしない");
        return NO;
    }
    
    //場所を移動していれば再取得対象
    if ([[src valueForKeyPath:@"coordinate.latitude"] isEqualToString:[dst valueForKeyPath:@"coordinate.latitude"]] &&
        [[src valueForKeyPath:@"coordinate.longitude"] isEqualToString:[dst valueForKeyPath:@"coordinate.longitude"]]) {
        
        NSDate *lastDate = [src objectForKey:@"createdAtDate"];
        NSLog(@"lastDate %@", lastDate);
        if (!lastDate) {
            NSLog(@"saveします");
            return YES;
        }
        
        NSDate *latestDate = [dst objectForKey:@"createdAtDate"];
        NSLog(@"latestDate %@", latestDate);
        if (!latestDate) {
            NSLog(@"saveしません");
            return NO;
        }
        
        // 直近とその１つ前に取得した時間がn秒間以上空いている場合のみ有効としよう
        if ([latestDate timeIntervalSinceDate:lastDate] >= searchTimeInterval) {
            NSLog(@"saveします");
            return YES;
        } else {
            NSLog(@"saveしません");
            return NO;
        }
        
    } else {
        NSLog(@"saveします");
        return YES;
    }
}

#pragma mark -

- (NSString *)getStrDateNow
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *cmp = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit
                                        fromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%4ld/%2ld/%2ld(%@)", [cmp year], [cmp month], [cmp day], [cmp weekdayString]];
}
                                                               
#pragma mark -
                                                               
- (CLLocationCoordinate2D)getCoordinate:(NSDictionary *)params
{
   return CLLocationCoordinate2DMake([[params objectForKey:@"lat"] floatValue], [[params objectForKey:@"lon"] floatValue]);
}

#pragma mark - 

- (IBAction)longPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    NSLog(@"longPress...");
    [[TwitterAPIClient sharedManager] tweet:self];
}
@end
