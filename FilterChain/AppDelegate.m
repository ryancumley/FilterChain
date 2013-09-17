//
//  AppDelegate.m
//  FilterChain
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize mVC = _mVC;

- (void)loadFiltersFromJSON {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"FilterBank" ofType:@"json"];
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
            [self createFilterWithName:name imageNamed:imageNamed filterDesignator:filterDesignator];
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

- (void)createFilterWithName:(NSString*)name imageNamed:(NSString*)imageName filterDesignator:(NSString*)designator {
    NSManagedObjectContext* moc = [self managedObjectContext];
    Filter* newFilter = [NSEntityDescription insertNewObjectForEntityForName:@"Filter" inManagedObjectContext:moc];
    newFilter.name = name;
    newFilter.imageName = imageName;
    newFilter.filterDesignator = designator;
    
    NSError* error;
    [moc save:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [self loadFiltersFromJSON];
    self.window.backgroundColor = [UIColor whiteColor];
    
    
    //TODO switch the nib Name based on type of hardware detected
    _mVC = [[MainViewController alloc] initWithNibName:@"Retina" bundle:[NSBundle mainBundle]];
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    //[_mVC.view setFrame:appFrame];
    //[_mVC.previewLayer setFrame:appFrame];
    //[_mVC.clipManagerView setFrame:appFrame];
    self.window.rootViewController = _mVC;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [_mVC awakeVideoCamera];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
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
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
