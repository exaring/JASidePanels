//
//  JAViewController.m
//  JASidePanels
//
//  Created by Jesse Andersen on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "JASidePanelController.h"

@interface JASidePanelController() {
	CGRect _centerPanelRestingFrame;		
	CGPoint _locationBeforePan;
}

@property (nonatomic, readwrite) JASidePanelState state;
@property (nonatomic, strong) UIView *tapView;

// panel containers
@property (nonatomic, strong) UIView *leftPanelContainer;
@property (nonatomic, strong) UIView *rightPanelContainer;
@property (nonatomic, strong) UIView *centerPanelContainer;

// setup
- (void)_configureContainers;
- (void)_sizeSidePanels;

// center panel
- (void)_swapCenter:(UIViewController *)previous with:(UIViewController *)next;

// internal helpers
- (BOOL)_validateThreshold:(CGFloat)movement;

// panel loading
- (void)_addPanGestureToView:(UIView *)view;
- (void)_loadCenterPanel;
- (void)_loadLeftPanel;
- (void)_loadRightPanel;

// panel width
- (CGFloat)_leftPanelWidth;
- (CGFloat)_rightPanelWidth;

// gestures
- (void)_handlePan:(UIGestureRecognizer *)sender;
- (void)_completePan:(CGFloat)deltaX;
- (void)_undoPan:(CGFloat)deltaX;

// showing panels
- (void)_showLeftPanel:(BOOL)animated bounce:(BOOL)shouldBounce;
- (void)_showCenterPanel:(BOOL)animated bounce:(BOOL)shouldBounce;
- (void)_showRightPanel:(BOOL)animated bounce:(BOOL)shouldBounce;

// animation
- (CGFloat)_calculatedDuration;
- (void)_animateCenterPanel:(BOOL)shouldBounce completion:(void (^)(BOOL finished))completion;
- (void)_adjustCenterFrame;

@end

@implementation JASidePanelController

@synthesize leftPanelContainer = _leftPanelContainer;
@synthesize rightPanelContainer = _rightPanelContainer;
@synthesize centerPanelContainer = _centerPanelContainer;

@synthesize tapView = _tapView;

@synthesize style = _style;
@synthesize state = _state;

@synthesize leftPanel = _leftPanel;
@synthesize centerPanel = _centerPanel;
@synthesize rightPanel = _rightPanel;

@synthesize leftGapPercentage = _leftGapPercentage;
@synthesize leftFixedWidth = _leftFixedWidth;
@synthesize rightGapPercentage = _rightGapPercentage;
@synthesize rightFixedWidth = _rightFixedWidth;

@synthesize minimumMovePercentage = _minimumMovePercentage;
@synthesize maximumAnimationDuration = _maximumAnimationDuration;
@synthesize bounceDuration = _bounceDuration;
@synthesize bouncePercentage = _bouncePercentage;

#pragma mark - Icon

+ (UIImage *)defaultImage {
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.f, 13.f), NO, 0.0f);
	
	[[UIColor blackColor] setFill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 20, 1)] fill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 5, 20, 1)] fill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 10, 20, 1)] fill];

	[[UIColor whiteColor] setFill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 1, 20, 2)] fill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 6,  20, 2)] fill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 11, 20, 2)] fill];   
	
	UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return iconImage;
}

#pragma mark - NSObject

- (id)init {
	if (self = [super init]) {
		self.style = JASidePanelSingleActive;
		self.leftGapPercentage = 0.8f;
		self.rightGapPercentage = 0.8f;
		self.minimumMovePercentage = 0.15f;
		self.maximumAnimationDuration = 0.2f;
		self.bounceDuration = 0.1f;
		self.bouncePercentage = 0.075f;
	}
	return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	self.centerPanelContainer = [[UIView alloc] initWithFrame:self.view.bounds];
	_centerPanelRestingFrame = self.centerPanelContainer.frame;
	
	self.leftPanelContainer = [[UIView alloc] initWithFrame:self.view.bounds];
	self.leftPanelContainer.hidden = YES;
	
	self.rightPanelContainer = [[UIView alloc] initWithFrame:self.view.bounds];
	self.rightPanelContainer.hidden = YES;
	
	[self _configureContainers];
	[self _sizeSidePanels];

	[self styleContainer:self.centerPanelContainer animate:NO duration:0.0f];
	[self styleContainer:self.leftPanelContainer animate:NO duration:0.0f];
	[self styleContainer:self.rightPanelContainer animate:NO duration:0.0f];
	
	[self.view addSubview:self.centerPanelContainer];
	[self.view addSubview:self.leftPanelContainer];
	[self.view addSubview:self.rightPanelContainer];
	
	self.state = JASidePanelCenterVisible;
	
	[self _swapCenter:nil with:_centerPanel];
	[self.view bringSubviewToFront:self.centerPanelContainer];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tapView = nil;
	self.centerPanelContainer = nil;
	self.leftPanelContainer = nil;
	self.rightPanelContainer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	_centerPanelRestingFrame.size = self.centerPanelContainer.bounds.size;
	switch (self.state) {
		case JASidePanelLeftVisible:
			[self _showLeftPanel:NO bounce:NO];
			break;
		case JASidePanelRightVisible:
			[self _showRightPanel:NO bounce:NO];
			break;
		default:
			break;
	}
	
	[self _sizeSidePanels];
	[self styleContainer:self.centerPanelContainer animate:YES duration:duration];	
	[self styleContainer:self.leftPanelContainer animate:YES duration:duration];	
	[self styleContainer:self.rightPanelContainer animate:YES duration:duration];	
}

#pragma mark - Style

- (void)setStyle:(JASidePanelStyle)style {
	if (style != _style) {
		_style = style;
		if (self.isViewLoaded) {
			[self _configureContainers];
			[self _sizeSidePanels];
		}
	}
}

- (void)styleContainer:(UIView *)container animate:(BOOL)animate duration:(NSTimeInterval)duration {
	UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:container.bounds cornerRadius:0.0f];
	if (animate) {
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
		animation.fromValue = (id)container.layer.shadowPath;
		animation.toValue = (id)shadowPath.CGPath;
		animation.duration = duration;
		[container.layer addAnimation:animation forKey:@"shadowPath"];
	}
	container.layer.shadowPath = shadowPath.CGPath;	
	container.layer.shadowColor = [UIColor blackColor].CGColor;
	container.layer.shadowRadius = 10.0f;
	container.layer.shadowOpacity = 0.75f;
	container.clipsToBounds = NO;
}

- (void)stylePanel:(UIView *)panel {
	panel.layer.cornerRadius = 6.0f;
	panel.clipsToBounds = YES;
}

- (void)_configureContainers {
	self.leftPanelContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
	self.rightPanelContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
	self.centerPanelContainer.frame =  self.view.bounds;
	self.centerPanelContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)_sizeSidePanels {
	CGRect leftFrame = self.view.bounds;
	CGRect rightFrame = self.view.bounds;
	if (self.style == JASidePanelMultipleActive) {
		// left panel container
		leftFrame.size.width = [self _leftPanelWidth];
		
		// right panel container
		rightFrame.size.width = [self _rightPanelWidth];
		rightFrame.origin.x = self.view.bounds.size.width - rightFrame.size.width;
	}
	self.leftPanelContainer.frame = leftFrame;
	self.rightPanelContainer.frame = rightFrame;
}

#pragma mark - Panels

- (void)setCenterPanel:(UIViewController *)centerPanel {
	UIViewController *previous = _centerPanel;
	if (centerPanel != _centerPanel) {
		_centerPanel = centerPanel;
	}
	if (self.isViewLoaded && self.state == JASidePanelCenterVisible) {
		[self _swapCenter:previous with:_centerPanel];
	} else if (self.isViewLoaded) {
		[UIView animateWithDuration:0.2f animations:^{
			// first move the centerPanel offscreen
			CGFloat x = self.state == JASidePanelLeftVisible ? self.view.bounds.size.width : -self.view.bounds.size.width;
			_centerPanelRestingFrame.origin.x = x;
			self.centerPanelContainer.frame = _centerPanelRestingFrame;
		} completion:^(BOOL finished) {
			[self _swapCenter:previous with:_centerPanel];
			[self _showCenterPanel:YES bounce:NO];
		}];
	}
}

- (void)_swapCenter:(UIViewController *)previous with:(UIViewController *)next {
	if (previous != next) {
		[previous willMoveToParentViewController:nil];
		[previous.view removeFromSuperview];
		[previous removeFromParentViewController];
		
		if (next) {
			[self _loadCenterPanel];
			[self addChildViewController:next];
			[self.centerPanelContainer addSubview:next.view];
		}
	}
}

- (void)setLeftPanel:(UIViewController *)leftPanel {
	if (leftPanel != _leftPanel) {
		[_leftPanel willMoveToParentViewController:nil];
		[_leftPanel.view removeFromSuperview];
		[_leftPanel removeFromParentViewController];
		_leftPanel = leftPanel;
		[self addChildViewController:_leftPanel];
	}
}

- (void)setRightPanel:(UIViewController *)rightPanel {
	if (rightPanel != _rightPanel) {
		[_rightPanel willMoveToParentViewController:nil];
		[_rightPanel.view removeFromSuperview];
		[_rightPanel removeFromParentViewController];
		_rightPanel = rightPanel;
		[self addChildViewController:_rightPanel];
	}
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.view == self.tapView) {
		return YES;
	} else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
		UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
		CGPoint translate = [pan translationInView:self.centerPanelContainer];
		return translate.x != 0 && ((translate.y / translate.x) < 1.0f);
	}
	return NO;
}

#pragma mark - Pan Gestures

- (void)_addPanGestureToView:(UIView *)view {
	UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePan:)];
	panGesture.delegate = self;
	panGesture.maximumNumberOfTouches = 1;
	panGesture.minimumNumberOfTouches = 1;
	[view addGestureRecognizer:panGesture];	
}

- (void)_handlePan:(UIGestureRecognizer *)sender {
	if ([sender isKindOfClass:[UIPanGestureRecognizer class]]) {
		UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)sender;
		
		if (pan.state == UIGestureRecognizerStateBegan) {
			_locationBeforePan = self.centerPanelContainer.frame.origin;
		}
		
		CGPoint translate = [pan translationInView:self.centerPanelContainer];
		CGRect frame = _centerPanelRestingFrame;
		frame.origin.x += [self _correctMovement:translate.x];
		self.centerPanelContainer.frame = frame;
		
		// if center panel has focus, make sure correct side panel is revealed
		if (self.state == JASidePanelCenterVisible) {
			if (frame.origin.x > 0.0f) {
				[self _loadLeftPanel];
			} else if(frame.origin.x < 0.0f) {
				[self _loadRightPanel];
			}
		}
		
		if (sender.state == UIGestureRecognizerStateEnded) {
			CGFloat deltaX =  frame.origin.x - _locationBeforePan.x;			
			if ([self _validateThreshold:deltaX]) {
				[self _completePan:deltaX];
			} else {
				[self _undoPan:deltaX];
			}
		}
	}
}

- (void)_completePan:(CGFloat)deltaX {
	switch (self.state) {
		case JASidePanelCenterVisible:
			if (deltaX > 0.0f) {
				[self _showLeftPanel:YES bounce:YES];
			} else {
				[self _showRightPanel:YES bounce:YES];
			}
			break;
		case JASidePanelLeftVisible:
			[self _showCenterPanel:YES bounce:_rightPanel != nil];
			break;
		case JASidePanelRightVisible:
			[self _showCenterPanel:YES bounce:_leftPanel != nil];
			break;
		default:
			break;
	}	
}

- (void)_undoPan:(CGFloat)deltaX {
	switch (self.state) {
		case JASidePanelCenterVisible:
			[self _showCenterPanel:YES bounce:NO];
			break;
		case JASidePanelLeftVisible:
			[self _showLeftPanel:YES bounce:NO];
			break;
		case JASidePanelRightVisible:
			[self _showRightPanel:YES bounce:NO];
		default:
			break;
	}
}

#pragma mark - Tap Gesture

- (void)setTapView:(UIView *)tapView {
	if (tapView != _tapView) {
		[_tapView removeFromSuperview];
		_tapView = tapView;
		if (_tapView) {
			[self _addTapGestureToView:_tapView];
			[self _addPanGestureToView:_tapView];
			[self.view addSubview:_tapView];
		}
	}
}

- (void)_addTapGestureToView:(UIView *)view {
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_centerPanelTapped:)];
	[view addGestureRecognizer:tapGesture];	
}

- (void)_centerPanelTapped:(UIGestureRecognizer *)gesture {
	[self _showCenterPanel:YES bounce:NO];
}

#pragma mark - Internal Methods

- (CGFloat)_correctMovement:(CGFloat)movement {	
	if (self.state == JASidePanelCenterVisible) {
		CGFloat position = _centerPanelRestingFrame.origin.x + movement;		
		if ((position > 0.0f && !self.leftPanel) || (position < 0.0f && !self.rightPanel)) {
			return 0.0f;
		}
	}
	return movement;
}

- (BOOL)_validateThreshold:(CGFloat)movement {
	CGFloat minimum = floorf(self.view.bounds.size.width * self.minimumMovePercentage);
	switch (self.state) {
		case JASidePanelLeftVisible:
			return movement <= -minimum;
		case JASidePanelCenterVisible:
			return fabsf(movement) >= minimum;
		case JASidePanelRightVisible:
			return movement >= minimum;
		default:
			break;
	}
	return NO;
}

#pragma mark - Loading Panels

- (void)_loadCenterPanel {
	if (self.gestureController.isViewLoaded) {
		[self _addPanGestureToView:self.gestureController.view];
	}
	[self.gestureController addObserver:self forKeyPath:@"view" options:0 context:nil];
	
	_centerPanel.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_centerPanel.view.frame = self.centerPanelContainer.bounds;
	[self stylePanel:_centerPanel.view];
		
	if (self.leftPanel && !self.gestureController.navigationItem.leftBarButtonItem) {
		self.gestureController.navigationItem.leftBarButtonItem = [self leftButtonForCenterPanel];
	}
}

- (void)_loadLeftPanel {
	self.rightPanelContainer.hidden = YES;
	if (self.leftPanelContainer.hidden && self.leftPanel) {
		
		if (!_leftPanel.view.superview) {
			_leftPanel.view.frame = self.leftPanelContainer.bounds;
			_leftPanel.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[self stylePanel:_leftPanel.view];
			[self.leftPanelContainer addSubview:_leftPanel.view];
		}
		
		self.leftPanelContainer.hidden = NO;
	}
}

- (void)_loadRightPanel {
	self.leftPanelContainer.hidden = YES;
	if (self.rightPanelContainer.hidden && self.rightPanel) {
		
		if (!_rightPanel.view.superview) {
			_rightPanel.view.frame = self.rightPanelContainer.bounds;
			_rightPanel.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[self stylePanel:_rightPanel.view];
			[self.rightPanelContainer addSubview:_rightPanel.view];
		}
		
		self.rightPanelContainer.hidden = NO;
	}
}

#pragma mark - Animation

- (void)_adjustCenterFrame {
	if (self.style == JASidePanelMultipleActive) {
		switch (self.state) {
			case JASidePanelCenterVisible:
				_centerPanelRestingFrame.size.width = self.view.bounds.size.width;	
				break;
			case JASidePanelLeftVisible:
				_centerPanelRestingFrame.size.width = self.view.bounds.size.width - [self _leftPanelWidth];
				break;
			case JASidePanelRightVisible:
				_centerPanelRestingFrame.origin.x = 0.0f;
				_centerPanelRestingFrame.size.width = self.view.bounds.size.width - [self _rightPanelWidth];
				break;
			default:
				break;
		}
	}
}

- (CGFloat)_calculatedDuration {
	CGFloat remaining = fabsf(self.centerPanelContainer.frame.origin.x - _centerPanelRestingFrame.origin.x);	
	CGFloat max = _locationBeforePan.x == _centerPanelRestingFrame.origin.x ? remaining : fabsf(_locationBeforePan.x - _centerPanelRestingFrame.origin.x);
	return max > 0.0f ? self.maximumAnimationDuration * (remaining / max) : self.maximumAnimationDuration;
}

- (void)_animateCenterPanel:(BOOL)shouldBounce completion:(void (^)(BOOL finished))completion {
	CGFloat bounceDistance = (_centerPanelRestingFrame.origin.x - self.centerPanelContainer.frame.origin.x) * self.bouncePercentage;
	
	[self _adjustCenterFrame];
	
	// looks bad if we bounce when the center panel grows
	if (_centerPanelRestingFrame.size.width > self.centerPanelContainer.frame.size.width) {
		shouldBounce = NO;
	}
	
	CGFloat duration = [self _calculatedDuration];
	[UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
		self.centerPanelContainer.frame = _centerPanelRestingFrame;	
		[self styleContainer:self.centerPanelContainer animate:YES duration:duration];
	} completion:^(BOOL finished) {
		if (shouldBounce) {
			// make sure correct panel is displayed under the bounce
			if (self.state == JASidePanelCenterVisible) {
				if (bounceDistance > 0.0f) {
					[self _loadLeftPanel];
				} else {
					[self _loadRightPanel];
				}
			}
			// animate the bounce
			[UIView animateWithDuration:self.bounceDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
				CGRect bounceFrame = _centerPanelRestingFrame;
				bounceFrame.origin.x += bounceDistance;
				self.centerPanelContainer.frame = bounceFrame;
			} completion:^(BOOL finished2) {
				[UIView animateWithDuration:self.bounceDuration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
					self.centerPanelContainer.frame = _centerPanelRestingFrame;				
				} completion:completion];
			}];
		} else if (completion) {
			completion(finished);
		}
	}];
}

#pragma mark - Panel Width

- (CGFloat)_leftPanelWidth {
	return self.leftFixedWidth ? self.leftFixedWidth : floorf(self.view.bounds.size.width * self.leftGapPercentage);
}

- (CGFloat)_rightPanelWidth {
	return self.rightFixedWidth ? self.rightFixedWidth : floorf(self.view.bounds.size.width * self.rightGapPercentage);
}

#pragma mark - Showing Panels

- (void)_showLeftPanel:(BOOL)animated bounce:(BOOL)shouldBounce {
	self.state = JASidePanelLeftVisible;
	[self _loadLeftPanel];
	
	_centerPanelRestingFrame.origin.x = [self _leftPanelWidth];
		
	if (animated) {
		[self _animateCenterPanel:shouldBounce completion:nil];
	} else {
		[self _adjustCenterFrame];
		self.centerPanelContainer.frame = _centerPanelRestingFrame;			
	}
	
	if (self.style == JASidePanelSingleActive) {
		self.tapView = [[UIView alloc] initWithFrame:_centerPanelRestingFrame];
	}
}

- (void)_showRightPanel:(BOOL)animated bounce:(BOOL)shouldBounce {
	self.state = JASidePanelRightVisible;
	[self _loadRightPanel];
	
	_centerPanelRestingFrame.origin.x = -[self _rightPanelWidth];
	
	if (animated) {
		[self _animateCenterPanel:shouldBounce completion:nil];
	} else {
		[self _adjustCenterFrame];
		self.centerPanelContainer.frame = _centerPanelRestingFrame;			
	}
	
	if (self.style == JASidePanelSingleActive) {
		self.tapView = [[UIView alloc] initWithFrame:_centerPanelRestingFrame];
	}
}

- (void)_showCenterPanel:(BOOL)animated bounce:(BOOL)shouldBounce {
	self.state = JASidePanelCenterVisible;
	_centerPanelRestingFrame.origin.x = 0.0f;
		
	if (animated) {
		[self _animateCenterPanel:shouldBounce completion:^(BOOL finished) {
			self.leftPanelContainer.hidden = YES;
			self.rightPanelContainer.hidden = YES;
		}];
	} else {
		[self _adjustCenterFrame];
		self.centerPanelContainer.frame = _centerPanelRestingFrame;		
		self.leftPanelContainer.hidden = YES;
		self.rightPanelContainer.hidden = YES;
	}
	
	self.tapView = nil;
}

#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"view"]) {
		if (self.gestureController.isViewLoaded) {
			[self _addPanGestureToView:self.gestureController.view];
		}
	}
}

#pragma mark - Public Methods

- (UIBarButtonItem *)leftButtonForCenterPanel {
	return [[UIBarButtonItem alloc] initWithImage:[[self class] defaultImage] style:UIBarButtonItemStylePlain target:self action:@selector(toggleLeftPanel:)];
}

- (UIViewController *)gestureController {
	UIViewController *result = self.centerPanel;
	if ([result isKindOfClass:[UINavigationController class]]) {
		UINavigationController *nav = (UINavigationController *)result;
		if ([nav.viewControllers count] > 0) {
			result = [nav.viewControllers objectAtIndex:0];
		}
	}
	return result;
}

- (void)showLeftPanel:(BOOL)animated {
	[self _showLeftPanel:animated bounce:NO];
}

- (void)showRightPanel:(BOOL)animated {
	[self _showRightPanel:animated bounce:NO];
}

- (void)showCenterPanel:(BOOL)animated {
	[self _showCenterPanel:animated bounce:NO];
}

- (void)toggleLeftPanel:(id)sender {
	if (self.state == JASidePanelLeftVisible) {
		[self _showCenterPanel:YES bounce:NO];
	} else if (self.state == JASidePanelCenterVisible) {
		[self _showLeftPanel:YES bounce:NO];
	}
}

- (void)toggleRightPanel:(id)sender {
	if (self.state == JASidePanelRightVisible) {
		[self _showCenterPanel:YES bounce:NO];
	} else if (self.state == JASidePanelCenterVisible) {
		[self _showRightPanel:YES bounce:NO];
	}
}

@end