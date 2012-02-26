//
//  XbeeController.m
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 26/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import "XbeeController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"


@implementation XbeeController
//@synthesize port;
@synthesize updateRate, test;

-(void)awakeFromNib{
    // we don't have a serial port open yet
	serialFileDescriptor = -1;
	incommingMessagePos = 0;
    clientPingStatus = 0;
    waitingForData = NO;
    readThreadRunning = FALSE;
    [self setUpdateRate:0.07];
    
    NSString *error = [self openSerialPort:@"/dev/tty.usbserial-A70064SC" baud:BAUDRATE];
    if(error != nil){
        NSLog(@"Open Serial error: %@",error);
        [appDelegate logError:FORMAT(@"Error connecting to serial %@",error)];
        
    } else {
        NSLog(@"Serial successfully opened");
        [appDelegate logInfo:@"Serial successfully opened"];
        
        [self performSelectorInBackground:@selector(serialReadThread:) withObject:[NSThread currentThread]];
        [self performSelectorInBackground:@selector(serialUpdateThread:) withObject:[NSThread currentThread]];
        
    }
}


-(void) sendValues {
    ArduinoLinkMessage msg;
    msg.type = 'V';
    msg.destination = 0;
    msg.sender = 254;
    msg.moreComing = NO;
    msg.length = NUM_PIXELS*3 + 1;
    msg.data[0] = 0;
    
    for(int i=0;i<NUM_PIXELS;i++){
        msg.data[1+i*3] = clients[0].pixels[i].r*100;
        msg.data[2+i*3] = clients[0].pixels[i].g*100;
        msg.data[3+i*3] = clients[0].pixels[i].b*100;
    }
    
    [self serialWriteMessage:msg];
    
    int byteLength = msg.length + 6;
    int bitLength = byteLength * 8;
    
    float packetPrSec = (float)BAUDRATE/bitLength;
    float secDelay = 1.0/packetPrSec;
        
   // [self setUpdateRate:secDelay];
    [nextValueSendTime release];
    nextValueSendTime = [[NSDate dateWithTimeIntervalSinceNow:updateRate+0.01] retain];

}

-(void)serialUpdateThread:(NSThread *)parentThread{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSThread setThreadPriority:1.0];
    startTime = [[[NSDate alloc] init] retain];
    while(TRUE) {
        //Test data
        for(int i=0;i<NUM_CLIENTS;i++){
            for(int u=0;u<NUM_PIXELS;u++){
                float b = (sin(-[startTime timeIntervalSinceNow] + u) + 1)/2.0;
                float g = (sin(-[startTime timeIntervalSinceNow] + u+3.14) + 1)/2.0;
//                float b = (sin(-[startTime timeIntervalSinceNow] + u+3.14/3.0+3.14/3.0) + 1)/2.0;
            
                float r = test ;
                clients[i].pixels[u].r = r;
                clients[i].pixels[u].g = g;
                clients[i].pixels[u].b = b;
            }
        }
        
        
        if(!waitingForData){
            if(nextPingTime == nil || [nextPingTime timeIntervalSinceNow] < 0){
                //Ping!
                
                @synchronized(self){
                    //        [self writeByte:'a'];
                    [self writeString:@"#P"];
                    [self writeByte:clientPingStatus];
                    [self writeByte:254];
                    [self writeByte:0];
                    [self writeByte:0];
                    waitingForData = YES;
                    
                    if(sendTime)
                        [sendTime release];
                    sendTime = [[NSDate date] retain];
                    
                    NSLog(@"Ping %i",clientPingStatus);
                    
                    [pingTimeoutTime release];
                    pingTimeoutTime = [[NSDate dateWithTimeIntervalSinceNow:0.5] retain];
                    [nextPingTime release];
                    nextPingTime = [[NSDate dateWithTimeIntervalSinceNow:2.0] retain];
                }
            }
        }
      
        if(!waitingForData){
            if((nextValueSendTime == nil || [nextValueSendTime timeIntervalSinceNow] < 0) && updateRate > 0){
                @synchronized(self){
                    [self sendValues];
                }
                
            }          
        }
        
        
        
        if(waitingForData && pingTimeoutTime && [pingTimeoutTime timeIntervalSinceNow] < 0){
            //Timeout ping, lets go on!
            NSLog(@"Timeout %i",clientPingStatus);
            
            pingTimeoutTime = nil;
            waitingForData = NO;
            //      if(clients[clientPingStatus].online){
            [[[appDelegate clientStates] objectAtIndex:clientPingStatus] setValue:@"Offline" forKey:@"status"];
            clients[clientPingStatus].online = NO; 
            //    }
            
            clientPingStatus ++;
            if(clientPingStatus >= NUM_CLIENTS){
                clientPingStatus = 0;
            }
        }
        //NSLog(@"%f", [pingTimeoutTime timeIntervalSinceNow]);
        
    }
    
    [pool release];
    
}

- (void) receivedMessage:(ArduinoLinkMessage)msg{
    [appDelegate logMessage:FORMAT(@"Receviced message %c",msg.type)];
    
    if(sendTime){
        [appDelegate logMessage:FORMAT(@"Time: %f",-[sendTime timeIntervalSinceNow])];
        
    }
    
    if(msg.type == 'A'){
        waitingForData = NO;
    }
    if(msg.type == 'S'){
        
        //Status 
        if(!clients[clientPingStatus].online){
            clients[clientPingStatus].online = YES;
            [[[appDelegate clientStates] objectAtIndex:msg.sender] setValue:@"OK" forKey:@"status"];
        }
        if(!msg.moreComing){
            waitingForData = NO;
        }
        
        clientPingStatus ++;
        if(clientPingStatus >= NUM_CLIENTS){
            clientPingStatus = 0;
        }
        
    }
}

-(void) serialWriteMessage:(ArduinoLinkMessage)msg{
    unsigned char cmsg[msg.length + 6];
    cmsg[0] = '#';
    cmsg[1] = msg.type;
    cmsg[2] = msg.destination;
    cmsg[3] = msg.sender;
    cmsg[4] = msg.length;
    cmsg[5] = msg.moreComing;
    
    for(int i=0;i<msg.length;i++){
        cmsg[i+6] = msg.data[i];
    }
    [self writeBytes:cmsg length:msg.length + 6];
    
}


// This selector will be called as another thread
- (void)serialReadThread: (NSThread *) parentThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	readThreadRunning = TRUE;
    
	const int BUFFER_SIZE = 100;
	char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	ssize_t numBytes=0; // number of bytes read during read
	NSString *text; // incoming text from the serial port
	
	// assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(TRUE) {
		// read() blocks until some data is available or the port is closed
		numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
		if(numBytes>0) {
            @synchronized(self){
                
                for(int i=0;i<numBytes;i++){
                    unsigned char c = byte_buffer[i];
                    
                    if(incommingMessagePos == 0){
                        if(c != '#'){
                            incommingMessagePos = -1;
                            NSLog(@"NOT # at pos 0");
                        }
                    } 
                    else if(incommingMessagePos == 1){
                        incommingMessage.type = c;
                    } 
                    else if(incommingMessagePos == 2){
                        incommingMessage.destination = c; 
                    } 
                    else if(incommingMessagePos == 3){
                        incommingMessage.sender = c; 
                    } 
                    else if(incommingMessagePos == 4){
                        incommingMessage.length = c; 
                    } 
                    
                    else if(incommingMessagePos == 5){
                        incommingMessage.moreComing = c; 
                        
                        if(incommingMessage.length == 0){
                            incommingMessage.complete = true;
                        }
                    } 
                    else if(incommingMessagePos >= 6) {
                        incommingMessage.data[incommingMessagePos-6] = c;
                        
                        if(incommingMessagePos - 5 == incommingMessage.length){
                            incommingMessage.complete = true;
                        }
                    }
                    incommingMessagePos++;
                    
                    if(incommingMessage.complete){
                        incommingMessagePos = 0;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self receivedMessage:incommingMessage];
                        });
                    }
                    
                    incommingMessage.complete = false;
                }
                
                /* // create an NSString from the incoming bytes (the bytes aren't null terminated)
                 text = [NSString stringWithCString:byte_buffer length:numBytes];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                 [appDelegate logMessage:text];
                 });*/
            }
        }
    }
    // make sure the serial port is closed
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    // mark that the thread has quit
    readThreadRunning = FALSE;
    
    // give back the pool
    [pool release];
}



// send a string to the serial port
- (void) writeString: (NSString *) str {
    if(serialFileDescriptor!=-1) {
        write(serialFileDescriptor, [str cStringUsingEncoding:NSUTF8StringEncoding], [str length]);
    } else {
        // make sure the user knows they should select a serial port
        //	[self appendToIncomingText:@"\n ERROR:  Select a Serial Port from the pull-down menu\n"];
    }
}

// send a byte to the serial port
- (void) writeByte: (unsigned char) val {
    if(serialFileDescriptor!=-1) {
        unsigned char tmpByte[1];
        tmpByte[0] = val;
        int numWritten = write(serialFileDescriptor, tmpByte, 1);
    }
}

// send a byte to the serial port
- (void) writeBytes: (unsigned char * ) bytes length:(int)length {
    if(serialFileDescriptor!=-1) {
        int numWritten = write(serialFileDescriptor, bytes, length);
    }
}






- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate {
	int success = 0;
	
	// close the port if it is already open
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
    
    if(serialFileDescriptor == -1){
        // ofLog(OF_LOG_ERROR,"ofSerial: unable to open port %s", portName.c_str());
        return false;
    }
    
    //struct termios options;
    tcgetattr(serialFileDescriptor,&gOriginalTTYAttrs);
    options = gOriginalTTYAttrs;
    switch(baudRate){
        case 300: 	cfsetispeed(&options,B300);
            cfsetospeed(&options,B300);
            break;
        case 1200: 	cfsetispeed(&options,B1200);
            cfsetospeed(&options,B1200);
            break;
        case 2400: 	cfsetispeed(&options,B2400);
            cfsetospeed(&options,B2400);
            break;
        case 4800: 	cfsetispeed(&options,B4800);
            cfsetospeed(&options,B4800);
            break;
        case 9600: 	cfsetispeed(&options,B9600);
            cfsetospeed(&options,B9600);
            break;
        case 14400: 	cfsetispeed(&options,B14400);
            cfsetospeed(&options,B14400);
            break;
        case 19200: 	cfsetispeed(&options,B19200);
            cfsetospeed(&options,B19200);
            break;
        case 28800: 	cfsetispeed(&options,B28800);
            cfsetospeed(&options,B28800);
            break;
        case 38400: 	cfsetispeed(&options,B38400);
            cfsetospeed(&options,B38400);
            break;
        case 57600:  cfsetispeed(&options,B57600);
            cfsetospeed(&options,B57600);
            break;
        case 115200: cfsetispeed(&options,B115200);
            cfsetospeed(&options,B115200);
            break;
            
        default:	cfsetispeed(&options,B9600);
            cfsetospeed(&options,B9600);
            //ofLog(OF_LOG_ERROR,"ofSerialInit: cannot set %i baud setting baud to 9600\n", baud);
            break;
    }
    
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;
    tcsetattr(serialFileDescriptor,TCSANOW,&options);
    
    // make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	return errorMessage;
}
@end
