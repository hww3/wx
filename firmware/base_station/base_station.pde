#include <Ports.h>
#include <RF12.h>

typedef struct {int16_t uptime; int16_t temp; int32_t pres; float relhx; float tempb; word luxa; word luxb; word luxc;} Payload;

// typedef struct { int16_t temp; int32_t pres; } Payload;
int i = 0;

void setup() {
 Serial.begin(57600);
 Serial.println("\n[bmp085recv]\n");
 
 rf12_initialize(30, RF12_915MHZ, 5);
}

void loop() {
  
 
 if(rf12_recvDone() && rf12_crc == 0 && rf12_len == sizeof(Payload)) 
 {
     Payload * data = (Payload *) rf12_data;
     
     Serial.print("BMP / RHumidity / Lux");
     Serial.print(data->uptime);
     Serial.print(" : 0 0 ");
     Serial.print(data->temp);
     Serial.print(' ');
     Serial.print(data->pres);
     Serial.print(" / ");
     Serial.print(data->relhx);
     Serial.print(' ');
     Serial.println(data->tempb);
     Serial.print(" / ");
     Serial.print(data->luxa);
     Serial.print(' ');
     Serial.print(data->luxb);
     Serial.print(' ');
     Serial.println(data->luxc);
     i++;
 } 
}
