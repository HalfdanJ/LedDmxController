







///---------


void arduinoLinkSetup(){
  Serial.begin(19200);
  for(int i=0;i<numClients;i++){
    clients[i].online = false;
  }
}


void arduinoLinkLoop(){

  //Ping clients and shift receiveMode to next client if timeout

  //Receive messages from clients
  /*if(Serial.available()){
   if(receiveMode == -1){
   
   }
   
   ComputerUdp.beginPacket(computerIp, computerUdpPort);
   while(Serial.available()){
   ComputerUdp.write(Serial.read());
   }
   ComputerUdp.endPacket();
   }*/


}



