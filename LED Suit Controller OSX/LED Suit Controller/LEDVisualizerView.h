//
//  LEDVisualizerView.h
//  LED Suit Controller
//
//  Created by Jonas Jongejan on 06/03/12.
//  Copyright (c) 2012 HalfdanJ. All rights reserved.
//


#include <OpenGL/OpenGL.h>
#include <GLUT/GLUT.h>
#import "XbeeController.h"

#define numStrips 16
typedef struct {
    float xStart;
    float yStart;
    float xDir;
    float yDir;
    
    int num;
    
} strip;
@interface LEDVisualizerView : NSOpenGLView{
    strip strips[numStrips];
    
    IBOutlet XbeeController * xbee;
    NSTimer *animationTimer;
}
@end
