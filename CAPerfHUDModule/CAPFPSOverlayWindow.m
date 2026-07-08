#import "CAPFPSOverlayWindow.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - FPS Bar View (mimics system QuartzCore FPS HUD)

@interface CAPFPSBarView : UIView
@property (nonatomic, assign) CGFloat fps;
@end

@implementation CAPFPSBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setFps:(CGFloat)fps {
    _fps = fps;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;

    // === Layout constants ===
    CGFloat barH = 4.0;                 // green bar height
    CGFloat barY = h - barH - 1;        // bar bottom-aligned
    CGFloat barX = 0;
    CGFloat barW = w;
    CGFloat cornerR = 2.0;

    // === Background bar (dark semi-transparent) ===
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0 alpha:0.45].CGColor);
    UIBezierPath *bgPath = [UIBezierPath bezierPathWithRoundedRect:
        CGRectMake(barX, barY, barW, barH) cornerRadius:cornerR];
    [bgPath fill];

    // === Filled portion (green gradient bar) ===
    CGFloat ratio = MIN(_fps / 60.0, 1.0);
    if (ratio > 0) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.15
            green:0.85 blue:0.15 alpha:1.0].CGColor);
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:
            CGRectMake(barX, barY, barW * ratio, barH) cornerRadius:cornerR];
        [fillPath fill];
    }

    // === FPS number (white, top-right of bar) ===
    NSString *fpsText = [NSString stringWithFormat:@"%.0f", _fps];
    NSDictionary *attrs = @{
        NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:10.0
            weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    CGSize textSize = [fpsText sizeWithAttributes:attrs];
    CGFloat textX = barX;
    CGFloat textY = barY - textSize.height - 1;
    [fpsText drawAtPoint:CGPointMake(textX, textY) withAttributes:attrs];
}

@end

#pragma mark - FPS Overlay Window Manager

@interface CAPFPSOverlayWindow ()
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) CAPFPSBarView *barView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign) NSUInteger frameCount;
@property (nonatomic, assign) BOOL isVisible;
@end

@implementation CAPFPSOverlayWindow

+ (instancetype)shared {
    static CAPFPSOverlayWindow *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CAPFPSOverlayWindow alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat barWidth = 64.0;
    CGFloat barHeight = 18.0;
    CGFloat margin = 10.0;
    CGFloat statusBarH = 20.0;
    CGFloat x = screenBounds.size.width - barWidth - margin;
    CGFloat y = statusBarH + 4.0;

    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(x, y, barWidth, barHeight)];
    self.window.windowLevel = UIWindowLevelStatusBar + 100;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.opaque = NO;
    self.window.userInteractionEnabled = NO;
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view.backgroundColor = [UIColor clearColor];

    self.barView = [[CAPFPSBarView alloc] initWithFrame:
        CGRectMake(0, 0, barWidth, barHeight)];
    [self.window.rootViewController.view addSubview:self.barView];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self
        selector:@selector(tick:)];
    self.displayLink.paused = YES;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
        forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        self.frameCount = 0;
        return;
    }

    self.frameCount++;
    CFTimeInterval elapsed = link.timestamp - self.lastTimestamp;

    if (elapsed >= 0.8) {
        CGFloat fps = (CGFloat)self.frameCount / elapsed;
        self.barView.fps = fps;
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

- (void)show {
    if (self.isVisible) return;
    self.isVisible = YES;
    self.lastTimestamp = 0;
    self.frameCount = 0;
    self.barView.fps = 0;
    self.displayLink.paused = NO;
    self.window.hidden = NO;
}

- (void)hide {
    if (!self.isVisible) return;
    self.isVisible = NO;
    self.displayLink.paused = YES;
    self.window.hidden = YES;
    self.barView.fps = 0;
}

@end