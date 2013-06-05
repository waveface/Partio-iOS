//
//  WAPhotoGalleryCell.m
//  wammer
//
//  Created by Shen Steven on 4/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoGalleryCell.h"
@interface WAPhotoGalleryCell ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation WAPhotoGalleryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
  self.imageView.layer.cornerRadius = 5.0f;
  self.creatorNameLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
  self.avatarView.layer.cornerRadius = 5.0f;
  [self.activityIndicatorView startAnimating];
}

- (void) setImage:(UIImage *)image {
  
  [self setImage:image animated:NO];
  
}

- (void) setImage:(UIImage *)newImage animated:(BOOL)animated {

  NSTimeInterval duration = (animated ? 0.3f : 0.0f);
  NSTimeInterval delay = 0.0f;
  UIViewAnimationOptions options = UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState;
  
  self.activityIndicatorView.hidden = !!newImage;
  
  [UIView animateWithDuration:duration delay:delay options:options animations:^{
	
    [self.imageView setImage:newImage];
    
  } completion:nil];

}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
