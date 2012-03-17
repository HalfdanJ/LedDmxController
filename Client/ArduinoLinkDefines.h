const int MAX_DATA_SIZE = 255;
/*unsigned char TYPE_PING = 'P';
unsigned char TYPE_STATUS = 'S';
unsigned char TYPE_VALUES = 'V';
unsigned char TYPE_BULK_VALUES = 'B';*/

unsigned char CENTRAL = 15;

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

enum ProtocolTypes {
  PING = 0x01,
  STATUS = 0x02,
  VALUES = 0x03,
  BULK_VALUES = 0x04,
  CLOCK = 0x05,
  ALIVE = 0x06
};


ArduinoLinkMessage  msgSend;

void sendArduinoMessage(){
  Serial.write('#');
/*  Serial.write(STATUS);
  Serial.write(0x0F);
  Serial.write((byte)0x00);*/
  Serial.write(msgSend.type + msgSend.moreComing * 0x10);
  Serial.write(msgSend.destination + (msgSend.sender << 4));
  Serial.write(msgSend.length);
  if(msgSend.length > 0){
    Serial.write(msgSend.data, msgSend.length);
  }
}



char incommingPos = 0;
ArduinoLinkMessage msgCache;

ArduinoLinkMessage * parseArduinoMessage(){ 
  msgCache.complete = false;

  while(Serial.available()){
    unsigned char c = Serial.read();
        digitalWrite(8, HIGH);
                         //   digitalWrite(13, HIGH);
    if(incommingPos == 0){
      //      Serial.println("START");
      if(c != '#'){
        incommingPos = -1;
      } else {
      }
    } 
    else if(incommingPos == 1){
      //      Serial.println("TYPE");
      msgCache.type = c & 0xF;
      msgCache.moreComing = c & 0x10;
    } 
    else if(incommingPos == 2){
      //     Serial.println("DEST");
      msgCache.sender = c >> 4;
      msgCache.destination = c & 0xF; 
    } 
    else if(incommingPos == 3){
      //     Serial.println("DEST");
      msgCache.length = c; 
//                            digitalWrite(13, HIGH);

      if(msgCache.length == 0){
        incommingPos = -1;
        msgCache.complete = true;
      }
    } 
    else if(incommingPos >= 4) {
      //  Serial.println("DATA");

      msgCache.data[incommingPos-4] = c;

      if(incommingPos - 3 >= msgCache.length){
        //   Serial.println("DONE");

        incommingPos = -1;
        msgCache.complete = true;
      }
    }

    incommingPos++;
  }
  return &msgCache;
}






