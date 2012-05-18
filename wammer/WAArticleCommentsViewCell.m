//
//  WAArticleCommentsViewCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticleCommentsViewCell.h"


@interface WAArticleCommentsViewCell ()
@property (nonatomic, readwrite, assign) WAArticleCommentsViewCellStyle style;
@property (nonatomic, readwrite, copy) NSString *reuseIdentifier;
@end


@implementation WAArticleCommentsViewCell
@synthesize style;
@dynamic reuseIdentifier;
@synthesize avatarView, userNicknameLabel, contentTextLabel, dateOriginLabel, dateLabel, originLabel;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

	return [self initWithCommentsViewCellStyle:WAArticleCommentsViewCellStyleDefault reuseIdentifier:reuseIdentifier];

}

- (id) initWithCommentsViewCellStyle:(WAArticleCommentsViewCellStyle)aStyle reuseIdentifier:(NSString *)aReuseIdentifier {

	NSString *loadedNibName = nil;
	
	switch (aStyle) {
		case WAArticleCommentsViewCellStyleDefault: {
			loadedNibName = @"WAArticleCommentsViewCell-Default";
			break;
		}
		case WAArticleCommentsViewCellStyleImageStack: {
			loadedNibName = @"WAArticleCommentsViewCell-ImageStack";
			break;
		}
	}

	self = [[self class] cellFromNibNamed:loadedNibName instantiatingOwner:nil withOptions:nil];
	
	if (!self)
		return nil;
	
	self.style = aStyle;
	self.reuseIdentifier = aReuseIdentifier;
    
	self.avatarView.layer.cornerRadius = 7.0;
	self.avatarView.layer.masksToBounds = YES;
    
	return self;
	
}

@end





@implementation WAArticleCommentsViewCell (NibLoading)

+ (WAArticleCommentsViewCell *) cellFromNib {

	return [self cellFromNibNamed:NSStringFromClass([self class]) instantiatingOwner:nil withOptions:nil];

}

+ (WAArticleCommentsViewCell *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options {

	UINib *nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
	NSArray *loadedObjects = [nib instantiateWithOwner:nil options:nil];
	
	for (id loadedObject in loadedObjects)	
	if ([loadedObject isKindOfClass:[self class]])
		return loadedObject;
	
	return [[NSSet setWithArray:loadedObjects] anyObject];

}

@end
