//
//  WAArticleCommentsViewCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAPostViewCellPhone.h"
#import "QuartzCore+IRAdditions.h"
#import "WADefines.h"


@interface WAPostViewCellPhone ()
@property (nonatomic, readwrite, assign) WAPostViewCellStyle postViewCellStyle;
@property (nonatomic, readwrite, copy) NSString *reuseIdentifier;
@property (nonatomic, readwrite, retain) UIView *dateLabelBackgroundView;
@end


@implementation WAPostViewCellPhone

@synthesize backgroundImageView;
@synthesize dayLabel;
@synthesize monthLabel;

@synthesize extraInfoLabel;
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize postViewCellStyle;
@dynamic reuseIdentifier;
@synthesize imageStackView, avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel, previewBadge;
@synthesize dateLabelBackgroundView;

@synthesize previewImageView;
@synthesize previewTitleLabel;
@synthesize previewProviderLabel;
@synthesize previewImageBackground;
@synthesize post;

- (id) initWithStyle:(UITableViewCellStyle)aStyle reuseIdentifier:(NSString *)reuseIdentifier {

	return [self initWithPostViewCellStyle:WAPostViewCellStyleDefault reuseIdentifier:reuseIdentifier];

}

- (id) initWithPostViewCellStyle:(WAPostViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier {

	NSString *loadedNibName = nil;
	
	switch (aStyle) {
		case WAPostViewCellStyleDefault:{
			loadedNibName = @"WAPostViewCellPhone-Default";
			self = [[self class] cellFromNibNamed:loadedNibName instantiatingOwner:nil withOptions:nil];
			break;
		}
    case WAPostViewCellStyleImageStack: {
			loadedNibName = @"WAPostViewCellPhone-ImageStack";
			self = [[self class] cellFromNibNamed:loadedNibName instantiatingOwner:nil withOptions:nil];
			break;
		}
    case WAPostViewCellStyleWebLink: 
		case WAPostViewCellStyleWebLinkWithoutPhoto:{
      loadedNibName = @"WAPostViewCellPhone-WebLink";
			UINib *nib = [UINib nibWithNibName:loadedNibName bundle:[NSBundle mainBundle]];
			
			NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
			
			id loadedObject = [loadedObjects objectAtIndex:(aStyle-WAPostViewCellStyleWebLink)];
			self = (WAPostViewCellPhone *)loadedObject;
    }
	}
	
	if (!self)
		return nil;
	
	self.postViewCellStyle = aStyle;
	self.reuseIdentifier = aReuseIdentifier;
	  
	self.selectedBackgroundView = ((^ {
	
		UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		return view;
		
	})());
	
	self.previewBadge.titleFont = [UIFont systemFontOfSize:14.0f];
	self.previewBadge.textFont = [UIFont systemFontOfSize:14.0f];
	
	return self;
	
}

@end





@implementation WAPostViewCellPhone (NibLoading)

+ (WAPostViewCellPhone *) cellFromNib {

	return [self cellFromNibNamed:NSStringFromClass([self class]) instantiatingOwner:nil withOptions:nil];

}

+ (WAPostViewCellPhone *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options {

	UINib *nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
	NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
	
	for (id loadedObject in loadedObjects)	
	if ([loadedObject isKindOfClass:[self class]])
		return loadedObject;
	
	return [[NSSet setWithArray:loadedObjects] anyObject];

}
@end
