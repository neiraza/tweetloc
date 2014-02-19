//
//  TimeLineViewController.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/13.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "TimeLineViewController.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "NSUserDefaultsUtil.h"
#import "TwitterAPIClient.h"
#import "NSDateComponents+WeekDayString.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

#define tweets_loc_radius @"1km"
#define searchTimeInterval 1.0

@interface TimeLineViewController ()
//@property (nonatomic) ACAccountStore *accountStore;
@property (nonatomic) NSMutableArray *results;
@property (nonatomic) NSString *lastLat;
@property (nonatomic) NSString *lastLon;
@end

@implementation TimeLineViewController

//@synthesize accountStore;
@synthesize lastLat, lastLon;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.results = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSDictionary *locData = getLocationData();
    if (locData) {
        lastLat = [locData valueForKeyPath:@"coordinate.latitude"];
        lastLon = [locData valueForKeyPath:@"coordinate.longitude"];
        NSDictionary *currentData = @{@"coordinate":@{@"latitude":lastLat, @"longitude":lastLon},
                                      @"createdAt": [self getStrDateNow], @"createdAtDate": [NSDate date]};
        
        NSLog(@"currentData %@", currentData);
        
        if ([self isUpdatedLocationData:currentData]) {
            [self fetchNearbyTweets];
        } else {
            NSLog(@"位置がかわってねええええええええ？");
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if (self.results && self.results.count > 0) {
        NSDictionary *place = [self.results objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [place valueForKeyPath:@"user.name"], [[TwitterAPIClient sharedManager] createdAtToString:[place valueForKey:@"created_at"]]];
        cell.detailTextLabel.text = [place valueForKey:@"text"];
        if ([place valueForKeyPath:@"user.profile_image_url"]) {
            [cell.imageView setImageWithURL:[NSURL URLWithString:[place valueForKeyPath:@"user.profile_image_url"]] placeholderImage:[UIImage imageNamed:@"noUserImage"]];
        }
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark -

- (void)fetchNearbyTweets
{
    NSDictionary *twitterAPIParams = @{@"geocodeParam" : [[TwitterAPIClient sharedManager] getGeocodeParam:@{@"lat" : lastLat, @"lon" : lastLon}]};
    
    [[TwitterAPIClient sharedManager] fetchNearbyTweets:twitterAPIParams
                                               callback:^(NSArray *results, NSError *error){
                                                   
                                                   if (error) {
                                                       NSLog(@"%@", error);
                                                       return;
                                                   }
                                                   
                                                   NSArray *statuses = [results valueForKeyPath:@"statuses"];
                                                   NSLog(@"search count %ld", statuses.count);
                                                   self.results = [statuses mutableCopy];

                                                   //TODO 位置情報から位置付きのtweet get
                                                   if (self.results.count > 0) {
                                                       for (NSDictionary *dic in self.results) {
                                                           NSLog(@"name : %@", [dic valueForKeyPath:@"user.name"]);
                                                           NSLog(@"created_at(STR) : %@", [[TwitterAPIClient sharedManager] createdAtToString:[dic valueForKey:@"created_at"]]);
                                                           NSLog(@"text : %@", [dic valueForKey:@"text"]);
                                                           NSLog(@"profile_image_url : %@", [dic valueForKeyPath:@"user.profile_image_url"]);
                                                       }
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           self.navigationItem.title = [self getTitleGeocode];
                                                           [self.tableView reloadData];
                                                       });
                                                   }
                                                   
                                               }];
}

#pragma mark -

- (NSString *)getTitleGeocode
{
    return [NSString stringWithFormat:@"(%@, %@), %@", lastLat, lastLon, tweets_loc_radius];
}

#pragma mark -

//TODO Mapのメソッドと全く一緒
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

//TODO Mapのメソッドと全く一緒
- (NSString *)getStrDateNow
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *cmp = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit
                                        fromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%4ld/%2ld/%2ld(%@)", [cmp year], [cmp month], [cmp day], [cmp weekdayString]];
}


@end
