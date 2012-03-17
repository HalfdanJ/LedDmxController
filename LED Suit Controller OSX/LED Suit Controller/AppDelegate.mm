//
//  AppDelegate.m
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XbeeController.h"


@implementation AppDelegate
@synthesize testPatternButton;

@synthesize window, logView, clientStates;

- (id)init {
    self = [super init];
    if (self) {
        //       artnetController = [[ArtnetController alloc] init];
        clientStates = [NSMutableArray arrayWithCapacity:0];
        for(int i=0;i<20;i++){
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];
            [dict setValue:[NSNumber numberWithInt:i] forKey:@"clientId"];
            [dict setValue:@" - " forKey:@"status"];
            
            [clientStates addObject:dict];
            artnetReceived = NO;
            for(int i=0;i<512*12;i++){
                values[i] = 0;
            }
        }
        
        for(int i=0;i<8;i++){
            universeReceived[i] = NO;
        }
    }
    return self;
}

- (void)awakeFromNib
{
	[logView setEnabledTextCheckingTypes:0];
	[logView setAutomaticSpellingCorrectionEnabled:NO];
}

- (void)scrollToBottom
{
	NSScrollView *scrollView = [logView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}


- (void)dealloc
{
    [super dealloc];
}


- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"Arduino log: %@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

-(void) sendData:(NSData*)data{
    //  [udpSocket sendData:data toHost:@"localhost" port:6454 withTimeout:-1 tag:0];
}

-(void) sendPing{
    // [self sendData:[@"#P" dataUsingEncoding:NSUTF8StringEncoding]];;
    // [self performSelector:@selector(sendPing) withObject:nil afterDelay:1.0];
}



-(void) sendValues{
    /*
     while(1){
     count++;
     [self sendTestValue:[NSNumber numberWithFloat:50*(sin((count)/100.0)+1)/2.0]];
     
     
     int leds = 32;
     
     for(int i=1;i<leds;i++){
     ledsTest[i] = ledsTest[i] * 0.9 + ledsTest[i-1]*0.1;
     }
     
     int num = leds*3;
     unsigned char msg[3+num];
     msg[0] = '#';
     msg[1] = 'V';
     msg[2] = 0;
     msg[3] = num;    
     for(int i=0;i<leds;i++){
     msg[i*3+4] =  ledsTest[i];
     // NSLog(@"%i",msg[i+4]);
     msg[i*3+5] =  ledsTest[i];
     msg[i*3+6] =  ledsTest[i];
     }
     NSData * data = [NSData dataWithBytes:msg length:num+4];
     
     [self sendData:data];
     
     //   [self performSelector:@selector(sendValues) withObject:nil afterDelay:0.01];
     [NSThread sleepForTimeInterval:0.01];
     
     
     
     }*/
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    int port = 6454;
    NSError *error = nil;
    
    if (![udpSocket bindToPort:port error:&error])
    {
        [self logError:FORMAT(@"Error starting server (bind): %@", error)];
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        
        [self logError:FORMAT(@"Error starting server (recv): %@", error)];
        return;
    }
    
    [self logInfo:FORMAT(@"Artnet receiver started on port %hu", [udpSocket localPort])];
    
    
    isRunning = YES;
    
    // [self performSelector:@selector(sendPing) withObject:nil afterDelay:1.0];
    //[self performSelector:@selector(sendValues) withObject:nil afterDelay:0.0];
    // NSThread * thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendValues) object:nil];
    // [thread start];
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if(![testPatternButton state]){   
        NSString * string = [NSString stringWithCString:((const  char*)[data bytes]) encoding:NSUTF8StringEncoding];
        if([string length] > 6 && [[string substringToIndex:7] isEqualToString:@"Art-Net"]){
            if(!artnetReceived){
                artnetReceived = YES;
                [self logInfo:@"Artnet data received!"];
            }
            
            [[xbee lock] lock];
            // NSLog(@"String: %@",string);
            //   NSLog(@"%i %i",((unsigned char*)[data bytes])[14], ((unsigned char*)[data bytes])[15]);
            int universe = ((unsigned char*)[data bytes])[14]+1;
            universeReceived[universe-1] = YES;
            for(int i=0;i<512;i++){
                values[i+2+510*(universe-1)] = ((unsigned char*)[data bytes])[18+i];
            }
            
          /*  if(universe == 1){
                NSLog(@"%i: %i ",universe, values[2]);
            }
            */
            //    if(universe == 1){
            //            for(int i=0;i<512;i++){
            
            int base = 1;
            for(int j=0;j<11;j++){
                
                //                int adr = 31;          
                int adr = 31;
                for(int i=0;i<24;i++){ //right breast
                    [xbee client:j]->pixels[i].r = values[base+adr++]/255.0;
                    [xbee client:j]->pixels[i].g = values[base+adr++]/255.0;
                    [xbee client:j]->pixels[i].b = values[base+adr++]/255.0; 
                }
                
                adr = 109; //left breast
                for(int i=0;i<24;i++){
                    [xbee client:j]->pixels[i+38].r = values[base+adr++]/255.0;
                    [xbee client:j]->pixels[i+38].g = values[base+adr++]/255.0;
                    [xbee client:j]->pixels[i+38].b = values[base+adr++]/255.0; 
                }
                
                for(int i=0;i<8;i++){ //right lower arm
                    [xbee client:j]->pixels[i+24].r = values[base+13]/255.0;
                    [xbee client:j]->pixels[i+24].g = values[base+14]/255.0;
                    [xbee client:j]->pixels[i+24].b = values[base+15]/255.0; 
                }
                for(int i=0;i<6;i++){ //right ydderst arm
                    [xbee client:j]->pixels[i+32].r = values[base+16]/255.0;
                    [xbee client:j]->pixels[i+32].g = values[base+17]/255.0;
                    [xbee client:j]->pixels[i+32].b = values[base+18]/255.0; 
                }
                
                for(int i=0;i<8;i++){ //left lower arm
                    [xbee client:j]->pixels[i+62].r = values[base+19]/255.0;
                    [xbee client:j]->pixels[i+62].g = values[base+20]/255.0;
                    [xbee client:j]->pixels[i+62].b = values[base+21]/255.0; 
                }
                for(int i=0;i<6;i++){ //left ydderst arm
                    [xbee client:j]->pixels[i+70].r = values[base+22]/255.0;
                    [xbee client:j]->pixels[i+70].g = values[base+23]/255.0;
                    [xbee client:j]->pixels[i+70].b = values[base+24]/255.0; 
                }
                
                
                for(int i=0;i<16;i++){ //right upper leg
                    [xbee client:j]->pixels[i+76].r = values[base+1]/255.0;
                    [xbee client:j]->pixels[i+76].g = values[base+2]/255.0;
                    [xbee client:j]->pixels[i+76].b = values[base+3]/255.0; 
                }
                for(int i=0;i<10;i++){ //right lower leg
                    [xbee client:j]->pixels[i+16+76].r = values[base+4]/255.0;
                    [xbee client:j]->pixels[i+16+76].g = values[base+5]/255.0;
                    [xbee client:j]->pixels[i+16+76].b = values[base+6]/255.0; 
                }
                for(int i=0;i<16;i++){ //left upper leg
                    [xbee client:j]->pixels[i+26+76].r = values[base+7]/255.0;
                    [xbee client:j]->pixels[i+26+76].g = values[base+8]/255.0;
                    [xbee client:j]->pixels[i+26+76].b = values[base+9]/255.0; 
                }
                for(int i=0;i<10;i++){ //left lower leg
                    [xbee client:j]->pixels[i+34+76+8].r = values[base+10]/255.0;
                    [xbee client:j]->pixels[i+34+76+8].g = values[base+11]/255.0;
                    [xbee client:j]->pixels[i+34+76+8].b = values[base+12]/255.0; 
                }
                
                
                for(int i=0;i<14;i++){ //neck lower
                    [xbee client:j]->pixels[i+0+76+44+8].r = values[base+25]/255.0;
                    [xbee client:j]->pixels[i+0+76+44+8].g = values[base+26]/255.0;
                    [xbee client:j]->pixels[i+0+76+44+8].b = values[base+27]/255.0; 
                }
                for(int i=0;i<16;i++){ //neck lower
                    [xbee client:j]->pixels[i+14+76+44+8].r = values[base+28]/255.0;
                    [xbee client:j]->pixels[i+14+76+44+8].g = values[base+29]/255.0;
                    [xbee client:j]->pixels[i+14+76+44+8].b = values[base+30]/255.0; 
                }
                
                
                base += 62*3;
                
//
            }
         //         NSLog(@"Universe %i",universe);           
            /*
            if(universe == 5){
            BOOL update = YES;
            for(int i=0;i<5;i++){
                if(!universeReceived[i])
                    update = NO;

            }
            if(update){
                NSLog(@"Update");
                [xbee setPixelsUpdated:YES];
                for(int i=0;i<8;i++){
                    universeReceived[i] = NO;
                }
            }
            }
              */
            [xbee setPixelsUpdated:YES];
            [[xbee lock] unlock];
            
            //  }
            
            
        }
    }
    /*    
     if(((unsigned char*)[data bytes])[0] == '#'){
     NSData * sdata = [data subdataWithRange:NSMakeRange(2, [data length]-2)];
     
     unsigned char task = ((unsigned char*)[data bytes])[1];
     if(task == 'M'){
     NSString *msg = [[[NSString alloc] initWithData:sdata encoding:NSUTF8StringEncoding] autorelease];
     if (msg)
     {
     [self logMessage:msg];
     }
     else
     {
     [self logError:@"Error converting received data into UTF-8 String"];
     }
     }
     
     if(task == 'S'){
     unsigned char * bytes = (unsigned char *) [sdata bytes];
     int index = 0;
     
     int numClients = bytes[index++];
     
     for(int i=0;i<numClients;i++){
     unsigned char state = bytes[index++];
     if(state){
     [[clientStates objectAtIndex:i] setValue:@"OK" forKey:@"status"];
     } else {
     [[clientStates objectAtIndex:i] setValue:@"offline" forKey:@"status"];                    
     }
     }
     
     }
     
     }*/
}

-(IBAction)sendTestValue:(id)sender{
    // ledsTest[0] = int([sender floatValue]);
    
}

@end
