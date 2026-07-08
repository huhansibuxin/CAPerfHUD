#import "CAPHMenuModule.h"
#import "CAPHMenuModuleViewController.h"

@implementation CAPHMenuModule

- (CCUIContentModuleContentViewController *)contentViewController {
    return [[CAPHMenuModuleViewController alloc] init];
}

@end