#include "LPD8806.h"
#include "SPI.h"

int dataPin = 2;   
int clockPin = 3; 

LPD8806 strip = LPD8806(32, dataPin, clockPin);

int incomingByte = 0;   // for incoming serial data

void setup() {
  // Start up the LED strip
  //  strip.begin();

  // Update the strip, to start they are all 'off'
  // strip.show();


  Serial.begin(9600);
}


void loop(){
  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();

    // say what you got:
    for (int i=0; i < strip.numPixels(); i++) {
      strip.setPixelColor(i, incomingByte, incomingByte, incomingByte);
    }  
    strip.show();   // write all the pixels out
  }
}



