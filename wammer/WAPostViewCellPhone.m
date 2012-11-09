//
//  WAArticleCommentsViewCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAPostViewCellPhone.h"

#import "UIKit+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"

#import "WADefines.h"
#import "WAPreviewBadge.h"
#import "WARemoteInterface.h"
#import "WAArticle.h"
#import "WAEventViewController.h"


@interface WAPostViewCellPhone () <IRTableViewCellPrototype>

@property (nonatomic, strong) UILabel *fileNoLabel;
@property (nonatomic, strong) UIImageView *typeImageView;

@end


@implementation WAPostViewCellPhone

@synthesize backgroundImageView;
@synthesize photoImageViews;
@synthesize monthLabel, dayLabel, timeLabel;
@synthesize extraInfoLabel;
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize eventCardBGImageView;
@synthesize avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel;
@synthesize previewBadge, previewImageView, previewTitleLabel, previewProviderLabel, previewImageBackground;
@synthesize containerView;
@synthesize fileNoLabel, typeImageView;

+ (NSSet *) encodedObjectKeyPaths {

	return [NSSet setWithObjects:@"backgroundImageView", @"monthLabel", @"dayLabel", @"extraInfoLabel", @"contentTextView", @"commentLabel", @"avatarView", @"userNicknameLabel", @"contentDescriptionLabel", @"dateOriginLabel", @"dateLabel", @"originLabel", @"previewBadge", @"previewImageView", @"previewTitleLabel", @"previewProviderLabel", @"previewImageBackground", @"photoImageViews", @"timeLabel", @"eventCardBGImageView", @"containerView", nil];

}

+ (NSSet *) keyPathsForValuesAffectingArticle {

	return [NSSet setWithObjects:
		
		@"representedObject",
		
	nil];

}

- (WAArticle *) article {

	return (WAArticle *)self.representedObject;

}

+ (WAPostViewCellPhone *) newPrototypeForIdentifier:(NSString *)identifier {

	WAPostViewCellPhone *cell = nil;

	if ([identifier isEqualToString:@"PostCell-Stacked-1-Photo"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:0];
	
	} else if ([identifier isEqualToString:@"PostCell-Stacked-2-Photo"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:1];
	
	} else if ([identifier isEqualToString:@"PostCell-Stacked-3-Photo"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:2];
	
	} else if ([identifier isEqualToString:@"PostCell-WebLink"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-WebLink" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:0];
	
	} else if ([identifier isEqualToString:@"PostCell-WebLinkNoPhoto"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-WebLink" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:1];
	
	} else if ([identifier isEqualToString:@"PostCell-WebLinkOnly"]) {

		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-WebLinkOnly" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];

		cell = [loadedObjects objectAtIndex:0];

	} else if ([identifier isEqualToString:@"PostCell-WebLinkOnlyNoPhoto"]) {

		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-WebLinkOnly" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];

		cell = [loadedObjects objectAtIndex:1];

	} else if ([identifier isEqualToString:@"PostCell-TextOnly"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-Default" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:0];
	
	} else if ([identifier isEqualToString:@"PostCell-Stacked-1-PhotoOnly"]) {

		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageOnlyStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];

		cell = [loadedObjects objectAtIndex:0];

	} else if ([identifier isEqualToString:@"PostCell-Stacked-2-PhotoOnly"]) {

		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageOnlyStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];

		cell = [loadedObjects objectAtIndex:1];

	} else if ([identifier isEqualToString:@"PostCell-Stacked-3-PhotoOnly"]) {

		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-ImageOnlyStack" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];

		cell = [loadedObjects objectAtIndex:2];

	}
	
	cell.selectedBackgroundView = ((^ {
	
		UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor colorWithWhite:0.65 alpha:1];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		return view;
		
	})());
	
	cell.previewBadge.titleFont = [UIFont systemFontOfSize:14.0f];
	cell.previewBadge.textFont = [UIFont systemFontOfSize:14.0f];
	
	return cell;

}

+ (NSString *) identifierRepresentingObject:(WAArticle *)article {

	switch ([article.files count]) {
	
		case 0: {
		
			WAPreview *anyPreview = [article.previews anyObject];
			
			if (anyPreview.text || anyPreview.url || anyPreview.graphElement.text || anyPreview.graphElement.title) {
			
				if ([anyPreview.graphElement.representingImage.imageRemoteURL length] != 0) {
					if ([article.text length] > 0) {
						return @"PostCell-WebLink";
					}
					return @"PostCell-WebLinkOnly";
				} else {
					if ([article.text length] > 0) {
						return @"PostCell-WebLinkNoPhoto";
					}
					return @"PostCell-WebLinkOnlyNoPhoto";
				}
			
			}
			
			return @"PostCell-TextOnly";
		
		}
		
		case 1: {

				return @"PostCell-Stacked-1-Photo";

		}
		
		case 2: {

				return @"PostCell-Stacked-2-Photo";

		}
		
		default: {

				return @"PostCell-Stacked-3-Photo";

		}

	}
	
}

- (CGFloat) heightForRowRepresentingObject:(WAArticle *)object inTableView:(UITableView *)tableView {

	NSString *identifier = [[self class] identifierRepresentingObject:object];
	WAPostViewCellPhone *prototype = (WAPostViewCellPhone *)[[self class] prototypeForIdentifier:identifier];
	NSParameterAssert([prototype isKindOfClass:[WAPostViewCellPhone class]]);
	
	prototype.frame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(tableView.bounds),
			CGRectGetHeight(prototype.bounds)
		}
	};
	
	CGRect oldLabelFrame = prototype.commentLabel.frame;
	CGFloat cellLabelHeightDelta = CGRectGetHeight(prototype.bounds) - CGRectGetHeight(oldLabelFrame);
	
	prototype.commentLabel.frame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(prototype.commentLabel.bounds),
			0
		}
	};
	
	prototype.commentLabel.text = object.text;
	
	[prototype.commentLabel sizeToFit];
	
	CGFloat answer = roundf(MIN(prototype.commentLabel.font.lineHeight * 3, CGRectGetHeight(prototype.commentLabel.bounds)) + cellLabelHeightDelta);
	prototype.commentLabel.frame = oldLabelFrame;
	
	return MAX(answer, CGRectGetHeight(prototype.bounds));
	
}

- (void) setRepresentedObject:(id)representedObject {

	WAArticle *previousPost = self.representedObject;
	if (previousPost) {
		for (WAFile *file in previousPost.files) {
			[file irRemoveObserverBlocksForKeyPath:@"smallThumbnailImage"];
		}
		[previousPost irRemoveObserverBlocksForKeyPath:@"dirty"];
	}

	[super setRepresentedObject:representedObject];
	
	WAArticle *post = representedObject;
	NSParameterAssert([post isKindOfClass:[WAArticle class]]);
	
	BOOL const postHasFiles = (BOOL)!![post.files count];
	BOOL const postHasPreview = (BOOL)!![post.previews count];
	
	NSDate *postDate = post.presentationDate;
	NSString *deviceName = post.creationDeviceName;
	NSString *timeString = [[[self class] timeFormatter] stringFromDate:postDate];
	
	self.originLabel.text = [NSString stringWithFormat:NSLocalizedString(@"CREATE_TIME_FROM_DEVICE", @"iPhone Timeline"), timeString, deviceName];
	self.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:postDate] lowercaseString];

	CGFloat oldCommentHeight = CGRectGetHeight(self.commentLabel.frame);
	self.commentLabel.text = post.text;
	
	if (postHasPreview) {

		WAPreview *preview = [post.previews anyObject];
		
		self.extraInfoLabel.text = @"";
	 
		self.previewBadge.preview = preview;
		
		self.accessibilityLabel = @"Preview";
		self.accessibilityHint = preview.graphElement.title;
		self.accessibilityValue = preview.graphElement.text;
		
		UIImageView *piv = self.previewImageView;
		
		[piv irUnbind:@"image"];
		
		[piv irBind:@"image" toObject:preview keyPath:@"graphElement.representingImage.image" options:[NSDictionary dictionaryWithObjectsAndKeys:
		
			(id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
		
		nil]];
		
		self.previewTitleLabel.text = preview.graphElement.title;
		self.previewProviderLabel.text = preview.graphElement.providerDisplayName;
			
	} else if (postHasFiles) {

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

		__weak WAPostViewCellPhone *wSelf = self;

		void (^showSyncCompletedInCell)(void) = ^ {
			WAArticle *article = wSelf.representedObject;
			wSelf.originLabel.textColor = [UIColor lightGrayColor];
			wSelf.originLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS_CREATE_TIME_FROM_DEVICE", @"iPhone Timeline"), wSelf.accessibilityHint, [[[wSelf class] timeFormatter] stringFromDate:article.presentationDate], article.creationDeviceName];
		};

		void (^showSyncingStatusInCell)(void) = ^ {
			wSelf.originLabel.textColor = [UIColor colorWithRed:0x6c/255.0 green:0xbc/255.0 blue:0xd3/255.0 alpha:1.0];
			wSelf.originLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DOWNLOADING_PHOTOS", @"Downloading Status on iPhone Timeline")];
		};

		void (^showSyncingInterruptedInCell)(void) = ^ {
			wSelf.originLabel.textColor = [UIColor colorWithRed:0x6c/255.0 green:0xbc/255.0 blue:0xd3/255.0 alpha:1.0];
			wSelf.originLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UNABLE_TO_DOWNLOADING_PHOTOS", @"Downloading Status on iPhone Timeline")];
		};

		if ([self.article.dirty isEqualToNumber:(id)kCFBooleanFalse]) {

			showSyncCompletedInCell();

		} else {

			[self.representedObject irObserve:@"dirty" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
				if ([self.article.dirty isEqualToNumber:(id)kCFBooleanFalse]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						showSyncCompletedInCell();
					});
				}
			}];

			if ([[WARemoteInterface sharedInterface] hasReachableCloud]) {
				showSyncingStatusInCell();
			} else {
				showSyncingInterruptedInCell();
			}
		}

		[[WARemoteInterface sharedInterface] irObserve:@"networkState" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
			if ([self.article.dirty isEqualToNumber:(id)kCFBooleanFalse]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					showSyncCompletedInCell();
				});
			} else {
				if ([[WARemoteInterface sharedInterface] hasReachableCloud]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						showSyncingStatusInCell();
					});
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						showSyncingInterruptedInCell();
					});
				}
			}
		}];

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
		
		if ([post.files count] > 3) {
			
			self.extraInfoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS", @"Photo information in cell"), [post.files count]];
			
		}
		
  } else {
		
		self.commentLabel.text = post.text;
		self.extraInfoLabel.text = @"";
	 
		self.accessibilityLabel = @"Text Post";
		self.accessibilityValue = post.text;
		
	}
		
	self.commentLabel.attributedText = [WAEventViewController attributedDescriptionStringForEvent:self.article];
//	self.commentLabel.text = post.text;
	
	[self.commentLabel sizeToFit];
	CGFloat newCommentHeight = CGRectGetHeight(self.commentLabel.frame);
	
	UIColor *textColor;
	UIColor *shadowColor;

	if ([post.favorite isEqual:(id)kCFBooleanTrue]) {
		
		self.backgroundImageView.image = [UIImage imageNamed:@"tagFavorite"];
		textColor = [UIColor whiteColor];
		shadowColor = [UIColor colorWithHue:155/360 saturation:0.0 brightness:0.8 alpha:1.0];
		
	} else {
		
		self.backgroundImageView.image = [UIImage imageNamed:@"tagDefault"];
		textColor = [UIColor colorWithHue:111/360 saturation:0.0 brightness:0.56 alpha:1.0];
		shadowColor = [UIColor colorWithHue:111/360 saturation:0.0 brightness:1.0 alpha:1.0];
		
	} 
	
	self.dayLabel.textColor = textColor;
	self.dayLabel.shadowColor = shadowColor;
	
	self.monthLabel.textColor = textColor;
	self.monthLabel.shadowColor = shadowColor;
	
	self.timeLabel.textColor = textColor;
	self.timeLabel.shadowColor = shadowColor;
	
	self.dayLabel.text = [[[self class] dayFormatter] stringFromDate:postDate];
	self.monthLabel.text = [[[[self class] monthFormatter] stringFromDate:postDate] uppercaseString];
	
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
	
	self.eventCardBGImageView.image = [[UIImage imageNamed:@"EventCardBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];

	[self setNeedsLayout];
	
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

- (void) setActive:(BOOL)active animated:(BOOL)animated {

	CGFloat alpha = active ? 0.65f : 1.0f;
	UIColor *backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
	
	for (UIImageView *iv in self.photoImageViews) {
		iv.alpha = alpha;
		iv.backgroundColor = backgroundColor;
	}
	
	self.previewImageView.alpha = alpha;
	self.previewImageView.backgroundColor = backgroundColor;

}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {

	[super setHighlighted:highlighted animated:animated];
	
	[self setActive:(self.highlighted || self.selected) animated:animated];

}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];
	
	[self setActive:(self.highlighted || self.selected) animated:animated];

}

@end
