//
//  WAArticleStyle.h
//  wammer
//
//  Created by Evadne Wu on 6/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WAArticle;

enum {

	WAFullScreenArticleStyle = 1 << 0,
	WACellArticleStyle = 1 << 1,
	
	WAPlaintextArticleStyle = 1 << 8,
	WAPhotosArticleStyle = 1 << 9,
	WAPreviewArticleStyle = 1 << 10,
	WADocumentArticleStyle = 1 << 11,
	
	WAFullScreenPlaintextArticleStyle = WAPlaintextArticleStyle|WAFullScreenArticleStyle,
	WAFullScreenImageStackArticleStyle = WAPhotosArticleStyle|WAFullScreenArticleStyle,
	WAFullScreenPreviewArticleStyle = WAPreviewArticleStyle|WAFullScreenArticleStyle,
  WAFullScreenDocumentArticleStyle = WADocumentArticleStyle|WAFullScreenArticleStyle,
  
	WACellPlaintextArticleStyle = WAPlaintextArticleStyle|WACellArticleStyle,
	WACellSingleImageArticleStyle = WAPhotosArticleStyle|WACellArticleStyle,
	WACellPreviewArticleStyle = WAPreviewArticleStyle|WACellArticleStyle,
  WACellDocumentArticleStyle = WADocumentArticleStyle|WACellArticleStyle,
		
}; typedef NSInteger WAArticleStyle;

extern WAArticleStyle WASuggestedStyleForArticle (WAArticle *article);
