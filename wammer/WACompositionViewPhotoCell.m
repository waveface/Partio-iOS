//
//  WACompositionViewPhotoCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAView.h"
#import "WACompositionViewPhotoCell.h"
#import "QuartzCore+IRAdditions.h"


@interface WACompositionViewPhotoCell ()
@property (nonatomic, readwrite, retain) UIView *imageContainer;
@property (nonatomic, readwrite, retain) UIButton *removeButton;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicator;
@end

@implementation WACompositionViewPhotoCell
@synthesize image, imageContainer, removeButton, onRemove;
@synthesize activityIndicator;
@synthesize canRemove;

+ (WACompositionViewPhotoCell *) cellRepresentingFile:(WAFile *)aFile reuseIdentifier:(NSString *)identifier {

	WACompositionViewPhotoCell *returnedCell = [[self alloc] initWithFrame:(CGRect){ 0, 0, 128, 128 } reuseIdentifier:identifier];
	
	return returnedCell;

}

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	UIView *buttonAnswer = [self.removeButton hitTest:[self convertPoint:point toView:self.removeButton] withEvent:event];
	if (buttonAnswer)
		return buttonAnswer;

	return [super hitTest:point withEvent:event];

}

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {

	self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
	if (!self)
		return nil;
	
	self.backgroundColor = nil;
	self.contentView.backgroundColor = nil;
	self.selectionStyle = AQGridViewCellSelectionStyleNone;
	self.contentView.layer.shouldRasterize = YES;
	self.contentView.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	self.contentView.clipsToBounds = NO;
	
	self.imageContainer = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.contentView.bounds, (UIEdgeInsets){ 8, 8, 8, 8 })];
	self.imageContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;//kCAGravityResizeAspect;
	self.imageContainer.layer.minificationFilter = kCAFilterTrilinear;
	self.imageContainer.layer.shadowOffset = (CGSize){ 0, 1 };
	self.imageContainer.layer.shadowOpacity = 0.5f;
	self.imageContainer.layer.shadowRadius = 2.0f;
	//	self.imageContainer.layer.masksToBounds = YES;
	[self.contentView addSubview:self.imageContainer];
	
	self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.removeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
	[self.removeButton addTarget:self action:@selector(handleRemove:) forControlEvents:UIControlEventTouchUpInside];
	[self.removeButton setImage:[UIImage imageNamed:@"WAButtonSpringBoardRemove"] forState:UIControlStateNormal];
	[self.removeButton sizeToFit];
	self.removeButton.frame = UIEdgeInsetsInsetRect(self.removeButton.frame, (UIEdgeInsets){ -16, -16, -16, -16 });
	self.removeButton.imageView.contentMode = UIViewContentModeCenter;
	[self.contentView addSubview:self.removeButton];
	
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	self.activityIndicator.center = (CGPoint){ CGRectGetMidX(self.imageContainer.bounds), CGRectGetMidY(self.imageContainer.bounds) };
	self.activityIndicator.frame = CGRectIntegral(self.activityIndicator.frame);
	[self.activityIndicator startAnimating];
	[self.imageContainer addSubview:self.activityIndicator];
	
	self.canRemove = YES;
	
	[self setNeedsLayout];
	
	return self;

}

- (IBAction) handleRemove:(id)sender {

	if (self.onRemove)
		self.onRemove();

}

- (void) setImage:(UIImage *)newImage {

	if (image == newImage)
		return;
	
	[self willChangeValueForKey:@"image"];
	image = newImage;
	[self didChangeValueForKey:@"image"];
	
	self.imageContainer.layer.contents = (id)newImage.CGImage;
	
	if (newImage) {
	
		CGRect imageRect = IRGravitize(self.imageContainer.frame, newImage.size, kCAGravityResizeAspect);
		self.removeButton.center = (CGPoint) {
			CGRectGetMinX(imageRect) + 8,
			CGRectGetMinY(imageRect) + 8
		};
	
	}
	
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	if (canRemove) {
		self.removeButton.alpha = 1;
		self.removeButton.enabled = YES;
	} else {
		self.removeButton.alpha = 0;
		self.removeButton.enabled = NO;
	}
	
	if (self.image) {

		self.removeButton.hidden = NO;
		self.activityIndicator.alpha = 0;
		self.imageContainer.backgroundColor = nil;
		self.imageContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:IRCGSizeGetCenteredInRect(self.image.size, self.imageContainer.bounds, 0.0f, YES)].CGPath;
	
	} else {
	
		self.removeButton.hidden = YES;
		self.activityIndicator.alpha = 1;
		self.imageContainer.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
		self.imageContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.imageContainer.bounds].CGPath;
	
	}

}

- (void) prepareForReuse {

	self.image = nil;

}

@end
