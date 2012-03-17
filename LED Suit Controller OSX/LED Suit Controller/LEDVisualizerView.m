//
//  LEDVisualizerView.m
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 06/03/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//

#import "LEDVisualizerView.h"

@implementation LEDVisualizerView

- (id)initWithFrame:(NSRect)frame {
	
	/*NSOpenGLPixelFormatAttribute att[] = 
     {
     NSOpenGLPFAWindow,
     NSOpenGLPFADoubleBuffer,
     NSOpenGLPFAColorSize, 24,
     NSOpenGLPFAAlphaSize, 8,
     NSOpenGLPFADepthSize, 24,
     NSOpenGLPFANoRecovery,
     NSOpenGLPFAAccelerated,
     0
     };
     
     NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:att]; 
     
     
     [pixelFormat release];
     */
    if(self = [super initWithFrame:frame]) {
	}
	
    
    
	
	return self;
}

- (void)prepareOpenGL
{
    glShadeModel(GL_SMOOTH);
    glEnable(GL_NORMALIZE);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_COLOR_MATERIAL);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glClearColor(0, 0, 0, 0.0f);
    GLfloat light_diffuse[] = { 1, 1, 1, 1 };
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
    GLfloat light_position[] = { 0, 0, 5, 1 };
    glLightfv(GL_LIGHT0, GL_POSITION, light_position);
    
    { //A
        strips[0].xStart = -0.1;
        strips[0].yStart = 0.2;        
        strips[0].xDir = -0.5;
        strips[0].yDir = 0.5;        
        strips[0].num = 8;
        
        strips[1].xStart = -0.4;
        strips[1].yStart = 0.6;        
        strips[1].xDir = 0.5;
        strips[1].yDir = -0.5;        
        strips[1].num = 12;
        
        strips[2].xStart = -0.1;
        strips[2].yStart = 0.4;        
        strips[2].xDir = -0.5;
        strips[2].yDir = 0.5;        
        strips[2].num = 4;
        
        strips[3].xStart = -0.4;
        strips[3].yStart = 0.7;        
        strips[3].xDir = -1;
        strips[3].yDir = 0;        
        strips[3].num = 8;
        
        strips[4].xStart = -0.8;
        strips[4].yStart = 0.65;        
        strips[4].xDir = -0.2;
        strips[4].yDir = -0.8;        
        strips[4].num = 6;
        
        //Copy right
        for(int i=0;i<5;i++){
            strips[5+i].xStart = -strips[i].xStart;
            strips[5+i].yStart = strips[i].yStart;
            strips[5+i].xDir = -strips[i].xDir;
            strips[5+i].yDir = strips[i].yDir;
            strips[5+i].num = strips[i].num;
        }
    }
    
    { //B
        strips[10].xStart = -0.1;
        strips[10].yStart = 0.15;        
        strips[10].xDir = -0.3;
        strips[10].yDir = -0.7;        
        strips[10].num = 16;
        
        strips[11].xStart = -0.35;
        strips[11].yStart = -0.4;        
        strips[11].xDir = -0.2;
        strips[11].yDir = -0.8;        
        strips[11].num = 10;
        
        
        //Copy right
        for(int i=0;i<2;i++){
            strips[12+i].xStart = -strips[10+i].xStart;
            strips[12+i].yStart = strips[10+i].yStart;
            strips[12+i].xDir = -strips[10+i].xDir;
            strips[12+i].yDir = strips[10+i].yDir;
            strips[12+i].num = strips[10+i].num;
        }
    }
    
    {//C
        strips[14].xStart = 0;
        strips[14].yStart = 0;        
        strips[14].xDir = -0;
        strips[14].yDir = 1;        
        strips[14].num = 14;
        
        strips[15].xStart = 0.05;
        strips[15].yStart = 0.9;        
        strips[15].xDir = -0;
        strips[15].yDir = -1;        
        strips[15].num = 16;
        
    }
    
}

- (void) animationTimerFired: (NSTimer *) timer
{
	[ self setNeedsDisplay: YES ] ;
}

-(void)reshape {
    //    glViewport(0,0,[self bounds].size.width,[self bounds].size.height);
    const NSSize size = self.bounds.size;
    glViewport(0,0,size.width,size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0f,size.width/size.height,0.1f,100.0f);
    
}

-(void)drawRect:(NSRect)dirtyRect{
    animationTimer=[ [ NSTimer scheduledTimerWithTimeInterval:0.017 target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES ] retain ] ;
    
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glTranslatef(0.0f,0.0f,-2);
    glColor3f(1,0,0);
    
    // glutSolidCube(2);
    /*
     glClearColor(0, 0, 0, 1.0);
     glLoadIdentity();
     glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT+GL_STENCIL_BUFFER_BIT);
     */
    
    glPushMatrix();
    glScaled(0.37, 0.37, 1);
    glTranslated(-5, 0.3, 0);

    for(int j=0;j<11;j++){
        float scale = 0.05;
        int pixel = 0;
        for(int i=0;i<numStrips;i++){
            glColor4f(0.3, 0.3, 0.3,1);
        
            glBegin(GL_LINES);
            glVertex2d(strips[i].xStart, strips[i].yStart);
            glVertex2d(strips[i].xDir * scale * strips[i].num + strips[i].xStart, strips[i].yDir * scale * strips[i].num + strips[i].yStart);
            //        glVertex2d(0, 0);
            //      glVertex2d(1, 1);
            glEnd();
        }
        Client * client = [xbee client:j];
        for(int i=0;i<numStrips;i++){
            glBegin(GL_QUADS);
            
            float size = 0.012;
            for(int u=0;u<strips[i].num;u++){
                if(pixel < NUM_PIXELS){
                    glColor4f(client->sendPixels[pixel].r, client->sendPixels[pixel].g, client->sendPixels[pixel++].b, 1.0);
                    
                    if(client->sendPixels[pixel].justSend){
                        client->sendPixels[pixel].justSend = NO;
                        glColor4f(1.0,0,0, 0.1);
                    }
                    // glColor4f(client->pixels[pixel].b, client->pixels[pixel].r, client->pixels[pixel++].g, 1.0);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) - size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) - size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) + size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) - size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) + size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) + size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) - size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) + size);
                }
            }
            
            glEnd();
            
            
        }
        pixel = 0;

        for(int i=0;i<numStrips;i++){            
            glBegin(GL_QUADS);
            float size = 0.02;
            for(int u=0;u<strips[i].num;u++){
                if(pixel < NUM_PIXELS){
                  //  glColor4f(client->sendPixels[pixel].b, client->sendPixels[pixel].r, client->sendPixels[pixel++].g, 1.0);
                      glColor4f(client->pixels[pixel].r, client->pixels[pixel].g, client->pixels[pixel++].b, 1.0);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) - size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) - size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) + size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) - size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) + size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) + size);
                    
                    glVertex2d(strips[i].xStart + strips[i].xDir * scale * (u+0.5) - size , 
                               strips[i].yStart + strips[i].yDir * scale * (u+0.5) + size);
                }
            }
            glEnd();

        }
                if(j%2 == 0){
            glTranslated(0, -1, 0);
        } else {
            glTranslated(0, 1, 0);
        }
        glTranslated(1, 0, 0);
        
    }
    glPopMatrix();
    
    [[self openGLContext] flushBuffer];
}

@end
