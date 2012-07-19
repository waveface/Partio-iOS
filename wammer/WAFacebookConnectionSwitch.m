//
//  WAFacebookConnectionSwitch.m
//  wammer
//
//  Created by Evadne Wu on 7/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookConnectionSwitch.h"
#import "WAFacebookInterface.h"
#import "WARemoteInterface.h"
#import "WAFacebookInterfaceSubclass.h"
#import "Facebook.h"
#import "UIKit+IRAdditions.h"
#import "WAOverlayBezel.h"


@interface WAFacebookConnectionSwitch ()

- (void) commonInit;
- (void) reloadStatus;

@end


@implementation WAFacebookConnectionSwitch

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self commonInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self commonInit];

}

- (void) commonInit {

	[self addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
	
	self.enabled = NO;
	self.on = NO;
	
	[self reloadStatus];
	
}

- (void) reloadStatus {

	self.enabled = NO;
	self.on = NO;
	
	__weak WAFacebookConnectionSwitch *wSelf = self;
	
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	[ri retrieveConnectedSocialNetworksOnSuccess:^(NSArray *snsReps) {
	
		if (!wSelf)
			return;
	
		NSArray *facebookReps = [snsReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ (id evaluatedObject, NSDictionary *bindings) {
			
			return [[evaluatedObject valueForKeyPath:@"type"] isEqual:@"facebook"];
			
		}]];
		
		NSCParameterAssert([facebookReps count] <= 1);
		NSDictionary *fbRep = [facebookReps lastObject];
		//	NSString *fbStatus = [fbRep valueForKeyPath:@"status"];
		NSNumber *fbImportingEnabled = [fbRep valueForKeyPath:@"enabled"];
		
		BOOL importing = [fbImportingEnabled isEqual:(id)kCFBooleanTrue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (wSelf) {
				
				wSelf.enabled = YES;
				wSelf.on = importing;
				
			}
			
		});
		
	} onFailure:^(NSError *error) {
	
		NSLog(@"error %@", error);
		
	}];
	
}

- (void) handleValueChanged:(id)sender {

	NSCParameterAssert(sender == self);
	
	__weak WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	__weak WAFacebookInterface * const fi = [WAFacebookInterface sharedInterface];
	__weak WAFacebookConnectionSwitch * const wSelf = self;
	
	if (self.on) {
		
		NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
		IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
			
			[wSelf setOn:NO animated:YES];
			
		}];
		
		NSString *connectTitle = NSLocalizedString(@"ACTION_CONNECT_FACEBOOK_SHORT", @"SHort action title for connecting Facebook creds");
		IRAction *connectAction = [IRAction actionWithTitle:connectTitle block:^{
		
			[fi authenticateWithCompletion:^(BOOL didFinish, NSError *error) {
			
				dispatch_async(dispatch_get_main_queue(), ^{
				
					if (!didFinish) {
					
						WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
						[errorBezel showWithAnimation:WAOverlayBezelAnimationFade];
						
						[wSelf setOn:NO animated:YES];
						wSelf.enabled = YES;
						
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						
							[errorBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
							
						});
						
						return;
					
					}
				
					wSelf.enabled = NO;
					[wSelf setOn:YES animated:YES];
					
					WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
					[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
					
					[ri connectSocialNetwork:@"facebook" withToken:fi.facebook.accessToken onSuccess:^{
					
						if (!wSelf)
							return;
					
						dispatch_async(dispatch_get_main_queue(), ^{
						
							[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];

							wSelf.enabled = YES;
							[wSelf setOn:YES animated:YES];
							
						});
						
					} onFailure:^(NSError *error) {
					
						if (!wSelf)
							return;
					
						dispatch_async(dispatch_get_main_queue(), ^{
						
							[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
							
							WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
							[errorBezel showWithAnimation:WAOverlayBezelAnimationFade];
							
							[wSelf setOn:NO animated:YES];
							wSelf.enabled = YES;
							
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
							
								[errorBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
								
							});
							
						});
						
					}];
				
				});		

			}];
			
			wSelf.on = NO;
			
		}];
		
		NSString *alertTitle = NSLocalizedString(@"FACEBOOK_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Facebook account");
		NSString *alertMessage = NSLocalizedString(@"FACEBOOK_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Facebook account");
	
		IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:connectAction, nil]];
		[alertView show];
	
	} else {
	
		NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
		IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
			
			[wSelf setOn:YES animated:YES];
			
		}];
		
		NSString *disconnectTitle = NSLocalizedString(@"ACTION_DISCONNECT_FACEBOOK", @"Short action title for disconnecting Facebook creds");
		IRAction *disconnectAction = [IRAction actionWithTitle:disconnectTitle block:^{
		
			wSelf.enabled = NO;
		
			WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
			[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];

			[ri disconnectSocialNetwork:@"facebook" purgeData:NO onSuccess:^{

				dispatch_async(dispatch_get_main_queue(), ^{
					
					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
					if (!wSelf)
						return;

					wSelf.enabled = YES;
					wSelf.on = NO;
					
				});
				
			} onFailure:^(NSError *error) {
			
				dispatch_async(dispatch_get_main_queue(), ^{
				
					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
					
					WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
					[errorBezel showWithAnimation:WAOverlayBezelAnimationNone];

					if (!wSelf)
						return;
					
					[wSelf setOn:YES animated:YES];
					wSelf.enabled = YES;
					
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					
						[errorBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
						
					});

				});
				
			}];

		}];
		
		NSString *alertTitle = NSLocalizedString(@"FACEBOOK_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Facebook account");
		NSString *alertMessage = NSLocalizedString(@"FACEBOOK_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Facebook account");

		IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:disconnectAction, nil]];
		[alertView show];
			
	}
	
}

@end
