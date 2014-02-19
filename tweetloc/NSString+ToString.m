//
//  NSString+ToString.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "NSString+ToString.h"

@implementation NSString (ToString)

+ (NSString *)toString:(double)d
{
    return [NSString stringWithFormat:@"%g", d];
}

@end
