//
//  XbeeController.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 26/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import <Foundation/Foundation.h>
// import IOKit headers
// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>


#import "AppDelegate.h"

#define MAX_DATA_SIZE 256
#define NUM_CLIENTS 1
#define NUM_PIXELS 32
#define BAUDRATE 19200

typedef struct  {
    unsigned char type;
    unsigned char destination;
    unsigned char sender;
    unsigned char length;
    bool moreComing;
    bool complete;
    unsigned char data[MAX_DATA_SIZE]; 
}ArduinoLinkMessage ;

typedef struct {
    float r;
    float g;
    float b;
} Pixel;

typedef struct {
    bool online;
    Pixel pixels[NUM_PIXELS];
} Client;

@interface XbeeController : NSObject{
    int serialFileDescriptor;
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
    
    IBOutlet AppDelegate * appDelegate;
    
    ArduinoLinkMessage incommingMessage;
    char incommingMessagePos;
    
    BOOL waitingForData;
    
    NSDate * nextPingTime;
    NSDate * nextValueSendTime;

    NSDate * pingTimeoutTime;
    int clientPingStatus;
    NSDate * startTime;
    NSDate * sendTime;
    
    Client clients[NUM_CLIENTS];
    
    float updateRate;
    float test;
  //  AMSerialPort *port;

}

//@property (retain, readwrite) AMSerialPort * port;
@property (readwrite) float updateRate;
@property (readwrite) float test;

- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void) serialReadThread: (NSThread *) parentThread;
- (void) serialUpdateThread: (NSThread *) parentThread;
- (void) writeString: (NSString *) str;
- (void) writeByte: (unsigned char) val;
- (void) writeBytes: (unsigned char * ) bytes length:(int)length;
-(void) serialWriteMessage:(ArduinoLinkMessage)msg;

- (void) receivedMessage:(ArduinoLinkMessage)msg;

@end
