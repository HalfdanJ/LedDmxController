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
#include <time.h>


#import "AppDelegate.h"

#define MAX_DATA_SIZE 256
#define NUM_CLIENTS 12
#define NUM_PIXELS 158
//#define NUM_PIXELS 32
#define BAUDRATE 57600          
//#define DEBUG_LOG
enum ProtocolTypes {
    PING = 0x01,
    STATUS = 0x02,
    VALUES = 0x03,
    BULK_VALUES = 0x04,
    CLOCK = 0x05,
    ALIVE = 0x06,
    BULK_ALL_STRIPS = 0x07,
    BULK_SEGMENT_MULTI_SUIT = 0x08,
    BULK_STRIP_MULTI_SUIT = 0x09

/*    BULK_ALL_STRIPS_DIM = 0x10,
    BULK_SEGMENT_MULTI_SUIT_DIM = 0x11,
    BULK_STRIP_MULTI_SUIT_DIM = 0x12
*/
};

#define multicastByte 14

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
    BOOL justSend;
} Pixel;

typedef struct {
    bool online;
    Pixel pixels[NUM_PIXELS];
    Pixel sendPixels[NUM_PIXELS];
} Client;



@interface XbeeController : NSObject{
    int serialFileDescriptor;
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
    
    IBOutlet AppDelegate * appDelegate;
    
    ArduinoLinkMessage incommingMessage;
    char incommingMessagePos;
    
    BOOL waitingForData;
    
//    NSDate * nextPingTime;
    BOOL pinging;
    
    NSDate * nextValueSendTime;

    NSDate * pingTimeoutTime;
    int clientPingStatus;
    NSDate * startTime;
    //NSDate * sendTime;
    time_t sendTime;

    
    
    Client clients[NUM_CLIENTS];
    
    float updateRate;
    float test;
    
    int demoMode;
    float demoR;
    float demoG;
    float demoB;
    NSDate * demoTime;
    
    NSRecursiveLock * lock;
    BOOL xbeeConnected;
    BOOL pixelsUpdated;
    
    unsigned char outputBuffer[127];
    int outputBufferCounter;
  //  AMSerialPort *port;

}

//@property (retain, readwrite) AMSerialPort * port;
@property (readwrite) float updateRate;
@property (readwrite) float test;
@property (readwrite) NSRecursiveLock * lock;
@property (assign) IBOutlet NSButton *TestPatternButton;
@property (readwrite) BOOL pixelsUpdated;

- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void) serialReadThread: (NSThread *) parentThread;
- (void) serialUpdateThread: (NSThread *) parentThread;
- (void) writeString: (NSString *) str;
- (void) writeByte: (unsigned char) val;
- (void) writeBuffer;
- (void) writeBytes: (unsigned char * ) bytes length:(int)length;
- (void) bufferBytes: (unsigned char * ) bytes length:(int)length;
-(void) serialBufferMessage:(ArduinoLinkMessage)msg;

- (void) receivedMessage:(ArduinoLinkMessage)msg;

-(IBAction) statusUpdate:(id)sender;
-(Client*) client:(int)num;


@end
