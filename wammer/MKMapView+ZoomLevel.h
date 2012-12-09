//
//  MKMapView+ZoomLevel.h
//  wammer
//
//  Created by Shen Steven on 11/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//


// here is the code from: http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
									zoomLevel:(NSUInteger)zoomLevel
									 animated:(BOOL)animated;

@end
