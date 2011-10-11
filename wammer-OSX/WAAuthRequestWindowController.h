//
//  WAAuthRequestWindowController.h
//  wammer-OSX
//
//  Created by Evadne Wu on 10/10/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WAAuthRequestWindowController;
@protocol WAAuthRequestWindowControllerDelegate <NSObject>

- (void) authRequestController:(WAAuthRequestWindowController *)controller didRequestAuthenticationForUserName:(NSString 
*)proposedUsername password:(NSString *)proposedPassword withCallback:(void(^)(BOOL wasSuccessful))aCallback;

@end

@interface WAAuthRequestWindowController : NSWindowController <NSTextFieldDelegate>

@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;
@property (assign) IBOutlet NSProgressIndicator *activityIndicator;
@property (assign) IBOutlet NSButton *signInButton;
@property (assign) IBOutlet NSButton *registerButton;

@property (assign) id<WAAuthRequestWindowControllerDelegate> delegate;

- (IBAction) handleSignIn:(NSButton *)sender;
- (IBAction) handleRegister:(NSButton *)sender;

+ (id) sharedController;

@end
