//
//  WAArticleTextEmphasisLabel.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/16/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticleTextEmphasisLabel.h"


@interface WAArticleTextEmphasisLabel ()

- (void) waInitialize;

@end


@implementation WAArticleTextEmphasisLabel
@synthesize textView, label, backgroundView;

- (id) initWithFrame:(CGRect)aFrame {

	self = [super initWithFrame:aFrame];
	if (!self)
		return nil;
		
	[self waInitialize];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self waInitialize];

}

- (void) waInitialize {

	self.textView = [[[UITextView alloc] initWithFrame:self.bounds] autorelease];
	self.textView.editable = NO;
	self.textView.scrollEnabled = NO;
	self.textView.contentInset = UIEdgeInsetsZero;
	self.textView.dataDetectorTypes = UIDataDetectorTypeLink;
	
	self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.textView.font = [UIFont systemFontOfSize:16.0f];
	self.textView.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
	self.textView.opaque = NO;
	self.textView.backgroundColor = nil;
	
	self.label = [[[UILabel alloc] initWithFrame:self.bounds] autorelease];	
	self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.label.font = [UIFont systemFontOfSize:16.0f];
	self.label.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
	self.label.numberOfLines = 0;
	self.label.lineBreakMode = UILineBreakModeWordWrap;
	self.label.opaque = NO;
	self.label.backgroundColor = nil;
	
	[self addSubview:self.label];
	[self addSubview:self.textView];
	
}

- (void) setBackgroundView:(UIView *)newBackgroundView {

	[backgroundView removeFromSuperview];
	[backgroundView release];
	backgroundView = [newBackgroundView retain];
	
	[self insertSubview:newBackgroundView atIndex:0];
	backgroundView.frame = self.bounds;
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

}

- (CGSize) sizeThatFits:(CGSize)size {

	if (self.label.hidden)
		return [self.textView sizeThatFits:size];
	else
		return [self.label sizeThatFits:size];

}

- (void) dealloc {

	[label release];
	[textView release];
	[backgroundView release];
	[super dealloc];

}

@end
