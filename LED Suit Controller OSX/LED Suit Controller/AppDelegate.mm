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



@implementation AppDelegate

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
    [udpSocket sendData:data toHost:@"192.168.0.5" port:6466 withTimeout:-1 tag:0];
}

-(void) sendPing{
    [self sendData:[@"#P" dataUsingEncoding:NSUTF8StringEncoding]];;
    [self performSelector:@selector(sendPing) withObject:nil afterDelay:1.0];
}



-(void) sendValues{
    
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
        
       

    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    int port = 6466;
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
    
    [self logInfo:FORMAT(@"Udp server started on port %hu", [udpSocket localPort])];
    
    
    isRunning = YES;
    
        [self performSelector:@selector(sendPing) withObject:nil afterDelay:1.0];
        //[self performSelector:@selector(sendValues) withObject:nil afterDelay:0.0];
    NSThread * thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendValues) object:nil];
    [thread start];
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
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
        
    }
}

-(IBAction)sendTestValue:(id)sender{
    ledsTest[0] = int([sender floatValue]);
    
}

@end
