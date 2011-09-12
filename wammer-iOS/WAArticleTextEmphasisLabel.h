//
//  WAArticleTextEmphasisLabel.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/16/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WAArticleTextEmphasisLabel : UIView

@property (nonatomic, readwrite, copy) NSString *text;
//	@property (nonatomic, readwrite, retain) IBOutlet UITextView *textView;
//	@property (nonatomic, readwrite, retain) IBOutlet UILabel *label;
@property (nonatomic, readwrite, retain) IBOutlet UIView *backgroundView;

@end
