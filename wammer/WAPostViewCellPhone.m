//
//  WAArticleCommentsViewCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAPostViewCellPhone.h"


@interface WAPostViewCellPhone ()
@property (nonatomic, readwrite, assign) WAPostViewCellStyle postViewCellStyle;
@property (nonatomic, readwrite, copy) NSString *reuseIdentifier;
@end


@implementation WAPostViewCellPhone
@synthesize backgroundImageView;
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize commentBackground;
@synthesize postViewCellStyle;
@dynamic reuseIdentifier;
@synthesize imageStackView, avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel, previewBadge;

- (void) dealloc {
  
	[imageStackView release];
	[avatarView release];
	[userNicknameLabel release];
	[contentDescriptionLabel release];
	[dateOriginLabel release];
	[dateLabel release];
	[originLabel release];	
	[commentLabel release];
	[commentBackground release];
    [contentTextView release];
	[previewBadge release];
  [backgroundImageView release];
	[super dealloc];
	
}

- (id) initWithStyle:(UITableViewCellStyle)aStyle reuseIdentifier:(NSString *)reuseIdentifier {

	return [self initWithPostViewCellStyle:WAPostViewCellStyleDefault reuseIdentifier:reuseIdentifier];

}

- (id) initWithPostViewCellStyle:(WAPostViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier {

	NSString *loadedNibName = nil;
	
	switch (aStyle) {
		case WAPostViewCellStyleDefault:{
			loadedNibName = @"WAPostViewCellPhone-Default";
			break;
		}
    case WAPostViewCellStyleImageStack: {
			loadedNibName = @"WAPostViewCellPhone-ImageStack";
			break;
		}
    case WAPostViewCellStyleWebLink: {
      loadedNibName = @"WAPostViewCellPhone-WebLink";
    }
	}

	self = [[[self class] cellFromNibNamed:loadedNibName instantiatingOwner:nil withOptions:nil] retain];
	
	if (!self)
		return nil;
	
	self.postViewCellStyle = aStyle;
	self.reuseIdentifier = aReuseIdentifier;
    
  self.backgroundImageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPostBackground"]];
    
	self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.backgroundView.backgroundColor = [UIColor clearColor];
  	
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
	
	self.commentBackground.image = [self.commentBackground.image stretchableImageWithLeftCapWidth:24.0f topCapHeight:0];
	
    self.avatarView.layer.cornerRadius = 4.0;
	self.avatarView.layer.masksToBounds = YES;
	
	UIView *avatarWrapper = [[[UIView alloc] initWithFrame:self.avatarView.frame] autorelease];
	avatarWrapper.autoresizingMask = avatarWrapper.autoresizingMask;
	avatarWrapper.layer.shadowRadius = 1.0f;
	avatarWrapper.layer.shadowOffset = (CGSize){ 0, 1 };
	avatarWrapper.layer.shadowOpacity = 0.25f;
	[self.avatarView.superview addSubview:avatarWrapper];
	[avatarWrapper addSubview:self.avatarView];
	self.avatarView.frame = avatarWrapper.bounds;
  
	self.previewBadge.titleFont = [UIFont systemFontOfSize:14.0f];
	self.previewBadge.textFont = [UIFont systemFontOfSize:14.0f];
  
	return self;
	
}

- (void) prepareForReuse {

	[super prepareForReuse];
	[self.imageStackView setImages:nil asynchronously:NO withDecodingCompletion:nil];
    [self.imageView setImage:nil];
  
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
