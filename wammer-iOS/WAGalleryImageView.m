//
//  WAGalleryImageView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/5/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAGalleryImageView.h"


@interface WAGalleryImageView ()
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, readwrite, retain) UIImageView *imageView;
@end


@implementation WAGalleryImageView
@synthesize activityIndicator, imageView;

+ (WAGalleryImageView *) viewForImage:(UIImage *)image {

	WAGalleryImageView *returnedView = [[[self alloc] init] autorelease];
	returnedView.image = image;
	return returnedView;

}

- (void) waInit {

	self.imageView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
	self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	[self addSubview:self.imageView];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
	self.activityIndicator.hidesWhenStopped = NO;
	[self.activityIndicator startAnimating];
	[self addSubview:self.activityIndicator];

}

- (void) setImage:(UIImage *)newImage {

	if (self.imageView.image == newImage)
		return;

	[self willChangeValueForKey:@"image"];
	self.imageView.image = newImage;
	self.activityIndicator.hidden = !!(newImage);
	[self didChangeValueForKey:@"image"];

}

- (UIImage *) image {

	return self.imageView.image;

}





- (id) initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

- (id) initWithCoder:(NSCoder *)aDecoder {
	
	self = [super initWithCoder:aDecoder];
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

@end
