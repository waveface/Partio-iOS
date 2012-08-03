//
//  WAArticleStyle.m
//  wammer
//
//  Created by Evadne Wu on 6/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleStyle.h"
#import "WADataStore.h"

WAArticleStyle WASuggestedStyleForArticle (WAArticle *anArticle) {
	
	if (!anArticle)
		return WAPlaintextArticleStyle;
		
	for (WAPreview *aPreview in anArticle.previews)
		if (aPreview.text || aPreview.url || aPreview.graphElement.text || aPreview.graphElement.title)
			return WAPreviewArticleStyle;
			
	for (WAFile *aFile in anArticle.files)
		if (aFile.resourceURL || aFile.resourceFilePath || aFile.thumbnailURL || aFile.thumbnailFilePath || aFile.largeThumbnailURL || aFile.largeThumbnailFilePath || aFile.smallThumbnailURL || aFile.smallThumbnailFilePath || aFile.assetURL || [aFile.remoteResourceType isEqualToString:@"image"])
			return WAPhotosArticleStyle;
	
	return WAPlaintextArticleStyle;

}
