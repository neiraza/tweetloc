//
//  TwitterAPIClient.h
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Accounts/Accounts.h>

enum AccountStatus : int
{
    AccountNone,
    AccountOne,
    MultipleAccounts
};

typedef void (^FetchNearByTweets)(NSArray *results, NSError *error);
typedef void (^GetAccounts)(NSArray *results, int status, NSError *error);

@interface TwitterAPIClient : NSObject

@property (nonatomic) ACAccount *account;

+ (TwitterAPIClient *)sharedManager;
- (void)fetchNearbyTweets:(NSDictionary *)args callback:(FetchNearByTweets)callback;
- (NSString *)getGeocodeParam:(NSDictionary *)geocode;
- (NSString *)createdAtToString:(NSString *)dateStr;
- (void)getAccounts:(GetAccounts)callback;
- (void)openAccountSetting:(id)target;
- (void)setUserAccount:(ACAccount *)_account;
- (void)tweet:(id)target;

@end
