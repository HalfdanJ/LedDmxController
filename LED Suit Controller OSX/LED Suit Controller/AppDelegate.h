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
/*#define PATCH(UNIVERSE,PIXEL,ADR, CLIENT) ([xbee client:CLIENT]->pixels[PIXEL].r = values[ADR]/255.0; [xbee client:CLIENT]->pixels[PIXEL].g = values[ADR+1]/255.0; [xbee client:CLIENT]->pixels[PIXEL].b = values[ADR+2]/255.0);
*/

@class XbeeController;

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    IBOutlet NSWindow *window;
   IBOutlet NSTextView *logView;
    IBOutlet XbeeController * xbee;
  //  ArtnetController * artnetController;
    
    GCDAsyncUdpSocket *udpSocket;
	BOOL isRunning;
    
    NSMutableArray * clientStates;
    
    float ledsTest[32];
    long long count;
    
    int values[513*12];
    BOOL artnetReceived;
    BOOL universeReceived[8];
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSTextView *logView;
@property (readwrite, retain) NSMutableArray * clientStates;
@property (assign) IBOutlet NSButton *testPatternButton;
@property (assign) IBOutlet NSButton *testLedButton;

-(IBAction)sendTestValue:(id)sender;
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
//@property (readonly) ArtnetController * artnetController;
@end
