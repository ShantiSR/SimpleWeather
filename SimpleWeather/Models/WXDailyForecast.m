//
//  WXDailyForecast.m
//  SimpleWeather
//
//  Created by Santiago Sánchez Rodríguez on 31/7/15.
//  Copyright (c) 2015 Shanti Rodríguez. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast


/*
 
 1. Get WXCondition‘s map and create a mutable copy of it.
 2. Change the max and min key maps to what you’ll need for the daily forecast.
 3. Return the new mapping.

 */
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    // 1
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    // 2
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    // 3
    return paths;
}


@end
