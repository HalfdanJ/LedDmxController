#include <SPI.h>        
#include <Ethernet.h>
#include <EthernetUdp.h>
#include "ArduinoLinkDefines.h"

#define short_get_high_byte(x) ((HIGH_BYTE & x) >> 8)
#define short_get_low_byte(x)  (LOW_BYTE & x)
#define bytes_to_short(h,l) ( ((h << 8) & 0xff00) | (l & 0x00FF) );
/*
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
 IPAddress ip(2, 0, 0, 4);
 //IPAddress ip(192, 168, 1, 177);
 byte gateway[] = { 2,0,0,1 };
 byte subnet[] = { 255,0,0,0 };*/

byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; //MAC address to use
byte ip[] = { 
  192, 168, 0, 5 }; // Arduino's IP address
byte gw[] = { 
  192, 168, 0, 1 };   // Gateway IP address
byte subnet[] = { 
  255,0,0,0 };
// the next two variables are set when a packet is received
byte remoteIp[4];        // holds received packet's originating IP
unsigned int remotePort; // holds received packet's originating port

//artnet parameters
unsigned int localPort = 6454;      // artnet port
const int numberDmxChannels=512;
const int artnetPacketSize = 17+numberDmxChannels+1;

// buffers
const int MAX_BUFFER_UDP=600;
char packetBuffer[MAX_BUFFER_UDP]; //buffer de stockage de la trame entrante
//unsigned char buffer_dmx[512]; //dmx storage

//Art-Net identification variables
char ArtNetHead[8]="Art-Net";
char OpHbyteReceive=0;
char OpLbyteReceive=0;
short is_artnet_version_1=0;
short is_artnet_version_2=0;
short seq_artnet=0;
short artnet_physical=0;
short incoming_universe=0;
boolean is_opcode_is_dmx=0;
boolean is_opcode_is_artpoll=0;
boolean match_artnet=1;
short Opcode=0;


EthernetUDP Udp;



//--- Clients
const int numLeds1 = 32*3;

struct ClientLEDS {
  unsigned char strip1[numLeds1]; 
};


const char numClients = 1;
long long pingTime = 0;
long long pingTimeout = 0;
long long valueUpdateTime = 0;
char receiveMode = -1;
char pingClient = 0;
ClientState clients[numClients];
ClientLEDS leds[numClients];



//--- Computer link

EthernetUDP ComputerUdp;
int computerUdpPort = 6466;
boolean computerConnected = false;
uint32_t computerIp;
long long statusTime = 0;

unsigned char COMPUTER_MSG = 'M';

void logMsg(char* msg){
  ComputerUdp.beginPacket(computerIp, computerUdpPort);
  ComputerUdp.write("#M");
  ComputerUdp.write(msg);
  ComputerUdp.endPacket();
  delay(10);
}

void setup(){
  Ethernet.begin(mac,ip, gw, subnet);
  Udp.begin(localPort);
  ComputerUdp.begin(computerUdpPort);

  arduinoLinkSetup();

  computerConnected = false;
  // Serial.println("Hello computer!");
  //Serial.println(Ethernet.localIP());
  // Serial.println(artnetPacketSize);
}

void loop(){
//  if(valueUpdateTime < millis()){
    if(receiveMode == -1){
      valueUpdateTime = millis() + 1;
      for(int i=0;i<numClients;i++){
        msgSend.type = TYPE_VALUES;
        msgSend.destination = i;
        msgSend.sender = CENTRAL;
        msgSend.length = numLeds1+1;
        msgSend.moreComing = 0;

        msgSend.data[0] = 0;
        for(int j=0;j<numLeds1;j++){
          msgSend.data[j+1] = leds[i].strip1[j];
        //msgSend.data[j+1] = int(millis()/100.0)%50;
        }
       // Serial.println(int(millis()/100.0)%50);
       sendArduinoMessage();
      }
    }
 // }


  if(millis() > pingTimeout){
    receiveMode = -1;
  }
  if(millis() > pingTime){
    pingTime = millis() + 2000;
    pingTimeout = millis()+ 1000;
    pingClient ++;
    if(pingClient >= numClients){
      pingClient = 0;
    }
    receiveMode = pingClient;

    msgSend.type = TYPE_PING;
    msgSend.destination = pingClient;
    msgSend.sender = CENTRAL;
    msgSend.length = 0;
    msgSend.moreComing = 0;

    clients[receiveMode].timeout --;
    if( clients[receiveMode].timeout <= 0){
      clients[receiveMode].timeout = 0;
      if( clients[receiveMode].online){
        clients[receiveMode].online = false; 
        //  logMsg("Client offline");
      }
    }

    sendArduinoMessage();
  }



  int packetSize = Udp.parsePacket();
  if(packetSize){
    // Serial.println(packetSize);
  }

  packetSize = ComputerUdp.parsePacket();
  if(packetSize){
    // Serial.println("Computer udp");
    // Serial.println(packetSize);
    ComputerUdp.read(packetBuffer,MAX_BUFFER_UDP);
    //Serial.print(packetBuffer);
    if(packetBuffer[0] == '#'){


      computerIp = ComputerUdp.remoteIP();

      if(!computerConnected){
        //logMsg("Hello computer!"); //Wont work on mega :S
      }
      computerConnected = true;

      if(packetBuffer[1] == 'V'){ //LED Value
        unsigned char num = packetBuffer[3];
        for(int i=0;i<numClients;i++){

          for(int j=0;j<num;j++){
            leds[i].strip1[j] = packetBuffer[3+j];
          }
        }
      }
    }
    if(packetBuffer[1] == 'P'){ //LED Value
      //  logMsg("Yay");
      //    for(int i=0;i<numClients;i++){
      //  }

      // logMsg("Ping");
    }

  }


  //Computer status

  if(computerConnected && statusTime < millis()){
    statusTime = millis() + 1000;

    ComputerUdp.beginPacket(computerIp, computerUdpPort);
    ComputerUdp.write("#S");
    ComputerUdp.write(numClients);

    for(int i=0;i<numClients;i++){
      ComputerUdp.write(clients[i].online);
    }

    ComputerUdp.endPacket();

  }



  ArduinoLinkMessage * msg = parseArduinoMessage();
  if(msg->complete && msg->destination == CENTRAL){
    if(receiveMode != msg->sender){
      logMsg("Wrong sender in received message!");
    } 
    else {
      if(!clients[receiveMode].online){
        //      logMsg("Client online");
        clients[receiveMode].online = true;
      }
      clients[receiveMode].timeout = 3;

      logMsg("Got message!");
      if(!msg->moreComing){
        receiveMode = -1;
      }
    }
    //     Serial.println("GOT MSG COMPLETE");

  }

  //        logMsg("Test");
  /*
  if(packetSize == artnetPacketSize)//si un packet de la taille de la chaine art-net
   {
   Serial.print("Received artnet");
   Serial.print(" from ");
   IPAddress remote = Udp.remoteIP();
   for (int i =0; i < 4; i++)
   {
   Serial.print(remote[i], DEC);
   if (i < 3)
   {
   Serial.print(".");
   }
   }
   
   // read the packet into packetBufffer
   Udp.read(packetBuffer,MAX_BUFFER_UDP);
   match_artnet=1;//valeur de stockage
   for (int i=0;i<7;i++)
   {
   if(char(packetBuffer[i])!=ArtNetHead[i])
   {
   match_artnet=0;
   break;
   }
   } 
   if (match_artnet==1)
   { 
   //version protocole utilisé
   //is_artnet_version_1=packetBuffer[10]; 
   //is_artnet_version_2=packetBuffer[11];
   //séquence d'envoi des données
   //seq_artnet=packetBuffer[12];//0
   //émission de la trame venant du port physique dmx N°
   //artnet_physical=packetBuffer[13];//
   
   //operator code qui permet de savoir de quel type de message Art-Net il s'agit
   Opcode=bytes_to_short(packetBuffer[9],packetBuffer[8]);
   if(Opcode==0x5000)//il s'agit d'une trame dmx
   {
   is_opcode_is_dmx=1;
   is_opcode_is_artpoll=0;
   }   
   else if(Opcode==0x2000)//il s'agit d'un artpoll: un node art-net demande sur le réseau qui est présent
   {
   is_opcode_is_artpoll=1;
   is_opcode_is_dmx=0;
   //ici il faudrait renvoyer une trame artpoll reply au node qui a lancé le art-poll
   } 
   
   Serial.println(" OK ");
   if(  is_opcode_is_dmx=1)
   {
   //Extraction de l'univers DMX, si vous avez besoin de filtre
   incoming_universe= bytes_to_short(packetBuffer[15],packetBuffer[14]);//extraction de l'univers
   
   //report dans un buffer dmx de la trame reçue
   for(int i=0;i<numberDmxChannels;i++)
   {
   buffer_dmx[i]= char(packetBuffer[i+18]);
   }
   }
   
   }//fin de l'analyse 
   
   }*/


}






































