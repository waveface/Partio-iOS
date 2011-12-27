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
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize postViewCellStyle;
@dynamic reuseIdentifier;
@synthesize imageStackView, avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel, previewBadge;
@synthesize dateLabelBackgroundView;

- (void) dealloc {
  
	[imageStackView release];
	[avatarView release];
	[userNicknameLabel release];
	[contentDescriptionLabel release];
	[dateOriginLabel release];
	[dateLabel release];
	[originLabel release];	
	[commentLabel release];
  [contentTextView release];
	[previewBadge release];
	[dateLabelBackgroundView release];
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
	  
	self.backgroundView = WAStandardPostCellBackgroundView();  	
	self.selectedBackgroundView = WAStandardPostCellSelectedBackgroundView();  
	
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
	
	self.dateLabel.backgroundColor = nil;
	self.dateLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	self.dateLabel.textColor = [UIColor colorWithRed:145.0/255.0 green:118.0/255.0 blue:58.0/255.0 alpha:1];
	self.dateLabel.shadowColor = [UIColor whiteColor];
	self.dateLabel.shadowOffset = (CGSize){ 0, 1 };
	
	self.dateLabelBackgroundView = [[[UIView alloc] initWithFrame:self.dateLabel.bounds] autorelease];
	self.dateLabelBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
	
	[self.dateLabelBackgroundView addSubview:((^ {
	
		UIView *actualView = [[[UIView alloc] initWithFrame:(CGRect){
			(CGPoint){ 0, -8 },
			(CGSize){
				CGRectGetWidth(self.dateLabelBackgroundView.bounds),
				36
			}
		}] autorelease];
		
		UIImage *dateBadgeBackdrop = [UIImage imageNamed:@"WADateBadgeBackdrop"];
		actualView.layer.contents = (id)dateBadgeBackdrop.CGImage;
		actualView.layer.contentsScale = dateBadgeBackdrop.scale;
		actualView.layer.contentsCenter = (CGRect){ 8.0f/18.0f, 12.0f/36.0f, 2.0f/18.0f, 12.0f/36.0f };
		actualView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		actualView.frame = UIEdgeInsetsInsetRect(actualView.frame, (UIEdgeInsets){ 0, -10, 0, -10 });
		
		return actualView;
		
	})())];
	
	[self.contentView insertSubview:self.dateLabelBackgroundView belowSubview:self.dateLabel];
  
	return self;
	
}

- (void) setSelected:(BOOL)selecte animated:(BOOL)animated {

  //  Default behavior is undesirable

}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {

  //  Default behavior is undesirable

  if (highlighted) {
  
    if (self.backgroundView)
    if (self.selectedBackgroundView) {

      self.selectedBackgroundView.frame = self.bounds;
      [self insertSubview:self.selectedBackgroundView aboveSubview:self.backgroundView];
    
    }
  
  } else {
  
    [self.selectedBackgroundView removeFromSuperview];
  
  }

}

- (void) layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect dateRect = self.dateLabel.frame;
	[self.dateLabel sizeToFit];
	self.dateLabel.frame = IRGravitize(dateRect, self.dateLabel.frame.size, kCAGravityTopRight);
	self.dateLabelBackgroundView.frame = self.dateLabel.frame;
	
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
