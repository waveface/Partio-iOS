//
//  WAArticleTextEmphasisLabel.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/16/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticleTextEmphasisLabel.h"
#import "IRLabel.h"


@interface WAArticleTextEmphasisLabel () <UIWebViewDelegate>

@property (nonatomic, readwrite, retain) IBOutlet UITextView *textView;
@property (nonatomic, readwrite, retain) IBOutlet IRLabel *label;

- (void) waInitialize;

@end


@implementation WAArticleTextEmphasisLabel
@synthesize textView, label, backgroundView, font;

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

	self.font = [UIFont systemFontOfSize:20.0f];
		
	self.label = [[[IRLabel alloc] initWithFrame:self.bounds] autorelease];	
	self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.label.font = self.font;
	self.label.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
	self.label.numberOfLines = 0;
	self.label.lineBreakMode = UILineBreakModeTailTruncation;
	self.label.opaque = NO;
	self.label.backgroundColor = nil;
	self.label.userInteractionEnabled = YES;
	[self addSubview:self.label];
	
}

- (void) setBackgroundView:(UIView *)newBackgroundView {

	[backgroundView removeFromSuperview];
	[backgroundView release];
	backgroundView = [newBackgroundView retain];
	
	[self insertSubview:newBackgroundView atIndex:0];
	backgroundView.frame = self.bounds;
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

}

- (void) setText:(NSString *)text {

	IRLabel *capturedLabel = self.label;
	NSAttributedString *attributedText = [self.label attributedStringForString:text];
	capturedLabel.attributedText = attributedText;
	
	if (!text || ![text length])
		return;
	
  NSString *kThreadOwnDataDetector = [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@_threadOwnedDataDetector", NSStringFromSelector(_cmd)];

	dispatch_async(dispatch_get_global_queue(0, 0), ^ {
  
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
		NSDataDetector *sharedDataDetector = [threadDictionary objectForKey:kThreadOwnDataDetector];
    if (!sharedDataDetector) {
      sharedDataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
      [threadDictionary setObject:sharedDataDetector forKey:kThreadOwnDataDetector];
    }
		
		__block BOOL hasLinks = NO;
		
		NSMutableAttributedString *linkedAttributedText = [[attributedText mutableCopy] autorelease];		
		
		[linkedAttributedText beginEditing];
		
		[sharedDataDetector enumerateMatchesInString:text options:0 range:(NSRange){ 0, [text length] } usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		
			hasLinks = YES;
		
			[linkedAttributedText addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
				(id)[UIColor colorWithRed:0 green:0 blue:0.5 alpha:1].CGColor, kCTForegroundColorAttributeName,
				result.URL, kIRTextLinkAttribute,
			nil] range:result.range];
			
		}];
		
		[linkedAttributedText endEditing];
		
		if (!hasLinks)
			return;
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if ([capturedLabel.attributedText isEqualToAttributedString:attributedText])
				capturedLabel.attributedText = linkedAttributedText;
		
		});

	});

}

- (NSString *) text {

	return (NSString *)self.label.text;

}

- (CGSize) sizeThatFits:(CGSize)size {

	return [self.label sizeThatFits:size];

}

- (void) dealloc {

	[font release];
	[label release];
	[backgroundView release];
	[super dealloc];

}

@end
