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


@interface WAPostViewCellPhone () <IRTableViewCellPrototype>

@end


@implementation WAPostViewCellPhone

@synthesize backgroundImageView;
@synthesize photoImageViews;
@synthesize monthLabel, dayLabel;
@synthesize extraInfoLabel;
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel;
@synthesize previewBadge, previewImageView, previewTitleLabel, previewProviderLabel, previewImageBackground;

+ (NSSet *) encodedObjectKeyPaths {

	return [NSSet setWithObjects:@"backgroundImageView", @"monthLabel", @"dayLabel", @"extraInfoLabel", @"contentTextView", @"commentLabel", @"avatarView", @"userNicknameLabel", @"contentDescriptionLabel", @"dateOriginLabel", @"dateLabel", @"originLabel", @"previewBadge", @"previewImageView", @"previewTitleLabel", @"previewProviderLabel", @"previewImageBackground", @"photoImageViews", nil];

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
	
	} else if ([identifier isEqualToString:@"PostCell-TextOnly"]) {
	
		UINib *nib = [UINib nibWithNibName:@"WAPostViewCellPhone-Default" bundle:[NSBundle mainBundle]];
		NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
		
		cell = [loadedObjects objectAtIndex:0];
	
	}
	
	cell.selectedBackgroundView = ((^ {
	
		UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
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
			
				if (anyPreview.graphElement.primaryImage)
					return @"PostCell-WebLink";
			
				return @"PostCell-WebLinkNoPhoto";
			
			}
			
			return @"PostCell-TextOnly";
		
		}
		
		case 1:
			return @"PostCell-Stacked-1-Photo";
		
		case 2:
			return @"PostCell-Stacked-2-Photo";
		
		default:
			return @"PostCell-Stacked-3-Photo";
	
	}
	
}

- (CGFloat) heightForRowRepresentingObject:(WAArticle *)object inTableView:(UITableView *)tableView {

//	BOOL isWebPost = !![object.previews count];
//	BOOL isPhotoPost = !![object.files count];
//	if (isWebPost)
//		return 158;
	
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
	
	CGFloat answer = roundf(MIN(prototype.commentLabel.font.leading * 3, CGRectGetHeight(prototype.commentLabel.bounds)) + cellLabelHeightDelta);
	prototype.commentLabel.frame = oldLabelFrame;
	
	return MAX(answer, CGRectGetHeight(prototype.bounds));
	
}

- (void) setRepresentedObject:(id)representedObject {

	[super setRepresentedObject:representedObject];
	
	WAArticle *post = representedObject;
	NSParameterAssert([post isKindOfClass:[WAArticle class]]);

	BOOL postHasFiles = (BOOL)!![post.files count];
	BOOL postHasPreview = (BOOL)!![post.previews count];
	
	NSDate *postDate = post.presentationDate;
	NSString *relativeDateString = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:postDate];
	
	self.originLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS_FROM_DEVICE", @"iPhone Timeline"),
		relativeDateString,
		post.creationDeviceName
	];
	
	self.dateLabel.text = [relativeDateString lowercaseString];
	self.commentLabel.text = ([post.text length]>0)? post.text : @"My life is a tapestry for rich and royal you.";
	
	if (postHasPreview) {

		WAPreview *preview = [post.previews anyObject];
		
		self.extraInfoLabel.text = @"";
	 
		self.previewBadge.preview = preview;
		
		self.accessibilityLabel = @"Preview";
		self.accessibilityHint = preview.graphElement.title;
		self.accessibilityValue = preview.graphElement.text;
		
		UIImageView *piv = self.previewImageView;
		
		[piv irUnbind:@"image"];
		
		[piv irBind:@"image" toObject:preview keyPath:@"thumbnail" options:[NSDictionary dictionaryWithObjectsAndKeys:
		
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
		
			WAFile *file = (WAFile *)[displayedFiles objectAtIndex:idx];
			
			[iv irUnbind:@"image"];
			
			[iv irBind:@"image" toObject:file keyPath:@"smallestPresentableImage" options:[NSDictionary dictionaryWithObjectsAndKeys:
			
				(id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
			
			nil]];
			
		}];
		
		if ([post.files count] > 3) {
			
			self.extraInfoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS", @"Photo information in cell"), [post.files count]];
			
		}
	
		self.accessibilityLabel = @"Photo";
		
		NSString *photoInfo = NSLocalizedString(@"PHOTO_PLURAL", @"in iPhone timeline");
		if ( [post.files count]==1 )
			photoInfo = NSLocalizedString(@"PHOTO_SINGULAR", @"in iPhone timeline");
		self.accessibilityHint = [NSString stringWithFormat:photoInfo, [post.files count]];
		self.originLabel.text = [self.accessibilityHint stringByAppendingString:self.originLabel.text];
		
  } else {
		
		self.commentLabel.text = post.text;
		self.extraInfoLabel.text = @"";
	 
		self.accessibilityLabel = @"Text Post";
		self.accessibilityValue = post.text;
		
	}
		
	self.commentLabel.text = post.text;
	
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
	
	//	TBD: optimize if slow
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	dateFormatter.dateFormat = @"dd";
	self.dayLabel.text = [dateFormatter stringFromDate:postDate];
	
	dateFormatter.dateFormat = @"MMM";
	self.monthLabel.text = [[dateFormatter stringFromDate:postDate] uppercaseString];
	
	[self setNeedsLayout];
	
}

@end
