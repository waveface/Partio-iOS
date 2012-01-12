//
//  WARefreshActionView.m
//  wammer
//
//  Created by Evadne Wu on 10/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "WARefreshActionView.h"
#import "WADefines.h"
#import "WARemoteInterface.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"

#import "FIFactory.h"
#import "FISoundEngine.h"
#import "FISound.h"

@interface WARefreshActionView ()

- (void) updateStateAnimated:(BOOL)animate;

@property (nonatomic, readwrite, retain) WARemoteInterface *interface;
@property (nonatomic, readwrite, retain) UIButton *actionButton;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, readwrite, assign) BOOL currentlyBusy;
@property (nonatomic, readwrite, assign) BOOL requiresSoundEffectOnSessionEnd;

@property (nonatomic, readwrite, retain) FIFactory *soundFactory;
@property (nonatomic, readwrite, retain) FISoundEngine *soundEngine;
@property (nonatomic, readwrite, retain) FISound *refreshStartSound;
@property (nonatomic, readwrite, retain) FISound *refreshEndSound;

- (void) playRefreshStartSoundEffect;
- (void) playRefreshEndSoundEffect;

@end


@implementation WARefreshActionView
@synthesize interface, actionButton, activityIndicatorView;
@synthesize currentlyBusy, requiresSoundEffectOnSessionEnd;
@synthesize soundFactory, soundEngine, refreshStartSound, refreshEndSound;

- (id) initWithFrame:(CGRect)frame {

	return [self initWithRemoteInterface:nil];

}

- (id) initWithRemoteInterface:(WARemoteInterface *)anInterface {

	self = [super initWithFrame:(CGRect){ 0, 0, 24, 24 }];
	if (!self)
		return nil;
	
	self.interface = anInterface;
	[self addSubview:self.actionButton];
	[self addSubview:self.activityIndicatorView];

	//	self.actionButton.center = (CGPoint){ 12, 12 };
	self.activityIndicatorView.center = (CGPoint){ 12, 12 };
	
	[self.interface addObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
		
	return self;

}

- (void) dealloc {

	[interface removeObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates"];

	[interface release];
	[actionButton release];
	[activityIndicatorView release];
	
	[soundFactory release];
	[soundEngine release];
	
	[super dealloc];

}

- (UIButton *) actionButton {

	if (actionButton)
		return actionButton;
	
	actionButton = [WAButtonForImage(WABarButtonImageFromImageNamed(@"WARefreshGlyph")) retain];
	actionButton.frame = (CGRect){ CGPointZero, (CGSize){ 25, 25 }};

	actionButton.contentEdgeInsets = UIEdgeInsetsZero;
	actionButton.imageEdgeInsets = (UIEdgeInsets){ 0, -1, 0, 0 };
	actionButton.imageView.contentMode = UIViewContentModeTopLeft;

	[actionButton addTarget:self action:@selector(handleActionButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	
	return actionButton;

}

- (UIActivityIndicatorView *) activityIndicatorView {

	if (activityIndicatorView)
		return activityIndicatorView;
	
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	activityIndicatorView.hidesWhenStopped = NO;
	
	[activityIndicatorView startAnimating];
	
	return activityIndicatorView;

}

- (void) handleActionButtonTap:(UIButton *)sender {

	[self.interface performAutomaticRemoteUpdatesNow];
	[self updateStateAnimated:YES];

#if 0 //Mute
	[self playRefreshStartSoundEffect];
	[self setRequiresSoundEffectOnSessionEnd:YES];
#endif

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	[self updateStateAnimated:YES];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	[self updateStateAnimated:NO];

}

- (void) updateStateAnimated:(BOOL)animate {

	void (^animations)() = ^ {

		if (self.interface.performingAutomaticRemoteUpdates) {
		
			self.currentlyBusy = YES;
		
			self.actionButton.alpha = 0.0f;
			self.actionButton.transform = CGAffineTransformConcat(
				CGAffineTransformMakeRotation(30 * (2 * M_PI / 360.0f)),
				CGAffineTransformMakeScale(0.1, 0.1));
			self.activityIndicatorView.alpha = 1;
		
		} else {

			self.currentlyBusy = NO;
			
			self.actionButton.alpha = 1.0f;
			self.actionButton.transform = CGAffineTransformIdentity;
			self.activityIndicatorView.alpha = 0;
			
		}
	
	};
	
	if (animate) {
	
		[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:animations completion:nil];
	
	} else {
	
		animations();
	
	}

}

- (void) setCurrentlyBusy:(BOOL)newCurrentlyBusy {

	if (currentlyBusy == newCurrentlyBusy)
		return;
	
	if (currentlyBusy && !newCurrentlyBusy)
	if (requiresSoundEffectOnSessionEnd) {
		self.requiresSoundEffectOnSessionEnd = NO;
		[self playRefreshEndSoundEffect];
	}
	
	currentlyBusy = newCurrentlyBusy;

}

- (FIFactory *) soundFactory {

	if (soundFactory)
		return soundFactory;
		
	soundFactory = [[FIFactory alloc] init];
	return soundFactory;

}

- (FISoundEngine *) soundEngine {

	if (soundEngine)
		return soundEngine;
	
	soundEngine = [[self.soundFactory buildSoundEngine] retain];
	[soundEngine activateAudioSessionWithCategory:AVAudioSessionCategoryAmbient];
	[soundEngine openAudioDevice];
		
	return soundEngine;

}

- (FISound *) refreshStartSound {

	if (refreshStartSound)
		return refreshStartSound;
	
	refreshStartSound = [[self.soundFactory loadSoundNamed:@"WASoundRefreshStarted.caf"] retain];
	return refreshStartSound;

}

- (FISound *) refreshEndSound {

	if (refreshEndSound)
		return refreshEndSound;
	
	refreshEndSound = [[self.soundFactory loadSoundNamed:@"WASoundRefreshEnded.caf"] retain];	
	return refreshEndSound;

}

- (void) playRefreshStartSoundEffect {

	[self soundEngine];
	[self.refreshStartSound play];
	
}

- (void) playRefreshEndSoundEffect {

	[self soundEngine];
	[self.refreshEndSound play];
	
}

@end
