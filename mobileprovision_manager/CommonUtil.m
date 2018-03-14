#import "CommonUtil.h"
static NSDateFormatter *dateFormatter;
@implementation CommonUtil

+(void) initialize{
	dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh"]];
}

+(NSString *) dateChangeString:(NSString *) string fromFormat:(NSString *) fromFormat toFormat:(NSString *) toFormat{
    [dateFormatter setDateFormat:fromFormat];
    NSDate *date = [dateFormatter dateFromString:string];
    [dateFormatter setDateFormat:toFormat];
    return [dateFormatter stringFromDate:date];
}

+(NSDate *) dateFromString:(NSString *) string fromFormat:(NSString *) fromFormat{
    [dateFormatter setDateFormat:fromFormat];
    return [dateFormatter dateFromString:string];
}

+(NSString *) stringFromDate:(NSDate *) date toFormat:(NSString *) toFormat{
    [dateFormatter setDateFormat:toFormat];
    return [dateFormatter stringFromDate:date];
}



@end
