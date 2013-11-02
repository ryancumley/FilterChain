//
//  FilterChainTests.m
//  FilterChainTests
//
//  Created by Ryan Cumley on 9/6/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import "FilterChainTests.h"
#import "MainViewController.h"
#import "AppDelegate.h"
#import "RecordingManager.h"

@implementation FilterChainTests

- (void)setUp
{
    [super setUp];
    
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)testExample
{
    //STFail(@"Unit tests are not implemented yet in FilterChainTests");
    MainViewController* mvc = [[MainViewController alloc] init];
    [mvc viewDidLoad];
    RecordingManager* recordingManager = mvc.recordingManager;
    STAssertNotNil(recordingManager, @"failed to create recording Manager");
}

@end
