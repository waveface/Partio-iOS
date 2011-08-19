//
//  WACompositionViewPhotoCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/11/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAView.h"
#import "WACompositionViewPhotoCell.h"


@interface WACompositionViewPhotoCell ()
@property (nonatomic, readwrite, retain) UIView *imageContainer;
@property (nonatomic, readwrite, retain) UIButton *removeButton;
@end

@implementation WACompositionViewPhotoCell
@synthesize image, imageContainer, removeButton, onRemove;

+ (WACompositionViewPhotoCell *) cellRepresentingFile:(WAFile *)aFile reuseIdentifier:(NSString *)identifier {

	WACompositionViewPhotoCell *returnedCell = [[[self alloc] initWithFrame:(CGRect){ 0, 0, 128, 128 } reuseIdentifier:identifier] autorelease];
	
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
	
	self.imageContainer = [[[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.contentView.bounds, (UIEdgeInsets){ 8, 8, 8, 8 })] autorelease];
	self.imageContainer.layer.contentsGravity = kCAGravityResizeAspect;
	self.imageContainer.layer.minificationFilter = kCAFilterTrilinear;
	self.imageContainer.layer.shadowOffset = (CGSize){ 0, 1 };
	self.imageContainer.layer.shadowOpacity = 0.5f;
	self.imageContainer.layer.shadowRadius = 2.0f;
	[self.contentView addSubview:self.imageContainer];
	
	self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.removeButton addTarget:self action:@selector(handleRemove:) forControlEvents:UIControlEventTouchUpInside];
	[self.removeButton setImage:[UIImage imageNamed:@"WAButtonSpringBoardRemove"] forState:UIControlStateNormal];
	[self.removeButton sizeToFit];
	self.removeButton.frame = UIEdgeInsetsInsetRect(self.removeButton.frame, (UIEdgeInsets){ -16, -16, -16, -16 });
	self.removeButton.imageView.contentMode = UIViewContentModeCenter;
	[self.contentView addSubview:self.removeButton];
	
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
	[image release];
	image = [newImage retain];
	[self didChangeValueForKey:@"image"];
	
	self.imageContainer.layer.contents = (id)newImage.CGImage;
	self.removeButton.hidden = (BOOL)(!newImage);
	self.imageContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:IRCGSizeGetCenteredInRect(newImage.size, self.imageContainer.bounds, 0.0f, YES)].CGPath;
	
	CGRect imageRect = IRCGSizeGetCenteredInRect(newImage.size, self.imageContainer.frame, 0.0f, YES);
	self.removeButton.center = (CGPoint) {
		CGRectGetMinX(imageRect),
		CGRectGetMinY(imageRect)
	};

}

- (void) dealloc {

	[onRemove release];
	[imageContainer release];
	[image release];
	[removeButton release];
	[super dealloc];

}

@end
