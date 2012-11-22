//
//  WACalendarPickerByTypeViewController.h
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Kal.h"

@interface WACalendarPickerByTypeViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchRequestsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSDate *minDate;
@property (strong, nonatomic) NSDate *maxDate;
@property (strong, nonatomic) NSDate *selectedDate;

@property (weak, nonatomic) IBOutlet KalViewController *datePicker;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

- (IBAction) handleCancel:(UIButton *)sender;
- (IBAction) handleDone:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIView *backdropView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (void) runPresentingAnimationWithCompletion:(void(^)(void))callback;
- (void) runDismissingAnimationWithCompletion:(void(^)(void))callback;

+ (id) controllerWithCompletion:(void(^)(NSDate *))callback;

@end
