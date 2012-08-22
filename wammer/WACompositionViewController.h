//
//  WACompositionViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class IRImagePickerController, IRAction, WAArticle, IRTextAttributor;

@interface WACompositionViewController : UIViewController

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock;

@property (nonatomic, readwrite, retain) IBOutlet UIView *containerView;
@property (nonatomic, readwrite, retain) IBOutlet UITextView *contentTextView;

@property (nonatomic, readonly, retain) IRTextAttributor *textAttributor;
@property (nonatomic, readonly, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, retain) WAArticle *article;
@property (nonatomic, readwrite, assign) BOOL usesTransparentBackground;

@property (nonatomic, readonly, strong) NSOperationQueue *queue;

- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds;

@end


@interface WACompositionViewController (SubclassResponsibility)

- (void) handleFilesChangeKind:(NSKeyValueChange)kind oldValue:(id)oldValue newValue:(id)newValue indices:(NSIndexSet *)indices isPrior:(BOOL)isPrior;

- (void) handlePreviewsChangeKind:(NSKeyValueChange)kind oldValue:(id)oldValue newValue:(id)newValue indices:(NSIndexSet *)indices isPrior:(BOOL)isPrior;

- (void) handleCurrentTextChangedFrom:(NSString *)fromValue to:(NSString *)toValue changeKind:(NSKeyValueChange)changeKind;

@end


#import "WACompositionViewController+CustomUI.h"
#import "WACompositionViewController+ImageHandling.h"
