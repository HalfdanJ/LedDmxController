//
//  ArtnetController.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ola/DmxBuffer.h>
#import <ola/SimpleClient.h>

class MyObserver;

@interface ArtnetController : NSObject{
    ola::SimpleClient simpleClient;
    ola::OlaClient * olaClient;
    ola::DmxBuffer olaBuffer;
    
    MyObserver * observer;
    
    BOOL serverConnected;
}

@property (readonly) BOOL serverConnected;
@property (readonly) NSString * artnetStatus;

-(void) connectClient;

@end
