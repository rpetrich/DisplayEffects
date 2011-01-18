#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

static UIColor *color;
static CFMutableDictionaryRef windowMap;

@interface CAFilter : NSObject {
}
+ (id)filterWithType:(NSString *)filterType;
@end

@interface CAWindowServer : NSObject {
}
+ (id)server;
- (NSArray *)displays;
@end

@interface CAWindowServerDisplay : NSObject {
}
@property (nonatomic, assign) CGFloat contrast;
@end

CHDeclareClass(CAFilter)
CHDeclareClass(CAWindowServer)

CHDeclareClass(UIWindow)

CHOptimizedMethod(0, self, void, UIWindow, _commonInit)
{
	CHSuper(0, UIWindow, _commonInit);
	UIView *view = [[UIView alloc] initWithFrame:self.bounds];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.userInteractionEnabled = NO;
	view.layer.compositingFilter = [CHClass(CAFilter) filterWithType:@"multiply"];
	CFDictionarySetValue(windowMap, self, view);
	if (color)
		view.backgroundColor = color;
	else
		view.hidden = YES;
	[self addSubview:view];
	[view release];
}

CHOptimizedMethod(0, self, void, UIWindow, dealloc)
{
	CFDictionaryRemoveValue(windowMap, self);
	CHSuper(0, UIWindow, dealloc);
}

CHOptimizedMethod(1, self, void, UIWindow, didAddSubview, UIView *, view)
{
	CHSuper(1, UIWindow, didAddSubview, view);
	UIView *effectView = (UIView *)CFDictionaryGetValue(windowMap, self);
	[self bringSubviewToFront:effectView];
}

static void LoadSettings()
{
	[color release];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.displayeffects.plist"];
	NSArray *components = [[settings objectForKey:@"DEMultiplyColor"] ?: @"1,0,0" componentsSeparatedByString:@","];
	if ([components count] == 3) {
		CGFloat strength = [[settings objectForKey:@"DEMultiplyStrength"] floatValue] ?: 1.0f;
		CGFloat remaining = 1.0f - strength;
		color = [[UIColor alloc] initWithRed:remaining + [[components objectAtIndex:0] floatValue] * strength
		                               green:remaining + [[components objectAtIndex:1] floatValue] * strength
		                                blue:remaining + [[components objectAtIndex:2] floatValue] * strength
		                               alpha:1.0f];
		for (UIView *view in [(id)windowMap allValues]) {
			view.backgroundColor = color;
			view.hidden = NO;
		}
	} else {
		color = nil;
		for (UIView *view in [(id)windowMap allValues]) {
			view.backgroundColor = nil;
			view.hidden = YES;
		}
	}
	float contrast = [[settings objectForKey:@"DEContrast"] floatValue];
	[[[[CHClass(CAWindowServer) server] displays] objectAtIndex:0] setContrast:contrast];
}

CHConstructor
{
	CHAutoreleasePoolForScope();
	windowMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	CHLoadLateClass(UIWindow);
	CHHook(0, UIWindow, _commonInit);
	CHHook(0, UIWindow, dealloc);
	CHHook(1, UIWindow, didAddSubview);
	CHLoadLateClass(CAFilter);
	CHLoadLateClass(CAWindowServer);
	LoadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)LoadSettings, CFSTR("com.rpetrich.displayeffects/settingchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
