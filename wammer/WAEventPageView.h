//
//  WAEventPageView.h
//  wammer
//
//  Created by kchiu on 13/1/22.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class WAArticle, WAEventDescriptionView;
@interface WAEventPageView : UIView <MKMapViewDelegate>

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imageViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *containerViews;

@property (nonatomic, strong) UIImage *blurredBackgroundImage;
@property (nonatomic, strong) WAArticle *representingArticle;
@property (nonatomic, strong) WAEventDescriptionView *descriptionView;

+ (WAEventPageView *)viewWithRepresentingArticle:(WAArticle *)article;

- (void)loadImages;
- (void)unloadImages;

@end
