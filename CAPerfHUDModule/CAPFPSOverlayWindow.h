#import <UIKit/UIKit.h>

@interface CAPFPSOverlayWindow : NSObject

+ (instancetype)shared;
- (void)show;
- (void)hide;
@property (nonatomic, readonly) BOOL isVisible;

@end