//
//  WACompositionViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class IRImagePickerController, IRAction, WAArticle, IRTextAttributor;

@interface WACompositionViewController : UIViewController

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock;

@property (nonatomic, readwrite, retain) IBOutlet UIView *containerView;
- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds;

@property (nonatomic, readwrite, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, readonly, retain) IRTextAttributor *textAttributor;

@property (nonatomic, readwrite, assign) BOOL usesTransparentBackground;

@property (nonatomic, readonly, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, retain) WAArticle *article;

@end


@interface WACompositionViewController (SubclassResponsibility)

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSKeyValueChange)changeKind;
- (void) handleCurrentArticlePreviewsChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSKeyValueChange)changeKind;
- (void) handleCurrentTextChangedFrom:(NSString *)fromValue to:(NSString *)toValue changeKind:(NSKeyValueChange)changeKind;

@end


#import "WACompositionViewController+CustomUI.h"
#import "WACompositionViewController+ImageHandling.h"
