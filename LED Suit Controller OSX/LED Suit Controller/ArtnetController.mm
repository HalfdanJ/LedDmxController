//
//  ArtnetController.m
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 20/02/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import "ArtnetController.h"

using namespace std;
using namespace ola;

class MyObserver : public OlaClientObserver {
    public:
    __weak ArtnetController * controller;
    
    void Plugins(const vector<class OlaPlugin> &plugins, const string &error){
        NSLog(@"Plugins");
    }
    

};




@implementation ArtnetController
@synthesize serverConnected;

- (id)init {
    self = [super init];
    if (self) {
        [self connectClient];
    }
    return self;
}

-(void) connectClient {
    if (!simpleClient.Setup()) {
        NSLog(@"Client setup failed");
        serverConnected = NO;
    }
    serverConnected = YES;
    
    
    observer = new MyObserver;
        observer->controller = self;
    
    olaClient = simpleClient.GetClient();
    olaClient->SetObserver(observer);
    
    olaClient->FetchPluginList();

}


-(NSString *)artnetStatus{
    if(!serverConnected){
        return @"Error";
    } else {
        return @"OK";
    }
}

+(NSSet *)keyPathsForValuesAffectingArtnetStatus{
    return [NSSet setWithObjects:@"serverConnected", nil];
}



@end
