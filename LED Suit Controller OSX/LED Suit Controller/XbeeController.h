//
//  XbeeController.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 26/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import <Foundation/Foundation.h>
// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>

#import "AppDelegate.h"

@interface XbeeController : NSObject{
    int serialFileDescriptor;
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
    
    IBOutlet AppDelegate * appDelegate;

}

- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void)incomingTextUpdateThread: (NSThread *) parentThread;
- (void) writeString: (NSString *) str;
- (void) writeByte: (uint8_t *) val;


@end
