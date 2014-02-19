//
//  NSDateComponents+WeekDayString.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "NSDateComponents+WeekDayString.h"

@implementation NSDateComponents (WeekDayString)

- (NSString *)weekdayString
{
    NSString *result;
    NSInteger weekday = [self weekday];
    switch (weekday) {
        case 1:
            result = @"Sun";
            break;
        case 2:
            result = @"Mon";
            break;
        case 3:
            result = @"Tue";
            break;
        case 4:
            result = @"Wed";
            break;
        case 5:
            result = @"Thu";
            break;
        case 6:
            result = @"Fri";
            break;
        case 7:
            result = @"Sat";
            break;
        default:
            result = @"";
            break;
    }
    return result;
}

@end
