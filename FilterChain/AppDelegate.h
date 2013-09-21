//
//  AppDelegate.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "MainViewController.h"
#import "Filter.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) MainViewController* mVC;


- (void)saveContext;
- (void)loadFiltersFromJSON;
- (void)createDirectoryForThumbnails;
- (NSURL *)applicationDocumentsDirectory;
- (BOOL)alreadyExists:(NSString*)filterNamed inManagedObjectContext:(NSManagedObjectContext*)moc;
- (void)createFilterWithName:(NSString*)name imageNamed:(NSString*)imageName filterDesignator:(NSString*)designator;

@end