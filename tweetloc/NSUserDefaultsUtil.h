//
//  NSUserDefaultsUtil.h
//  tweetloc_sample
//
//  Created by togu on 2014/02/17.
//  Copyright (c) 2014年 togu. All rights reserved.
//

#ifndef tweetloc_sample_NSUserDefaultsUtil_h
#define tweetloc_sample_NSUserDefaultsUtil_h

#define LOCATION_DATA_KEY @"location"

static void setLocationData(NSDictionary *dic)
{
    //@{@"coordinate":@{@"latitude":XXX, @"longitude":XXX}, @"createdAt":XXX};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dic forKey:LOCATION_DATA_KEY];
    [defaults synchronize];
}


static NSDictionary *getLocationData()
{
    //@{@"coordinate":@{@"latitude":XXX, @"longitude":XXX}, @"createdAt":XXX};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:LOCATION_DATA_KEY];
}

#endif
