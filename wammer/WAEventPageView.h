//
//  WAEventPageView.h
//  wammer
//
//  Created by kchiu on 13/1/22.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAArticle;
@interface WAEventPageView : UIView

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imageViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *containerViews;

+ (WAEventPageView *)viewWithRepresentingArticle:(WAArticle *)article;

@end
