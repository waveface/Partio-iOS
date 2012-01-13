//
//  WAStackView.h
//  wammer
//
//  Created by Evadne Wu on 12/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


@class WAStackView;
@protocol WAStackViewDelegate <NSObject>

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement;
- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView;

@end


@interface WAStackView : UIScrollView

@property (nonatomic, readwrite, assign) id <UIScrollViewDelegate, WAStackViewDelegate> delegate;	//	the aptly-named `delegate` is used by the scrollview

- (NSMutableArray *) mutableStackElements;

- (void) addStackElements:(NSSet *)objects;
- (void) addStackElementsObject:(UIView *)object;
- (void) removeStackElements:(NSSet *)objects;
- (void) removeStackElementsAtIndexes:(NSIndexSet *)indexes;
- (void) removeStackElementsObject:(UIView *)object;

@end
