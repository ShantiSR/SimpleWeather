//
//  WXManager.m
//  SimpleWeather
//
//  Created by Santiago Sánchez Rodríguez on 31/7/15.
//  Copyright (c) 2015 Shanti Rodríguez. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager ()

@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;

@end

@implementation WXManager

+ (instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

/*
 
 1. Creates a location manager and sets it’s delegate to self.
 2. Creates the WXClient object for the manager. This handles all networking and data parsing, following our separation of concerns best practice.
 3. The manager observes the currentLocation key on itself using a ReactiveCocoa macro which returns a signal. This is similar to Key-Value Observing but is far more powerful.
 4. In order to continue down the method chain, currentLocation must not be nil.
 -flattenMap: is very similar to -map:, but instead of mapping each value, it flattens the values and returns one object containing all three signals. In this way, you can consider all three processes as a single unit of work.
 5. Deliver the signal to subscribers on the main thread.
 6. It’s not good practice to interact with the UI from inside your model, but for demonstration purposes you’ll display a banner whenever an error occurs.

 */
- (id)init {
    if (self = [super init]) {
        // 1
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        // 2
        _client = [[WXClient alloc] init];
        
        // 3
        [[[[RACObserve(self, currentLocation)
            // 4
            ignore:nil]
           // 5
           // Flatten and subscribe to all 3 signals when currentLocation updates
           flattenMap:^(CLLocation *newLocation) {
               return [RACSignal merge:@[
                                         [self updateCurrentConditions],
                                         [self updateDailyForecast],
                                         [self updateHourlyForecast]
                                         ]];
               // 6
           }] deliverOn:RACScheduler.mainThreadScheduler]
         // 7
         subscribeError:^(NSError *error) {
             [TSMessage showNotificationWithTitle:@"Error"
                                         subtitle:@"There was a problem fetching the latest weather."
                                             type:TSMessageNotificationTypeError];
         }];
    }
    return self;
}

#pragma mark Finding Location

/*
 
 1. Always ignore the first location update because it is almost always cached.
 2. Once you have a location with the proper accuracy, stop further updates.
 3. Setting the currentLocation key triggers the RACObservable you set earlier in the init implementation.

 */
- (void)findCurrentLocation {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // 1
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // 2
    if (location.horizontalAccuracy > 0) {
        // 3
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

#pragma mark Retrieve the Weather Data

- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

@end
