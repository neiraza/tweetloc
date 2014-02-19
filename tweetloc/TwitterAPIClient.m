//
//  TwitterAPIClient.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "TwitterAPIClient.h"

#import <Social/Social.h>

#define tweets_loc_radius @"1km"

@interface TwitterAPIClient()
@property (nonatomic) ACAccountStore *accountStore;
@property (nonatomic) ACAccount *account;
@end

@implementation TwitterAPIClient

@synthesize accountStore, account;

+ (TwitterAPIClient *)sharedManager
{
    static TwitterAPIClient *sharedSingleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[TwitterAPIClient alloc]
                           initSharedInstance];
    });
    return sharedSingleton;
}

- (id)initSharedInstance
{
    self = [super init];
    if (self) {
        accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

// initメソッドを呼んだら即死
- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark -

//アカウント取得が完了してから、必ず次に行くような仕組みになっていること！
- (void)fetchNearbyTweets:(NSDictionary *)args callback:(FetchNearByTweets)callback
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    
    if (!account) {
        NSLog(@"アカウントねーなー");
        return;
    }
    
    NSLog(@">>>>>>>>>>>>>>>>>> account.username %@", [account username]);
    
    NSDictionary *params = @{
                             @"screen_name" : [account username],
                             @"q" : @"",
                             @"geocode" : [args objectForKey:@"geocodeParam"],
                             @"lang" : @"ja",
                             @"count" : @"60"
                             };
    
    [self searchRequest:url parameters:params callback:callback];
}

#pragma mark -

- (void)searchRequest:(NSURL *)url parameters:(NSDictionary *)parameters callback:(FetchNearByTweets)callback
{
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:parameters];
    request.account = account;
    [request performRequestWithHandler:^(NSData* responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError* error) {
        
        if (!callback) {
            return;
        }
        
        if (error) {
            NSLog(@"TwitterAPIClient %@, %@", urlResponse, error);
            callback(nil, error);
            return;
        }
        
        if (200 <= urlResponse.statusCode && urlResponse.statusCode < 300) {
            NSError *e = nil;
            NSArray *array = [NSJSONSerialization
                             JSONObjectWithData:responseData
                             options:NSJSONReadingAllowFragments error:&e];
            
            if (e) {
                NSLog(@"TwitterAPIClient %@", e);
                callback(array, e);
                return;
            }
            
            callback(array, nil);
            
        } else {
            NSLog(@"TwitterAPIClient %@", urlResponse);
        }
    }];
}

#pragma mark - 

- (NSString *)getGeocodeParam:(NSDictionary *)geocode
{
    return [NSString stringWithFormat:@"%@,%@,%@", [geocode objectForKey:@"lat"], [geocode objectForKey:@"lon"], tweets_loc_radius];
}

#pragma mark - 

// created_atとかに使う
- (NSString *)createdAtToString:(NSString *)dateStr
{
    NSDateFormatter *inputFormat = [[NSDateFormatter alloc] init];
    [inputFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [inputFormat setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    NSDate *date = [inputFormat dateFromString:dateStr];
    
    NSDateFormatter *outputFormat = [[NSDateFormatter alloc] init];
    [outputFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    [outputFormat setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    return [outputFormat stringFromDate:date];
}

#pragma mark - 

- (void)getAccounts:(GetAccounts)callback
{
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:NULL
                                       completion:^(BOOL granted, NSError* error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if (!callback) {
                                                   NSLog(@"nil使うと先に進めないよ");
                                               }
                                               
                                               if (error) {
                                                   NSLog(@"TwitterAPIClient#getAccounts error %@", error);
                                                   callback(nil, AccountNone, error);
                                                   return;
                                               }
                                               
                                               if (granted) {
                                                   NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                                   if (accounts.count == 0) {
                                                       NSLog(@"TwitterAPIClient#getAccounts accountが設定されてない");
                                                       callback(nil, AccountNone, nil);
                                                       return;
                                                   } else if (accounts.count > 1) {
                                                       NSLog(@"TwitterAPIClient#getAccounts accountが複数設定されている");
                                                       callback(accounts, MultipleAccounts, nil);
                                                   } else {
                                                       NSLog(@"TwitterAPIClient#getAccounts accountが1つ設定されてる");
                                                       callback(accounts, AccountOne, nil);
                                                   }
                                               } else {
                                                   NSLog(@"データが取得できない謎");
                                               }
                                           });
                                       }];
}

#pragma mark - 

- (void)openAccountSetting:(id)target
{
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    tweetSheet.view.hidden = YES;
    [target presentViewController:tweetSheet animated:NO completion:^{
        [target dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark -

- (void)setUserAccount:(ACAccount *)_account
{
    account = _account;
}

#pragma mark -

- (void)tweet:(id)target
{
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                NSLog(@"投稿キャンセル");
                break;
            case SLComposeViewControllerResultDone:
                NSLog(@"Tweetしますた");
                break;
        }
        [target dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [target presentViewController:tweetSheet animated:YES completion:^{
        NSLog(@"tweet sheet起動");
    }];
}

@end
