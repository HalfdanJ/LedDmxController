#include "LPD8806.h"
#include "SPI.h"
#include "ArduinoLinkDefines.h"

//------------------------------------
//------------------------------------

int clientId = 11;

//------------------------------------
//------------------------------------


int dataPin = 3;   
int clockPin = 2; 
long long masterTimeout = 0;
boolean masterOnline = false;

const int numStrips = 5;

LPD8806 strips[numStrips];


float vout = 0.0;
float vin = 0.0;
float R1 = 56000.0;    // !! resistance of R1 !!
float R2 = 3900.0;     // !! resistance of R2 !!
int value = 0;

long long lowBatTimeout = -1;

boolean lowVoltage = false;

int incomingByte = 0;   // for incoming serial data

void setup() {
  for(int i=0;i<numStrips;i++){
    strips[i] = LPD8806(38, dataPin+i, clockPin);
    strips[i].begin();

    for (int u=0; u < strips[i].numPixels(); u++) {
      strips[i].setPixelColor(u, 0,0,1);
    }  
    strips[i].show();
  }

  // Start up the LED strip


  // Update the strip, to start they are all 'off'

  Serial.begin(57600);

  pinMode(0, INPUT);

  msgSend.destination = 0x0F;
  msgSend.sender = clientId;    

  pinMode(13, OUTPUT);  

  pinMode(12, OUTPUT);  
  pinMode(11, OUTPUT);  
  pinMode(10, OUTPUT);  
  pinMode(9, OUTPUT);  
  pinMode(8, OUTPUT);  

  masterTimeout = 1000;
  masterOnline = true;
 
}


float voltage(){
  value = analogRead(0);

  vout = (value) / 1024.0;
  vin = 5.2*vout / (R2/(R1+R2));  
  // vin += 0.7;
  return vin;
}

void loop(){

  digitalWrite(12, HIGH);
  if(voltage() < 6.3){
    if(lowBatTimeout == -1){
      lowBatTimeout = millis()+1000;
    }
    else if(lowBatTimeout < millis()){

      lowVoltage = true; 

      for(int i=0;i<numStrips;i++){
        for (int u=0; u < strips[i].numPixels(); u++) {
          strips[i].setPixelColor(u, 0,0,0);
        }  
        strips[i].setPixelColor(0, 1,0,0);
        strips[i].show();
      }
    }
  } 
  else {
    lowBatTimeout = -1;
    // lowVoltage = false;
  }



  if(masterOnline && !lowVoltage){
    if(masterTimeout < millis()){
      masterTimeout = 0; 
      masterOnline = false;
      for(int i=0;i<numStrips;i++){
        for (int u=0; u < strips[i].numPixels(); u++) {
          strips[i].setPixelColor(u, 0,0,0);
        }  
        strips[i].setPixelColor(0, 0,0,1);
        strips[i].show();
      }
    }
  }


  ArduinoLinkMessage * msg = parseArduinoMessage();
  if(msg->complete){
    digitalWrite(9, HIGH);

    if(!masterOnline){
      for(int i=0;i<numStrips;i++){
        for (int u=0; u < strips[i].numPixels(); u++) {
          strips[i].setPixelColor(u, 0,0,0);
        }  
        strips[i].show();
      }
    }

    masterTimeout = millis() + 3000;
    masterOnline = true;

    if(msg->type == CLOCK && !lowVoltage){
      digitalWrite(10, HIGH);
      for(int i=0;i<numStrips;i++){
        strips[i].show();   // write all the pixels out
      }
    }

    if(msg->type == PING){
      digitalWrite(13, HIGH);

      msgSend.type = STATUS;
      msgSend.length = 1;
      msgSend.moreComing = 0;
      //

      //    value = analogRead(0);
      //              msgSend.data[0] = int(512*value/1024);
      msgSend.data[0] = int(voltage()*10);
      // delay(100);

      sendArduinoMessage();

    }

    if(msg->type == VALUES){
      unsigned char offset = msg->data[0];
      unsigned char pixels = (msg->length - 1)/3;
      for (int i=0; i < pixels; i++) {
        strips[0].setPixelColor(i+offset, msg->data[i*3+1], msg->data[i*3+2], msg->data[i*3+3]);
      }  
    }


    if(msg->type == BULK_VALUES){

      unsigned char strip = msg->data[0];
      unsigned char offset = msg->data[1];
      unsigned char pixels = msg->data[2];
      for (int i=0; i < pixels; i++) {
        strips[strip].setPixelColor(i+offset, msg->data[3], msg->data[4], msg->data[5]);
      }  
    }

    if(msg->type == BULK_STRIP_MULTI_SUIT){
      boolean destinationMatch;
      if(clientId < 9){
        destinationMatch = 0x01 & (msg->data[0] >> (clientId-1));
      } 
      else {
        destinationMatch = 0x01 & (msg->data[1] >> (clientId-9));        
      }
      if(destinationMatch){
        for(int i=0;i<numStrips;i++){
          if((1 << i) & msg->data[2]){
            for (int j=0; j < strips[i].numPixels(); j++) {
              strips[i].setPixelColor(j, msg->data[3], msg->data[4], msg->data[5]);
            }  
          }
        }
      }
    }
    
    
    if(msg->type == BULK_SEGMENT_MULTI_SUIT){

      boolean destinationMatch;
      if(clientId < 9){
        destinationMatch = 0x01 & (msg->data[0] >> (clientId-1));
      } 
      else {
        destinationMatch = 0x01 & (msg->data[1] >> (clientId-9));        
      }
      if(destinationMatch){
        unsigned char strip = msg->data[2];
        unsigned char offset = msg->data[3];
        unsigned char pixels = msg->data[4];
        for (int i=0; i < pixels; i++) {
          strips[strip].setPixelColor(i+offset, msg->data[5], msg->data[6], msg->data[7]);
        }  
      }
    }

    if(msg->type ==  BULK_ALL_STRIPS){
      digitalWrite(11, HIGH);
      //       digitalWrite(11, HIGH);
      boolean destinationMatch;
      if(clientId < 9){
        destinationMatch = 0x01 & (msg->data[0] >> (clientId-1));
      } 
      else {
        destinationMatch = 0x01 & (msg->data[1] >> (clientId-9));        
      }
      if(destinationMatch){
        for(int j=0;j<numStrips;j++){
          for (int i=0; i < strips[j].numPixels(); i++) {
            strips[j].setPixelColor(i, msg->data[2], msg->data[3], msg->data[4]);
          }  
        }
      }

    }


  }

  digitalWrite(8, LOW);
  digitalWrite(9, LOW);
  digitalWrite(10, LOW);
  digitalWrite(11, LOW);
  digitalWrite(12, LOW);
  digitalWrite(13, LOW);
}


























