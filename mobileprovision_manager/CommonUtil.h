#define YYYYMMDD @"yyyy-MM-dd"
#define YYYYMMDDHHMMSS @"yyyy-MM-dd HH:mm:ss"
#define YYYYMMDDHHMM @"yyyy-MM-dd HH:mm"
#define MMDDHHMM @"MM-dd HH:mm"

#import <Cocoa/Cocoa.h>

@interface CommonUtil : NSObject
+(NSString *) dateChangeString:(NSString *) string fromFormat:(NSString *) fromFormat toFormat:(NSString *) toFormat;
+(NSDate *) dateFromString:(NSString *) string fromFormat:(NSString *) fromFormat;
+(NSString *) stringFromDate:(NSDate *) date toFormat:(NSString *) toFormat;

@end
