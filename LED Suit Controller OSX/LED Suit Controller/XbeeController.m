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
@synthesize TestPatternButton;
@synthesize testLedButton;
//@synthesize port;
@synthesize updateRate, test, lock, pixelsUpdated;

-(void)awakeFromNib{
    // we don't have a serial port open yet
	serialFileDescriptor = -1;
	incommingMessagePos = 0;
    clientPingStatus = 0;
    waitingForData = NO;
    readThreadRunning = FALSE;
    [self setUpdateRate:0.3];
    lock = [[[NSRecursiveLock alloc] init] retain];
    
    //    NSString *error = [self openSerialPort:@"/dev/tty.usbserial-AH00SB3J" baud:BAUDRATE];
    NSString *error = [self openSerialPort:@"/dev/tty.usbserial-A70064SC" baud:BAUDRATE];
    //        NSString *error = [self openSerialPort:@"/dev/tty.usbmodem26211" baud:BAUDRATE];
    if(error != nil){
        NSLog(@"Open Serial error: %@",error);
        [appDelegate logError:FORMAT(@"Error connecting to serial: %@",error)];
        xbeeConnected = NO;
        
    } else {
        NSLog(@"Serial successfully opened");
        [appDelegate logInfo:@"Serial successfully opened"];
        xbeeConnected = YES;
        
     //   [self performSelectorInBackground:@selector(serialReadThread:) withObject:[NSThread currentThread]];
        [self performSelectorInBackground:@selector(serialUpdateThread:) withObject:[NSThread currentThread]];
        
    }
    pixelsUpdated = YES;
}


-(Client*) client:(int)num{
    return &clients[num];
}

-(BOOL) pixel:(Pixel)pixel1 isEqualTo:(Pixel)pixel2{
    return (round(128*pixel1.r) == round(128*pixel2.r) && round(128*pixel1.g) == round(128*pixel2.g) && round(128*pixel1.b) == round(128*pixel2.b));
}


-(int) offsetStripPixel:(int)pixel{
    if(pixel < 38)
        return 0;
    if(pixel < 76)
        return 38;
    if(pixel < 102)
        return 76;
    if(pixel < 128)
        return 102;
    return 128;
}

-(int) stripForPixel:(int)pixel{
    if(pixel < 38)
        return 1;
    if(pixel < 76)
        return 0;
    if(pixel < 102)
        return 3;
    if(pixel < 128)
        return 2;
    return 4;
}

-(void) sendValues {
    if(pixelsUpdated){
        [lock lock];
        int numSend = 0;
        int bytesSend = 0;
        
        //    NSLog(@"%f",clients[0].pixels[21].r);
        
        for(int i=0;i< NUM_CLIENTS;i++){
            //Find ud af om der er opdateringer i dragten
            BOOL clientUpdated = NO;
            for(int u=0;u<NUM_PIXELS;u++){
                if(![self pixel:clients[i].pixels[u] isEqualTo:clients[i].sendPixels[u]]){
                    clientUpdated = YES;
                //    NSLog(@" Pixel %i updated (%f != %f)",u,clients[i].pixels[u].r, clients[i].sendPixels[u]);
                    break;
                }
            }
            
            if(clientUpdated){
              //  NSLog(@"Client %i updated",i);
                
                //Er alle pixels ens? 
                BOOL allTheSame = YES;
                Pixel _pixel = clients[i].pixels[0];
                for(int u=1;u<NUM_PIXELS;u++){
                    if(![self pixel:clients[i].pixels[u] isEqualTo:_pixel]){
                        allTheSame = NO;
                       // NSLog(@" Pixel %i not the same (%f != %f)",u,clients[i].pixels[u].b, _pixel.b);
                        break;
                    }
                }
                if(allTheSame){
                  //  NSLog(@"All the same!");
#pragma mark BULK ALL STRIPS
                    ArduinoLinkMessage msg;
                    msg.type = BULK_ALL_STRIPS;
                    msg.length = 5;
                    msg.data[0] = 0x00;
                    msg.data[1] = 0x00;     
                    
                    if(i < 8){
                        msg.data[0] += 1 << i;
                    } else {
                        msg.data[1] += 1 << (i-8);
                    }
                                        
                    msg.data[2] = clients[i].pixels[0].r*100;
                    msg.data[3] = clients[i].pixels[0].g*100;
                    msg.data[4] = clients[i].pixels[0].b*100;

                    //Andre dragte med samme værdier?
                    for(int j=0;j< NUM_CLIENTS;j++){
                        bool same = YES;
                        for(int u=0;u<NUM_PIXELS;u++){
                            if(j != i && ![self pixel:clients[j].pixels[u] isEqualTo:clients[i].pixels[0]]){
                                same = NO;
                                break;
                            }
                        }
                        
                        if(same && j != i ){
                            if(j < 8){
                                msg.data[0] += 1 << j;
                            } else {
                                msg.data[1] += 1 << (j-8);
                            }
                            for(int u=0;u<NUM_PIXELS;u++){
                                clients[j].sendPixels[u] = clients[i].pixels[0];
                                clients[j].sendPixels[u].justSend = YES;
                                
                            }
                            
                            //    NSLog(@"client %i same as %i",j,i);
                            
                        }
                    }
                    
                    for(int u=0;u<NUM_PIXELS;u++){
                        clients[i].sendPixels[u] = clients[i].pixels[0];
                        clients[i].sendPixels[u].justSend = YES;
                        
                    }
                    [self serialBufferMessage:msg];
                    #ifdef DEBUG_LOG
                                                    NSLog(@"Send BULK_ALL_STRIPS Client: %i  :  %X %X   (%i %i %i)",i,msg.data[1],msg.data[0], msg.data[2], msg.data[3], msg.data[4]);
#endif
                    numSend++;
                    
                    
                } else {
                    // NSLog(@"NOT the same!");                    
                    
                    //Find similair suits
                    int numSimilair = 0;
                    bool similair[NUM_CLIENTS];
                    for(int j=0;j< NUM_CLIENTS;j++){
                        similair[j] = NO;
                    
                        bool same = YES;
                        for(int u=0;u<NUM_PIXELS;u++){
                            if(j != i && ![self pixel:clients[j].pixels[u] isEqualTo:clients[i].pixels[u]]){
                                same = NO;
                                break;
                            }
                        }
                        
                        if(i!=j && same){
                            similair[j] = YES;
                            numSimilair ++;
                        }
                        if(i == j)
                            similair[j] = YES;
                    }
                    
                    if(numSimilair >= 0){
                        ArduinoLinkMessage msg;
                        msg.type = BULK_STRIP_MULTI_SUIT;
                        msg.length = 6;
                        msg.data[0] = 0x00;
                        msg.data[1] = 0x00;     
                       
                        for(int j=0;j< NUM_CLIENTS;j++){
                            if(similair[j]){
                                if(j < 8){
                                    msg.data[0] += 1 << j;
                                } else {
                                    msg.data[1] += 1 << (j-8);
                                }
                            }
                        }    
                        
                        
                        //All whole strips first
                        Pixel _pixel;
                        int _strip = -1;
                        BOOL allTheSame[5];
                        BOOL updatesOnStrip[5];
                        Pixel stripPixel[5];
                        for(int u=0;u<NUM_PIXELS;u++){
                            if([self stripForPixel:u] != _strip){
                                _strip = [self stripForPixel:u];
                                allTheSame[_strip] = YES;
                                _pixel = clients[i].pixels[u];
                                stripPixel[_strip] = _pixel;
                                updatesOnStrip[_strip] = NO;

                            } else {
                                if(![self pixel:clients[i].pixels[u] isEqualTo:clients[i].sendPixels[u]]){
                                    updatesOnStrip[_strip] = YES;
                                }
                                if(![self pixel:_pixel isEqualTo:clients[i].pixels[u]]){
                                    allTheSame[_strip] = NO;
                                }
                            }
                        }
                        
                        bool stripSend[5];
                        for(int j=0;j<5;j++){
                            stripSend[j] = NO;
                        }
                        for(int strip=0;strip<5;strip++){
                            if(allTheSame[strip] && updatesOnStrip[strip] && !stripSend[strip]){
                                msg.data[2] = 0;

                                
                                for(int otherStrips = strip;otherStrips<5;otherStrips++){
                                    //Other strip with same value (or same strip)
                                    if(allTheSame[otherStrips] &&[self pixel:stripPixel[otherStrips] isEqualTo:stripPixel[strip]]){
                                        msg.data[2] += 1 << otherStrips;
                                        stripSend[otherStrips] = YES;
                                       // NSLog(@"Bundle %i to %i   0x%X",otherStrips, strip, 1 << strip);
                                    }
                        
                                }
                                
//                                NSLog(@"All the same on strip %i",strip);
                                
                                msg.data[3] = stripPixel[strip].r*100;
                                msg.data[4] = stripPixel[strip].g*100;
                                msg.data[5] = stripPixel[strip].b*100;
                               
                                [self serialBufferMessage:msg];
                                #ifdef DEBUG_LOG
                                                              NSLog(@"Send BULK_STRIP_MULTI_SUIT  Client: %i (0x%X  0x%X) Strip: %i (0x%X)",i,msg.data[1],msg.data[0] , strip, msg.data[2]);
#endif
                                numSend ++;

                                for(int q=0;q<NUM_CLIENTS;q++){
                                    if(similair[q]){
                                        for(int j=0;j<NUM_PIXELS;j++){
                                            if(stripSend[[self stripForPixel:j]]){
                                                clients[q].sendPixels[j] = clients[q].pixels[j];
                                                clients[q].sendPixels[j].justSend = YES;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        
                        msg.type = BULK_SEGMENT_MULTI_SUIT;
                        msg.length = 8;

                   //    printf("%X %X\n",msg.data[1], msg.data[0 ]);
                        
                        int pixelUpdateIndexStart = -1;
                        Pixel pixelSend;              
                        for(int u=0;u<NUM_PIXELS;u++){
                            if(pixelUpdateIndexStart == -1 && ![self pixel:clients[i].pixels[u] isEqualTo:clients[i].sendPixels[u]]){
                                pixelUpdateIndexStart = u;
                                pixelSend = clients[i].pixels[u];
                            }
                            else if(pixelUpdateIndexStart != -1 && ([self stripForPixel:u] != [self stripForPixel:pixelUpdateIndexStart] || ![self pixel:clients[i].pixels[u] isEqualTo:pixelSend] || u == NUM_PIXELS-1) ){
                                //Send update
                                msg.data[2] = [self stripForPixel:pixelUpdateIndexStart];
                                msg.data[3] = pixelUpdateIndexStart - [self offsetStripPixel:pixelUpdateIndexStart];
                                msg.data[4] = u-pixelUpdateIndexStart;
                                msg.data[5] = clients[i].pixels[pixelUpdateIndexStart].r*100;
                                msg.data[6] = clients[i].pixels[pixelUpdateIndexStart].g*100;
                                msg.data[7] = clients[i].pixels[pixelUpdateIndexStart].b*100;
                                
                                for(int q=0;q<NUM_CLIENTS;q++){
                                    if(similair[q]){
                                        for(int j=pixelUpdateIndexStart;j<u;j++){
                                            clients[q].sendPixels[j] = clients[q].pixels[j];
                                            clients[q].sendPixels[j].justSend = YES;
                                        }
                                    }
                                }
                                
                                //
                                  //              NSLog(@"Send (%i - %i) %i: %i -> %i (%f, %f, %f)",i, [self stripForPixel:pixelUpdateIndexStart], pixelUpdateIndexStart, pixelUpdateIndexStart - [self offsetStripPixel:pixelUpdateIndexStart], u-pixelUpdateIndexStart, clients[i].pixels[pixelUpdateIndexStart].r,clients[i].pixels[pixelUpdateIndexStart].g, clients[i].pixels[pixelUpdateIndexStart].b);
                                //  NSLog(@"Num pixels updated: %i",u-pixelUpdateIndexStart);
                                [self serialBufferMessage:msg];
#ifdef DEBUG_LOG
                                NSLog(@"Send BULK_SEGMENT_MULTI_SUIT  Client: %i  Strip: %i offset: %i  num: %i",i,msg.data[2],msg.data[3],msg.data[4]);
#endif
                                numSend ++;
                                
                                pixelUpdateIndexStart = -1;
                                u--;
                            }
                        }
                    }
                    
                    
                    
                 //   NSLog(@"%i similair",numSimilair);

                    
                }

            }
            
            /*
            
            
            int pixelUpdateIndexStart = -1;
            Pixel pixelSend;
            
            
            
            for(int u=0;u<NUM_PIXELS;u++){
                if(pixelUpdateIndexStart == -1 && ![self pixel:clients[i].pixels[u] isEqualTo:clients[i].sendPixels[u]]){
                    pixelUpdateIndexStart = u;
                    pixelSend = clients[i].pixels[u];
                }
                else if(pixelUpdateIndexStart != -1 && ([self stripForPixel:u] != [self stripForPixel:pixelUpdateIndexStart] || ![self pixel:clients[i].pixels[u] isEqualTo:pixelSend] || u == NUM_PIXELS-1) ){
                    
                    //Find ud af om det kan multicastes
                    bool multicast = YES;
                    for(int clientPixel=pixelUpdateIndexStart;clientPixel<u;clientPixel++){
                        Pixel p = clients[i].pixels[clientPixel];
                        for(int client=0;client<NUM_CLIENTS;client++){
                            if(![self pixel:clients[client].pixels[clientPixel]  isEqualTo:p]){
                                multicast = NO;
                                break;
                            }
                        }
                    }
                    
                    //Send update
                    ArduinoLinkMessage msg;
                    msg.type = BULK_VALUES;
                    msg.destination = i+1;
                    if(multicast){
                        msg.destination = multicastByte;                    
                    }
                    msg.moreComing = NO;
                    msg.length = 6;
                    msg.data[0] = [self stripForPixel:pixelUpdateIndexStart];
                    msg.data[1] = pixelUpdateIndexStart - [self offsetStripPixel:pixelUpdateIndexStart];
                    msg.data[2] = u-pixelUpdateIndexStart;
                    msg.data[3] = clients[i].pixels[pixelUpdateIndexStart].r*100;
                    msg.data[4] = clients[i].pixels[pixelUpdateIndexStart].g*100;
                    msg.data[5] = clients[i].pixels[pixelUpdateIndexStart].b*100;
                    
                    //                NSLog(@"Send (%i - %i) %i: %i -> %i (%f, %f, %f)",i, [self stripForPixel:pixelUpdateIndexStart], pixelUpdateIndexStart, pixelUpdateIndexStart - [self offsetStripPixel:pixelUpdateIndexStart], u-pixelUpdateIndexStart, clients[i].pixels[pixelUpdateIndexStart].r,clients[i].pixels[pixelUpdateIndexStart].g, clients[i].pixels[pixelUpdateIndexStart].b);
                  //  NSLog(@"Num pixels updated: %i",u-pixelUpdateIndexStart);
                    [self serialBufferMessage:msg];
                    bytesSend += 5+6;
                    
                    for(int j=pixelUpdateIndexStart;j<u;j++){
                        clients[i].sendPixels[j].r = clients[i].pixels[j].r;
                        clients[i].sendPixels[j].g = clients[i].pixels[j].g;
                        clients[i].sendPixels[j].b = clients[i].pixels[j].b;  
                        clients[i].sendPixels[j].justSend = YES;
                        
                        if(multicast){
                            for(int client=0;client<NUM_CLIENTS;client++){
                                clients[client].sendPixels[j].justSend = YES;
                                clients[client].sendPixels[j].r = clients[client].pixels[j].r;
                                clients[client].sendPixels[j].g = clients[client].pixels[j].g;
                                clients[client].sendPixels[j].b = clients[client].pixels[j].b;  
                            }
                        }
                    }
                    anythingSend = true;
                    
                    pixelUpdateIndexStart = -1;
                    u--;
                }
            }
            */
        }
        pixelsUpdated = NO;
        [lock unlock];
        
        // NSLog(@"%f", );
        if(numSend){// || sendTime == nil || [sendTime timeIntervalSinceNow] < -0.5) {
            ArduinoLinkMessage msg;
            msg.type = CLOCK;
            msg.destination = 0;
            msg.moreComing = NO;
            msg.length = 0;
            
            [self serialBufferMessage:msg];
            bytesSend += 5;
         //   NSLog(@"Send %i messages",numSend);
//            
//            int bitLength = bytesSend * 8;
//            
//            float packetPrSec = (float)BAUDRATE/bitLength;
//            float secDelay = 1.0/packetPrSec;
//            [NSThread sleepForTimeInterval:secDelay+0.015];

            //   [self setUpdateRate:secDelay];
            #ifdef DEBUG_LOG
                    NSLog(@"Send clock");
#endif
            [self writeBuffer];
            [NSThread sleepForTimeInterval:0.021];

            
                      
            //    NSLog(@"%i bytes",bytesSend);
            
            //                [NSThread sleepForTimeInterval:0.05];
            
            //  [nextValueSendTime release];
            //  nextValueSendTime = [[NSDate dateWithTimeIntervalSinceNow:updateRate+0.001] retain];
            
            
        }
        }
    //if(sendTime == nil || [sendTime timeIntervalSinceNow] < -0.5){
    if(time(NULL) > sendTime + 0.5){
        ArduinoLinkMessage msg;
        msg.type = ALIVE;
        msg.destination = 0;
        msg.moreComing = NO;
        msg.length = 0;
        [self serialBufferMessage:msg];
        [self writeBuffer];
    }

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

-(void) writeBuffer{
#ifdef DEBUG_LOG
    NSLog(@"Write %i bytes",outputBufferCounter);
#endif
    if(outputBufferCounter > 0){
        [self writeBytes:outputBuffer length:outputBufferCounter];
        
        int bitLength = outputBufferCounter * 8;
        
        float packetPrSec = (float)BAUDRATE/bitLength;
        float secDelay = 1.0/packetPrSec;
//        [NSThread sleepForTimeInterval:secDelay+0.01];
                [NSThread sleepForTimeInterval:secDelay+0.01];
       // printf("%f   ",secDelay+0.015);
        
      /*  if(sendTime)
            [sendTime release];
        sendTime = [[NSDate date] retain];
        */
        sendTime = time(NULL);
        
        outputBufferCounter = 0;


    }
    
    
    
}

- (void) bufferBytes: (unsigned char * ) bytes length:(int)length {
    if(length+outputBufferCounter > 127){
         NSLog(@"Buffer overflow!");

        [self writeBuffer];
        [NSThread sleepForTimeInterval:0.01];

        //        return;
    }
    memcpy(outputBuffer+outputBufferCounter, bytes, length);
    outputBufferCounter += length;
}









-(IBAction) statusUpdate:(id)sender{
    @synchronized(self){
        for(int i=0;i<NUM_CLIENTS;i++){
            [[[appDelegate clientStates] objectAtIndex:i] setValue:@"Pinging" forKey:@"status"];
            [[[appDelegate clientStates] objectAtIndex:i] setValue:@"-" forKey:@"voltage"];
        }
        pinging = YES;
    }
    
}

-(void)serialUpdateThread:(NSThread *)parentThread{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSThread setThreadPriority:1.0];
    startTime = [[[NSDate alloc] init] retain];
    demoMode = 0;
    while(TRUE) {
        //Test data
        if([testLedButton state]){

            
            for(int i=0;i<NUM_CLIENTS;i++){
                for(int u=0;u<NUM_PIXELS;u++){
                    
                    float r = (sin(-[startTime timeIntervalSinceNow]*1 + [self stripForPixel:u]) + 1)/2.0;
                    float g = (sin(-[startTime timeIntervalSinceNow]*1+3.14*2/3.0+ [self stripForPixel:u]) + 1)/2.0;
                    float b = (sin(-[startTime timeIntervalSinceNow]*1+3.14*2/3.0+3.14/3.0+ [self stripForPixel:u]) + 1)/2.0;
                    
                    clients[i].pixels[u].r = r;
                    clients[i].pixels[u].g = g;
                    clients[i].pixels[u].b = b;
                    
                } 
            }
            pixelsUpdated = YES;

        }        
        else if([TestPatternButton state]){
            if(demoMode == 0){
                demoR -= [demoTime timeIntervalSinceNow]*0.2;
                
                demoTime = [NSDate date];
                
                for(int i=0;i<NUM_CLIENTS;i++){
                    for(int u=0;u<NUM_PIXELS;u++){
                        if((float)u / NUM_PIXELS < demoR){
                            clients[i].pixels[u].r = 1;
                            clients[i].pixels[u].b = 0;
                        } else {
                            clients[i].pixels[u].r = 0;
                            clients[i].pixels[u].b = 0;
                        }
                        
                        clients[i].pixels[u].g = 0;
                    }
                }
                if(demoR > 1){
                    demoR = 0;
                    demoMode=1;
                }
            }
            if(demoMode == 1){
                demoG -= [demoTime timeIntervalSinceNow]*0.3;
                
                demoTime = [NSDate date];
                
                for(int i=0;i<NUM_CLIENTS;i++){
                    for(int u=0;u<NUM_PIXELS;u++){
                        if((float)u / NUM_PIXELS < demoG){
                            clients[i].pixels[u].g = 1;
                            clients[i].pixels[u].r = 0;
                        } else {
                            clients[i].pixels[u].g = 0;
                            clients[i].pixels[u].r = 1;
                        }
                        
                        clients[i].pixels[u].b = 0;
                    }
                }
                if(demoG > 1){
                    demoG = 0;
                    demoMode++;
                }
            }
            if(demoMode == 2){
                demoB -= [demoTime timeIntervalSinceNow]*0.5;
                
                demoTime = [NSDate date];
                
                for(int i=0;i<NUM_CLIENTS;i++){
                    for(int u=0;u<NUM_PIXELS;u++){
                        if((float)u / NUM_PIXELS < demoB){
                            clients[i].pixels[u].b = 1;
                            clients[i].pixels[u].g =0;
                        } else {
                            clients[i].pixels[u].b = 0;
                            clients[i].pixels[u].g = 1;
                        }
                        
                        clients[i].pixels[u].r = 0;
                    }
                }
                if(demoB > 1){
                    demoB = 0;
                    demoMode++;
                }
            }
            if(demoMode >= 3 && demoMode < 20){
                if([demoTime timeIntervalSinceNow] < 0){
                    for(int i=0;i<NUM_CLIENTS;i++){
                        
                        if(demoMode % 2 == 0){
                            for(int u=0;u<NUM_PIXELS;u++){
                                clients[i].pixels[u].b = .2;
                                clients[i].pixels[u].g = 0.2;
                                clients[i].pixels[u].r = 0.2;
                            }
                        } else {
                            for(int u=0;u<NUM_PIXELS;u++){
                                clients[i].pixels[u].b = .0;
                                clients[i].pixels[u].g = 0.0;
                                clients[i].pixels[u].r = 0.0;
                            }  
                        }
                    }
                    [demoTime release];
                    demoTime = [[NSDate dateWithTimeIntervalSinceNow:0.2] retain];
                    
                    demoMode++;
                }
            }
            if(demoMode == 20){
                float r = (sin(-[demoTime timeIntervalSinceNow]*5) + 1)/2.0;
                float g = (sin(-[demoTime timeIntervalSinceNow]*5+3.14/3.0) + 1)/2.0;
                float b = (sin(-[demoTime timeIntervalSinceNow]*5+3.14/3.0+3.14/3.0) + 1)/2.0;
                
                for(int i=0;i<NUM_CLIENTS;i++){
                    float r = (sin(-[demoTime timeIntervalSinceNow]*5+i) + 1 )/2.0;
                    float g = (sin(-[demoTime timeIntervalSinceNow]*5+i+3.14/3.0) + 1)/2.0;
                    float b = (sin(-[demoTime timeIntervalSinceNow]*5+i+3.14/3.0+3.14/3.0) + 1)/2.0;

                    for(int u=0;u<NUM_PIXELS;u++){
                        clients[i].pixels[u].r = r;
                        clients[i].pixels[u].g = g;
                        clients[i].pixels[u].b = b;
                        
                    } 
                }
                
                if([demoTime timeIntervalSinceNow] < -5)
                    demoMode++;
            }
            if(demoMode >= 21){
                demoMode = 0;
            }
            pixelsUpdated = YES;
        }
        
        //        for(int i=0;i<NUM_CLIENTS;i++){
        //            for(int u=0;u<NUM_PIXELS;u++){
        //                float b = (sin(-[startTime timeIntervalSinceNow]*5 + u) + 1)/2.0;
        //                float g = (sin(-[startTime timeIntervalSinceNow]*5 + u+3.14) + 1)/2.0;
        //                //                float b = (sin(-[startTime timeIntervalSinceNow] + u+3.14/3.0+3.14/3.0) + 1)/2.0;
        //                
        //                float r = test ;
        //                clients[i].pixels[u].r = r;
        //                clients[i].pixels[u].g = g;
        //                clients[i].pixels[u].b = b;
        //            }
        //        }
        
        
        if(!waitingForData){
            
            if(pinging){
                @synchronized(self){
                    //Ping!
                    
                    //        [self writeByte:'a'];
                    ArduinoLinkMessage msg;
                    msg.type = PING;
                    msg.destination = clientPingStatus;
                    msg.moreComing = NO;
                    msg.length = 0;
                    
                    [self serialWriteMessage:msg];
                    
                    waitingForData = YES;
                    
                    
                    NSLog(@"Ping %i",clientPingStatus);
                    
                    [pingTimeoutTime release];
                    pingTimeoutTime = [[NSDate dateWithTimeIntervalSinceNow:0.5] retain];
                    //         nextPingTime = [[NSDate dateWithTimeIntervalSinceNow:10.0] retain];
                }
            }
        }
        
        if(!waitingForData && !pinging){
            //  if((nextValueSendTime == nil || [nextValueSendTime timeIntervalSinceNow] < 0) && updateRate > 0){
            //@synchronized(self){
                [self sendValues];
           // }
            
            //  }          
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
                pinging = NO;
            } else {
                pinging = YES;
            }
            
            incommingMessagePos = 0;
        }
        //NSLog(@"%f", [pingTimeoutTime timeIntervalSinceNow]);
        
    }
    
    [pool release];
    
}

- (void) receivedMessage:(ArduinoLinkMessage)msg{
    [appDelegate logMessage:FORMAT(@"Receviced message %i from %i",msg.type, msg.sender)];
    
    /* if(sendTime){
     [appDelegate logMessage:FORMAT(@"Time: %f",-[sendTime timeIntervalSinceNow])];
     
     }
     */
    
    if(msg.type == STATUS){
        float R1 = 56000.0;    // !! resistance of R1 !!
        float R2 = 3900.0;     // !! resistance of R2 !!
        
        //Status 
        //    if(!clients[clientPingStatus].online){
        clients[clientPingStatus].online = YES;
        /*      [[[appDelegate clientStates] objectAtIndex:msg.sender] setValue:@"OK" forKey:@"status"];
         float value = 1024*msg.data[0]/512;
         float vout = (value*5.5) / 1024.0;
         float vin = vout / (R2/(R1+R2));  */
        //      vin += 0.7;
        
        [[[appDelegate clientStates] objectAtIndex:msg.sender] setValue:[NSString stringWithFormat:@"%fV",msg.data[0]/10.0] forKey:@"voltage"];
        //                    [[[appDelegate clientStates] objectAtIndex:msg.sender] setValue:[NSString stringWithFormat:@"%fV",vin] forKey:@"voltage"];
        //     }
        if(!msg.moreComing){
            waitingForData = NO;
        }
        
        clientPingStatus ++;
        if(clientPingStatus >= NUM_CLIENTS){
            clientPingStatus = 0;
            pinging = NO;
        }
        
    }
}


// This selector will be called as another thread
- (void)serialReadThread: (NSThread *) parentThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	readThreadRunning = TRUE;
    
	const int BUFFER_SIZE = 100;
	unsigned char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	ssize_t numBytes=0; // number of bytes read during read
	NSString *text; // incoming text from the serial port
	
	// assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(TRUE && xbeeConnected) {
		// read() blocks until some data is available or the port is closed
		numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
		if(numBytes>0) {
            @synchronized(self){
                
                for(int i=0;i<numBytes;i++){
                    unsigned char c = byte_buffer[i];
                    //     [appDelegate logMessage:FORMAT(@"Receviced byte %i",c)];
                    
                    if(incommingMessagePos == 0){
                        if(c != '#'){
                            incommingMessagePos = -1;
                            NSLog(@"NOT # at pos 0");
                        }
                    } 
                    else if(incommingMessagePos == 1){
                        incommingMessage.type = c & 0xF; 
                        incommingMessage.moreComing = c & 0x10;
                    } 
                    else if(incommingMessagePos == 2){
                        incommingMessage.destination = c & 0x0F; 
                        incommingMessage.sender = c >> 4; 
                    } 
                    else if(incommingMessagePos == 3){
                        incommingMessage.length = c; 
                        if( incommingMessage.length == 128)
                            incommingMessage.length = 0;
                        if(incommingMessage.length == 0){
                            incommingMessage.complete = true;
                        }       
                    } 
                    else if(incommingMessagePos >= 4) {
                        incommingMessage.data[incommingMessagePos-4] = c;
                        
                        if(incommingMessagePos - 3 == incommingMessage.length){
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



-(void) serialBufferMessage:(ArduinoLinkMessage)msg{
    unsigned char cmsg[msg.length + 6];
    cmsg[0] = '#';
    cmsg[1] = msg.type;
//    cmsg[2] = msg.destination + 0xF0; //0xF0 = MASTER
    cmsg[2] = msg.length;
    
    for(int i=0;i<msg.length;i++){
        cmsg[i+3] = msg.data[i];
    }
    [self bufferBytes:cmsg length:msg.length + 3];
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
        errorMessage = @"XBee not found";
        return errorMessage;
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
    //    options.c_cflag |= CRTSCTS;                              /*enable RTS/CTS flow control - linux only supports rts/cts*/
    //  options.c_cflag |= PARENB;
    
    
    tcsetattr(serialFileDescriptor,TCSANOW,&options);
    
    // make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	return errorMessage;
}
@end
