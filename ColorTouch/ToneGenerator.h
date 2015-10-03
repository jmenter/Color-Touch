
#import <UIKit/UIKit.h>

@interface ToneGenerator : NSObject

@property (nonatomic) CGFloat frequency;

- (id)init;

- (void)play;
- (void)stop;

@end
