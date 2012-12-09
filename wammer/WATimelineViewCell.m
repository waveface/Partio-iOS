//
//  WAPostViewCellPad.m
//  wammer
//
//  Created by Shen Steven on 11/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//


#import "WATimelineViewCell.h"
#import "WAArticle+WAAdditions.h"
#import "WAFile.h"
#import "IRLabel.h"
#import "WAEventViewController.h"
#import "WALocation.h"
#import "MKMapView+ZoomLevel.h"

@interface WATimelineViewCell ()

@property (nonatomic, strong) IBOutletCollection(UIImageView) NSArray *photoImageViews;
@property (nonatomic, readwrite, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, readwrite, weak) IBOutlet UIView *containerView;
@property (nonatomic, readwrite, weak) IBOutlet UIImageView *eventCardBGImageView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) UILabel *fileNoLabel;
@property (nonatomic, strong) UIImageView *typeImageView;

@property (nonatomic, strong) WAArticle *article;

@end

@implementation WATimelineViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) setRepresentedArticle:(WAArticle *)representedArticle {
	
	WAArticle *post = representedArticle;
	NSParameterAssert([post isKindOfClass:[WAArticle class]]);
	
	self.article = representedArticle;
	
	_representedArticle = representedArticle;
	
	BOOL const postHasFiles = (BOOL)!![post.files count];
	NSDate *postDate = post.presentationDate;

	if (postHasFiles) {
		self.accessibilityValue = post.text;
		
		NSArray *allFiles = [post.files array];
		NSArray *allPhotoImageViews = self.photoImageViews;
		NSUInteger numberOfFiles = [allFiles count];
		NSUInteger numberOfPhotoImageViews = [allPhotoImageViews count];
		
		self.accessibilityLabel = @"Photo";
		
		NSString *photoInfo = NSLocalizedString(@"PHOTO_PLURAL", @"in iPhone timeline");
		if ([post.files count] == 1)
			photoInfo = NSLocalizedString(@"PHOTO_SINGULAR", @"in iPhone timeline");
		
		self.accessibilityHint = [NSString stringWithFormat:photoInfo, [post.files count]];

		NSMutableArray *displayedFiles = [[allFiles subarrayWithRange:(NSRange){ 0, MIN(numberOfPhotoImageViews, numberOfFiles)}] mutableCopy];
		
		WAFile *coverFile = post.representingFile;
		if ([displayedFiles containsObject:coverFile]) {
			
			[displayedFiles removeObject:coverFile];
			[displayedFiles insertObject:coverFile atIndex:0];
			
		} else {
			
			[displayedFiles insertObject:coverFile atIndex:0];
			
			if ([displayedFiles count] > numberOfPhotoImageViews)
				[displayedFiles removeLastObject];
			
		}
		
		[allPhotoImageViews enumerateObjectsUsingBlock:^(UIImageView *iv, NSUInteger idx, BOOL *stop) {
			
			if ([displayedFiles count] < idx) {
				
				iv.image = nil;
				
				return;
				
			}
			
			WAFile *file = (WAFile *)[displayedFiles objectAtIndex:idx];
			
			
			[file irObserve:@"smallThumbnailImage"
							options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
							context:nil
						withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
							
							dispatch_async(dispatch_get_main_queue(), ^{
								
								iv.image = (UIImage*)toValue;
								
							});
							
						}];
			
		}];

	
	} else {
	
		if (post.location) {

			CLLocationCoordinate2D center = { post.location.latitude.floatValue, post.location.longitude.floatValue };
			NSUInteger zoomLevel = [post.location.zoomLevel unsignedIntegerValue];
			[self.mapView setCenterCoordinate:center zoomLevel:zoomLevel animated:NO];
			
		}
		
	}

	CGFloat oldCommentHeight = CGRectGetHeight(self.commentLabel.frame);
	
	self.commentLabel.attributedText = [WAEventViewController attributedDescriptionStringForEvent:self.article];
	[self.commentLabel sizeToFit];
	CGFloat newCommentHeight = CGRectGetHeight(self.commentLabel.frame);

	self.timeLabel.text = [[[self class] timeFormatter] stringFromDate:postDate];
	
	self.fileNoLabel = [[UILabel alloc] initWithFrame:(CGRect){CGPointZero, CGSizeZero}];
	self.fileNoLabel.text = [NSString stringWithFormat:@"%d", self.article.files.count];
	self.fileNoLabel.font = [UIFont fontWithName:@"Helvetica-Regular" size:14.0f];
	self.fileNoLabel.textColor = [UIColor lightGrayColor];
	[self.fileNoLabel sizeToFit];
	
	UIImage *icon = [[self class] photoEventImage];
	CGFloat spacing = 2.0f;
	CGFloat leftAlignX = CGRectGetWidth(self.containerView.frame) - CGRectGetWidth(self.fileNoLabel.frame) - spacing - icon.size.width;
	
	self.typeImageView = [[UIImageView alloc] initWithFrame:(CGRect){ (CGPoint){leftAlignX, 0},  icon.size }];
	
	if ([self.article.style isEqualToNumber:[NSNumber numberWithUnsignedInt:WAPostStyleURLHistory]])
		self.typeImageView.image = [[self class] linkEventImage];
	else
		self.typeImageView.image = [[self class] photoEventImage];
	
	self.fileNoLabel.frame = CGRectOffset(self.fileNoLabel.frame, leftAlignX + icon.size.width + spacing, 0);
	
	// clean cached stuff
	NSArray *subviews = [self.containerView subviews];
	[subviews enumerateObjectsUsingBlock:^(UIView *sub, NSUInteger idx, BOOL *stop) {
		[sub removeFromSuperview];
	}];
	
	[self.containerView addSubview:self.typeImageView];
	[self.containerView addSubview:self.fileNoLabel];

	CGFloat delta = newCommentHeight - oldCommentHeight;
	if (delta < 0) delta = 0;

	self.eventCardBGImageView.frame = (CGRect){
		self.eventCardBGImageView.frame.origin,
		(CGSize) {
			self.eventCardBGImageView.frame.size.width,
			self.eventCardBGImageView.frame.size.height + delta
		}
	};
	
	self.eventCardBGImageView.image = [[self class] eventCardBackgroundImage];
	
	self.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	[self setNeedsLayout];

}

+ (UIImage *) eventCardBackgroundImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [[UIImage imageNamed:@"EventCardBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];
	});
	
	return image;
	
}

+ (UIImage *) photoEventImage {
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [UIImage imageNamed:@"EventCameraIcon"];
	});
	
	return image;
}

+ (UIImage *) linkEventImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [UIImage imageNamed:@"EventLinkIcon"];
	});
	
	return image;
	
}

+ (UIImage *) docEventImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    image = [UIImage imageNamed:@"EventDocIcon"];
	});
	
	return image;
	
}



+ (NSDateFormatter *) monthFormatter {
	
	static dispatch_once_t onceToken;
	static NSDateFormatter *formatter;
	dispatch_once(&onceToken, ^{
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"MMM";
	});
	
	return formatter;
	
}

+ (NSDateFormatter *) dayFormatter {
	
	static dispatch_once_t onceToken;
	static NSDateFormatter *formatter;
	dispatch_once(&onceToken, ^{
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"dd";
	});
	
	return formatter;
	
}

+ (NSDateFormatter *) timeFormatter {
	
	static dispatch_once_t onceToken;
	static NSDateFormatter *formatter;
	dispatch_once(&onceToken, ^{
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterNoStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
	});
	
	return formatter;
	
}


@end
