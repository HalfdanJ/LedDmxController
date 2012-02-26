//
//  AppDelegate.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    IBOutlet NSWindow *window;
   IBOutlet NSTextView *logView;

  //  ArtnetController * artnetController;
    
    GCDAsyncUdpSocket *udpSocket;
	BOOL isRunning;
    
    NSMutableArray * clientStates;
    
    float ledsTest[32];
    long long count;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSTextView *logView;
@property (readwrite, retain) NSMutableArray * clientStates;

-(IBAction)sendTestValue:(id)sender;
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
//@property (readonly) ArtnetController * artnetController;
@end
