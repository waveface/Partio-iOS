//
//  WAConnectionStatusView.m
//  wammer
//
//  Created by Shen Steven on 1/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAConnectionStatusView.h"
#import "WARemoteInterface.h"

@interface WAConnectionStatusView ()

@property (nonatomic, strong) WARemoteInterface *remoteInterface;

@end

@implementation WAConnectionStatusView

+ (id) viewFromNib {
  
  __weak id wSelf = self;
  return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
	return [evaluatedObject isKindOfClass:wSelf];
  }]] lastObject];
  
}

- (id)init
{
  self = [[self class] viewFromNib];
  if (self) {
	  
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	  
	self.remoteInterface = [WARemoteInterface sharedInterface];
	[self.remoteInterface addObserver:self
						   forKeyPath:@"networkState"
							  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
							  context:nil];
  }
  return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

  if ([self.remoteInterface hasReachableCloud] && ![self.remoteInterface hasReachableStation]) {
	
	self.textLabel.text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
	self.imageView.image = [UIImage imageNamed:@"cloud"];
	
  } else if ([self.remoteInterface hasReachableStation]) {
	
    if ([self.remoteInterface.monitoredHosts count]) {
	  self.textLabel.text = [self.remoteInterface.monitoredHosts[0] name];
	  self.imageView.image = [UIImage imageNamed:@"station"];
    } else {
      self.textLabel.text = NSLocalizedString(@"NO_STATION_INSTALLED", @"Cell title in connection status view controller");
	  self.imageView.image = [UIImage imageNamed:@"station"];
    }
	
  } else {
	
	self.textLabel.text = NSLocalizedString(@"NO_INTERNET_CONNECTION", @"No internet connection");
	self.imageView.image = [UIImage imageNamed:@"nointernetaccess"];
	
  }

}

- (void) dealloc {
  
  [self.remoteInterface removeObserver:self forKeyPath:@"networkState"];
  
}

@end
