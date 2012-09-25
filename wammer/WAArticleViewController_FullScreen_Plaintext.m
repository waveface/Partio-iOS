//
//  WAArticleViewController_Plaintext.m
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController_FullScreen_Plaintext.h"
#import "WAArticleTextStackElement.h"
#import "WAArticleTextStackCell.h"

@implementation WAArticleViewController_FullScreen_Plaintext

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(IRStackView *)aStackView {
	
	if ((anElement == self.textStackCell) || [self.textStackCell isDescendantOfView:anElement]) {
		
		CGSize elementAnswer = [anElement sizeThatFits:(CGSize){
			CGRectGetWidth(aStackView.bounds),
			0
		}];
		
		CGFloat preferredHeight = MAX(roundf(elementAnswer.height), self.stackView.bounds.size.height);
		return (CGSize){
			CGRectGetWidth(aStackView.bounds),
			preferredHeight
		};

	}
		
	return [super sizeThatFitsElement:anElement inStackView:aStackView];
		
}


@end
