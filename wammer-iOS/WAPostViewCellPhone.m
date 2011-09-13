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
@synthesize contentTextView;
@synthesize commentLabel;
@synthesize commentBackground;
@synthesize postViewCellStyle;
@dynamic reuseIdentifier;
@synthesize imageStackView, avatarView, userNicknameLabel, contentDescriptionLabel, dateOriginLabel, dateLabel, originLabel;

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
    
	self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1];

	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];

	self.commentBackground.image = [self.commentBackground.image stretchableImageWithLeftCapWidth:24.0f topCapHeight:0];
	
//  self.contentTextLabel.layer.borderColor = [UIColor redColor].CGColor;
//  self.contentTextLabel.layer.borderWidth = 2.0;
//  self.commentBackground.layer.borderColor = [UIColor greenColor].CGColor;
//  self.commentBackground.layer.borderWidth = 2.0;
  
  self.avatarView.layer.cornerRadius = 7.0;
	self.avatarView.layer.masksToBounds = YES;
    
  // TODO: URLs are touchable but all other text should be touch through.
  self.contentTextView.contentInset = UIEdgeInsetsMake(-10,-8,0,0);
  self.contentTextView.textAlignment = UITextAlignmentLeft;
  
	return self;
	
}

- (void) setCommentCount:(NSUInteger)commentCount {
  if (commentCount==0) {
    self.commentBackground.hidden = YES;
    self.commentLabel.hidden = YES;
  } else {
    self.commentBackground.hidden = NO;
    self.commentLabel.hidden = NO;
    self.commentLabel.text = [NSString stringWithFormat:@"%lu comments", commentCount];
  }
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
