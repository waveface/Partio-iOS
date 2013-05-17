//
//  WAEventTitleInputView.m
//  wammer
//
//  Created by Shen Steven on 5/17/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAEventTitleInputView.h"

@interface WAEventTitleInputView () <UITextFieldDelegate>
@property (nonatomic, assign) BOOL keyboardShown;
@property (nonatomic, strong) NSString *titleText;
@end

@implementation WAEventTitleInputView {
  CGRect origFrame;
}

+ (id) viewFromNib {
  
  return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject isKindOfClass:self];
  }]] lastObject];
  
}

- (void) awakeFromNib {

  self.keyboardShown = NO;
  if (isPhone()) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardFrameChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
  }
  
  [self setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  self.backgroundColor = [UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1];
}

- (void) dealloc {
  if (isPhone()) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  }
}


- (void)handleKeyboardWasShown:(NSNotification *)aNotification {
  if (self.keyboardShown) {
    return;
  }
  
  self.keyboardShown = YES;
  CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

  CGRect newFrame = self.frame;
  origFrame = newFrame;
  newFrame.origin.y -= kbSize.height;
  
  __weak WAEventTitleInputView *wSelf = self;
  [UIView animateWithDuration:0.1 animations:^{
    wSelf.frame = newFrame;
  }];

  return;

}

- (void)handleKeyboardFrameChange:(NSNotification*)aNotification {
  if (!self.keyboardShown)
    return;
  
  CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
  CGRect newFrame = self.frame;
  newFrame.origin.y = origFrame.origin.y - kbSize.height;
  
  self.frame = newFrame;
  
}

- (void)handleKeyboardWillBeHidden:(NSNotification *)aNotification {
  self.keyboardShown = NO;
  
  __weak WAEventTitleInputView *wSelf = self;
  [UIView animateWithDuration:0.1 animations:^{
    wSelf.frame = origFrame;
  }];
  return;
  
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
  self.titleText = textField.text;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
  if (self.onTitleChange) {
    if (![self.titleText isEqualToString:textField.text])
      self.onTitleChange(textField.text);
  }
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {

  return YES;
  
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {

  [textField resignFirstResponder];
  return YES;
  
}
@end
