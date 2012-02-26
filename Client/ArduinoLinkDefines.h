const int MAX_DATA_SIZE = 255;
unsigned char TYPE_PING = 'P';
unsigned char TYPE_STATUS = 'S';
unsigned char TYPE_VALUES = 'V';
unsigned char TYPE_BULK_VALUES = 'B';

unsigned char CENTRAL = 254;

struct ClientState {
  boolean online;
  char timeout;
};



struct ArduinoLinkMessage {
  unsigned char type;
  unsigned char destination;
  unsigned char sender;
  unsigned char length;
  boolean moreComing;
  boolean complete;
  unsigned char data[MAX_DATA_SIZE]; 
};


ArduinoLinkMessage  msgSend;

void sendArduinoMessage(){
  Serial.write("#");
  Serial.write(msgSend.type);
  Serial.write(msgSend.destination);
  Serial.write(msgSend.sender);
  Serial.write(msgSend.length);
  Serial.write(msgSend.moreComing);
  if(msgSend.length > 0){
    Serial.write(msgSend.data, msgSend.length);
  }
}



char incommingPos = 0;
ArduinoLinkMessage msgCache;

ArduinoLinkMessage * parseArduinoMessage(){ 
  msgCache.complete = false;

  while(Serial.available()){
     //   digitalWrite(13, HIGH);
    if(incommingPos == 0){
//      Serial.println("START");

      if(Serial.read() != '#'){
        incommingPos = -1;
      }
    } 
    else if(incommingPos == 1){
//      Serial.println("TYPE");

      msgCache.type = Serial.read(); 
    } 
    else if(incommingPos == 2){
 //     Serial.println("DEST");

      msgCache.destination = Serial.read(); 
    } 
    else if(incommingPos == 3){
 //     Serial.println("DEST");

      msgCache.sender = Serial.read(); 
    } 
    else if(incommingPos == 4){
  //    Serial.println("LENGTH1");

      msgCache.length = Serial.read(); 
    } 
  
    else if(incommingPos == 5){
    //  Serial.println("MORE");

      msgCache.moreComing = Serial.read(); 

      if(msgCache.length == 0){
    //    Serial.println("DONE WITHOUT DATA");

        incommingPos = -1;
        msgCache.complete = true;
      }
    } 
    else if(incommingPos >= 6) {
    //  Serial.println("DATA");

      msgCache.data[incommingPos-6] = Serial.read();

      if(incommingPos - 5 == msgCache.length){
     //   Serial.println("DONE");

        incommingPos = -1;
        msgCache.complete = true;
      }
    }

    incommingPos++;
  }
  return &msgCache;
}





