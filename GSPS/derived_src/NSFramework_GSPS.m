#include <Foundation/NSString.h>
@interface NSFramework_GSPS : NSObject
+ (NSString *)frameworkVersion;
+ (NSString *const*)frameworkClasses;
@end
@implementation NSFramework_GSPS
+ (NSString *)frameworkVersion { return @"0"; }
static NSString *allClasses[] = {@"PSGraphicsState", @"PSInterpreter", NULL};
+ (NSString *const*)frameworkClasses { return allClasses; }
@end
