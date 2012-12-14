//
//  WAPhotoDay.h
//  IRTextAttributor
//
//  Created by Shen Steven on 12/14/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WAFile;

@interface WAPhotoDay : IRManagedObject

@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) WAFile *file;

@end
