//
//  AppDelegate.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArtnetController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    IBOutlet NSWindow *window;
  //  ArtnetController * artnetController;
}

@property (assign) IBOutlet NSWindow *window;
//@property (readonly) ArtnetController * artnetController;
@end
