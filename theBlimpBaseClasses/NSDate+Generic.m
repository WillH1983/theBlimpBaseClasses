//
//  NSDate+Generic.m
//  theBlimpBaseClasses
//
//  Created by Will Hindenburg on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+Generic.h"
#define secondsInAMinute 60
#define secondsInAnHour 3600
#define secondsInADay 86400
#define secondsInTwoDays 172800

@implementation NSDate (Generic)

- (NSString *)socialDate
{
    NSString *dateDescription = nil;
    
    NSTimeInterval time = -[self timeIntervalSinceNow];
    
    if (time < secondsInAMinute)
    {
        dateDescription = @"Just Now";
    }
    else if (time < secondsInAnHour)
    {
        double mins = round(time/secondsInAMinute);
        dateDescription = [[NSString alloc] initWithFormat:@"%.0f Minutes ago", mins];
    }
    else if (time < secondsInADay)
    {
        double hours = round(time/secondsInAnHour);
        dateDescription = [[NSString alloc] initWithFormat:@"%.0f Hours ago", hours];
    }
    else if (time < secondsInTwoDays)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        dateDescription = [dateFormatter stringFromDate:self];
        dateDescription = [[NSString alloc] initWithFormat:@"Yesterday at %@", dateDescription];
    }
    else 
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        dateDescription = [dateFormatter stringFromDate:self];
    }
    
    return dateDescription;
}

- (NSDate *)initFacebookDateFormatWithString:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    self = [dateFormatter dateFromString:dateString];
    return self;
}

- (NSDate *)initTwitterDateFormatWithString:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE MMM d HH:mm:ss zzzz yyyy"];
    self = [dateFormatter dateFromString:dateString];
    return self;
}

@end
