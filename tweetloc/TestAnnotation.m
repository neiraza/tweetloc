//
//  TestAnnotation.m
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#import "TestAnnotation.h"

@implementation TestAnnotation

@synthesize coordinate;
@synthesize title, subtitle;

-(id)initWithCoordinate:(CLLocationCoordinate2D)co
{
    coordinate = co;
    return self;
}

@end
