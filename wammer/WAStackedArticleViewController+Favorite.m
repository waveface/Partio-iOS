//
//  WAStackedArticleViewController+Favorite.m
//  wammer
//
//  Created by Evadne Wu on 6/28/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAStackedArticleViewController+Favorite.h"
#import "UIKit+IRAdditions.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

@implementation WAStackedArticleViewController (Favorite)

- (UIBarButtonItem *) newFavoriteToggleItem {

	UIUserInterfaceIdiom uiIdiom = [UIDevice currentDevice].userInterfaceIdiom;

	IRBarButtonItem *item = [[IRBarButtonItem alloc] initWithTitle:@"Mark Favorite" style:UIBarButtonItemStyleBordered target:nil action:nil];
	
	__weak WAStackedArticleViewController *wSelf = self;
	__weak UIBarButtonItem *wItem = item;
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button addTarget:self action:@selector(handleFavoriteToggle:) forControlEvents:UIControlEventTouchUpInside];
	
	UIView *buttonWrapper = [[UIView alloc] initWithFrame:CGRectZero];
	[buttonWrapper addSubview:button];
	item.customView = buttonWrapper;
	
	__weak UIButton *wButton = button;
	__weak UIView *wButtonWrapper = buttonWrapper;
	
	[wItem irBind:@"title" toObject:self keyPath:@"article.favorite" options:[NSDictionary dictionaryWithObjectsAndKeys:

		[^ (id fromValue, id toValue, NSString *changeKind) {
		
			BOOL articleMarkedFavorite = [toValue isEqual:(id)kCFBooleanTrue];
			
			UIImage *faveImage, *unfaveImage;
			CGFloat edgeDelta;
			
			switch (uiIdiom) {
				
				case UIUserInterfaceIdiomPad: {
					edgeDelta = 0.0f;
					faveImage = [UIImage imageNamed:@"HeartHighlight"];
					unfaveImage = [UIImage imageNamed:@"HeartNormal"];
					break;
				}
				
				case UIUserInterfaceIdiomPhone: {
					edgeDelta = 8.0f;
					faveImage = [UIImage imageNamed:@"Fav~iphone"];
					unfaveImage = [UIImage imageNamed:@"Unfav~iphone"];
					break;
				}
				
			}
			
			[wButton setImage:(articleMarkedFavorite ? faveImage : unfaveImage) forState:UIControlStateNormal];
			
			[wButton sizeToFit];
			
			CGSize buttonSize = wButton.frame.size;
			wButtonWrapper.frame = (CGRect){ wButtonWrapper.frame.origin, (CGSize){
				buttonSize.width - edgeDelta,
				buttonSize.height
			}};

			return nil;
			
		} copy], kIRBindingsValueTransformerBlock,
	
	nil]];
				
	item.block = ^ {
	
		[wSelf handleFavoriteToggle:wItem];
				
	};
	
	return item;

}

- (void) handleFavoriteToggle:(id)sender {

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	WADataStore * const ds = [WADataStore defaultStore];

	WAArticle *article = self.article;
	
	article.favorite = (NSNumber *)([article.favorite isEqual:(id)kCFBooleanTrue] ? kCFBooleanFalse : kCFBooleanTrue);
	article.modificationDate = [NSDate date];
	
	NSError *savingError = nil;
	if (![article.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	[ri beginPostponingDataRetrievalTimerFiring];
	
	[ds updateArticle:[[article objectID] URIRepresentation] withOptions:nil onSuccess:^{
		
		[ri endPostponingDataRetrievalTimerFiring];
		
	} onFailure:^(NSError *error) {
		
		[ri endPostponingDataRetrievalTimerFiring];
		
	}];

}

@end
