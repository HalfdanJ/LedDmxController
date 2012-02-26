#include "LPD8806.h"
#include "SPI.h"
#include "ArduinoLinkDefines.h"

int clientId = 0;

int dataPin = 3;   
int clockPin = 4; 
long long masterTimeout = 0;
boolean masterOnline = false;

LPD8806 strip = LPD8806(32, dataPin, clockPin);

int incomingByte = 0;   // for incoming serial data

void setup() {
  // Start up the LED strip
  strip.begin();

  // Update the strip, to start they are all 'off'

  for (int i=0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, 0,0,1);
  }  
  strip.show();


  Serial.begin(19200);

  msgSend.destination = CENTRAL;
  msgSend.sender = clientId;    

  pinMode(13, OUTPUT);  

}


void loop(){
  if(masterOnline){
    if(masterTimeout < millis()){
      masterTimeout = 0; 
      masterOnline = false;

      for (int i=0; i < strip.numPixels(); i++) {
        strip.setPixelColor(i, 1,0,0);
      }  
      strip.show();
    }
  }
  /* if (Serial.available() > 0) {
   // read the incoming byte:
   incomingByte = Serial.read();
   
   // say what you got:
   for (int i=0; i < strip.numPixels(); i++) {
   strip.setPixelColor(i, incomingByte, incomingByte, incomingByte);
   }  
   strip.show();   // write all the pixels out
   }
   
   Serial.println("hej");
   delay(1000);*/

  ArduinoLinkMessage * msg = parseArduinoMessage();
  if(msg->complete && msg->destination == clientId){
    masterTimeout = millis() + 1000;
    masterOnline = true;
    digitalWrite(13, HIGH);
    if(msg->type == TYPE_PING){
      msgSend.type = TYPE_STATUS;
      msgSend.length = 0;
      msgSend.moreComing = 0;
      // delay(100);

      sendArduinoMessage();

    }

    if(msg->type == TYPE_VALUES){
      unsigned char offset = msg->data[0];
      unsigned char pixels = (msg->length - 1)/3;
      for (int i=0; i < pixels; i++) {
        strip.setPixelColor(i+offset, msg->data[i*3+1], msg->data[i*3+2], msg->data[i*3+3
          ]);
      }  
      strip.show();   // write all the pixels out
      /*
      msgSend.type = 'A';
       msgSend.length = 0;
       msgSend.moreComing = 0;
       sendArduinoMessage();*/

    }
    if(msg->type == TYPE_BULK_VALUES){
      unsigned char offset = msg->data[0];
      unsigned char pixels = msg->data[1];
      for (int i=0; i < pixels; i++) {
        strip.setPixelColor(i+offset, msg->data[2], msg->data[3], msg->data[4]);
      }  
      strip.show();   // write all the pixels out
      /*
      msgSend.type = 'A';
       msgSend.length = 0;
       msgSend.moreComing = 0;
       sendArduinoMessage();*/

    }


  }
  // delay(1);
  digitalWrite(13, LOW);

}












