//
//  TwitterAuthViewController.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/18.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "TwitterAuthViewController.h"

#import <Accounts/Accounts.h>

#import "TwitterAPIClient.h"

@interface TwitterAuthViewController ()
@property (nonatomic) NSArray *accounts; //複数アカウント対応
@end

@implementation TwitterAuthViewController

@synthesize accounts, tweetMap;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    accounts = [[NSArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    tweetMap.enabled = NO;
    [self authenticate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 

- (IBAction)authenticate
{
    [[TwitterAPIClient sharedManager] getAccounts:^(NSArray *results, int status, NSError *error) {
        switch (status) {
            case AccountNone: {
                [[TwitterAPIClient sharedManager] openAccountSetting:self];
                tweetMap.enabled = NO;
                break;
            }
            case AccountOne: {
                ACAccount *account = [results lastObject];
                NSLog(@"account is %@", account);
                [[TwitterAPIClient sharedManager] setUserAccount:account];
                tweetMap.enabled = YES;
                break;
            }
            case MultipleAccounts:
                accounts = [results copy];
                if (accounts.count > 0) {
                    [self showActionSheet];
                } else {
                    tweetMap.enabled = NO;
                }
                break;
        }
    }];
}

#pragma mark - 複数アカウントの中から1つを選択させる

- (void)showActionSheet
{
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.delegate = self;
    for (int i = 0; i < accounts.count; i++) {
        NSLog(@"showActionSheet %@", [accounts[i] valueForKey:@"username"]);
        [sheet addButtonWithTitle:[accounts[i] valueForKey:@"username"]];
    }
    [sheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"clicked %@", accounts[buttonIndex]);
    if (accounts[buttonIndex]) {
        [[TwitterAPIClient sharedManager] setUserAccount:accounts[buttonIndex]];
        tweetMap.enabled = YES;
    }
}

//#pragma mark - 
//
//- (void)hoge
//{
//    [self.navigationController pushViewController:nil animated:NO];
//}

#pragma mark - 

//遷移時に呼ばれる
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue");
}

@end
