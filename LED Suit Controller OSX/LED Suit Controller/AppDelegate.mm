//
//  AppDelegate.m
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window, artnetController;

- (id)init {
    self = [super init];
    if (self) {
 //       artnetController = [[ArtnetController alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

@end
