//
//  NSDate+Generic.h
//  theBlimpBaseClasses
//
//  Created by Will Hindenburg on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Generic)
@property (readonly) NSString *socialDate;

- (NSDate *)initFacebookDateFormatWithString:(NSString *)dateString;
- (NSDate *)initTwitterDateFormatWithString:(NSString *)dateString;

@end
