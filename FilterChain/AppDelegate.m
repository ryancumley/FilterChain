//
//  AppDelegate.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"


@interface AppDelegate ()

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize mVC = _mVC;
@synthesize purchaseManager = _purchaseManager;



#pragma Initialization, Configuration and View Lifecycle

- (void)createDirectoryForThumbnails {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* dataPath = [documentsDirectory stringByAppendingPathComponent:@"/Thumbnails"];
    NSError* error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
}

- (InAppPurchaseManager*)purchaseManager {
    if (_purchaseManager == nil) {
        _purchaseManager = [[InAppPurchaseManager alloc] init];
    }
    return _purchaseManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self loadFiltersFromJSON];
    [self createDirectoryForThumbnails];
    
    _mVC = [[MainViewController alloc] initWithNibName:@"Retina" bundle:[NSBundle mainBundle]];
    self.window.rootViewController = _mVC;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if (_mVC.recordingManager.isRecording) {
        [_mVC stopTimer];
        [_mVC.recordingManager stopRecording];
        [_mVC.clipManager refreshStoredClips];
    }
    [_mVC.recordingManager stopCameraCapture];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [_mVC awakeVideoCamera];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
    if (_mVC.recordingManager.isRecording) {
        [_mVC.recordingManager stopRecording];
    }
    [_mVC.recordingManager stopCameraCapture];

}




#pragma mark Load From CoreData at Launch

- (void)loadFiltersFromJSON {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"FreeFilterBank" ofType:@"json"];
    NSData *filterData = [NSData dataWithContentsOfFile:path];
    
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:filterData options:kNilOptions error:&err];
    if (err) { //TODO this can be removed prior to shipping the app
        NSLog(@"%@", err);
    }
    NSArray *definedFilters = [json objectForKey:@"Filter"];
    NSManagedObjectContext* moc = [self managedObjectContext];
    
    for (NSDictionary *filter in definedFilters) {
        NSString *name = [filter valueForKey:@"name"];
        BOOL exists = [self alreadyExists:name inManagedObjectContext:moc];
        if (!exists) {
            NSString *imageNamed = [filter valueForKey:@"imageName"];
            NSString *filterDesignator = [filter valueForKey:@"filterDesignator"];
            NSString *paid = [filter valueForKey:@"paidOrFree"];
            [self createFilterWithName:name imageNamed:imageNamed filterDesignator:filterDesignator paidOrFree:paid];
        }
    }
    

}

- (BOOL)alreadyExists:(NSString*)filterNamed inManagedObjectContext:(NSManagedObjectContext*)moc {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@", filterNamed];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Filter" inManagedObjectContext:moc];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity:description];
    [request setPredicate:predicate];
    NSError* error;
    NSArray* fetchedResult = [moc executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
    
    if (fetchedResult.count == 0) {
        return NO;
    }
    else {
        return YES;
    }
    
}

- (void)createFilterWithName:(NSString*)name imageNamed:(NSString*)imageName filterDesignator:(NSString*)designator paidOrFree:(NSString *)paid {
    NSManagedObjectContext* moc = [self managedObjectContext];
    Filter* newFilter = [NSEntityDescription insertNewObjectForEntityForName:@"Filter" inManagedObjectContext:moc];
    newFilter.name = name;
    newFilter.imageName = imageName;
    newFilter.filterDesignator = designator;
    newFilter.paidOrFree = paid;
    
    NSError* error;
    [moc save:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}




#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FilterChain" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FilterChain.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
    }
    
    return _persistentStoreCoordinator;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
        }
    }
}


#pragma mark Convenience Methods
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
