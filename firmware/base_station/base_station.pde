#include <Wire.h>

#include <enc28j60.h>
#include <EtherCard.h>
#include <net.h>

#include <Ports.h>
#include <RF12.h>
#include <avr/wdt.h>


#define WX_DATA_PORT 7656

#define gPB ether.buffer

static byte* bufPtr;
/*
 struct {
   uint8_t station_id;
   int16_t uptime; 
 int16_t temp; 
 int32_t pres; 
 float relhx; 
 float tempb; 
 float rainfall;
 float windspeed; 
 float maxwindspeed; 
 char winddira; 
 char winddirb; word luxa; word luxb; word luxc;} payload;
 */

struct payload {
                char cookiea;
                char cookieb;
                char cookiec;
                char cookied;
                uint8_t station_id;
                int16_t uptime; 
                int16_t temp; 
                int32_t pres; 
                float relhx; 
                float tempb; 
                float rainfall; 
                float windspeed; 
                float maxwindspeed; 
                char winddira; 
                char winddirb; 
                word luxa; 
                word luxb; 
                word luxc;
              };

typedef struct payload wx_data;

// typedef struct { int16_t temp; int32_t pres; } Payload;
int i = 0;
static byte mymac[] = { 0x74, 0x69, 0x69, 0x2d, 0x30, 0x31 };

byte Ethernet::buffer[700];

static byte dnstid_l; // a counter for transaction ID
#define DNSCLIENT_SRC_PORT_H 0xD2 

#define soft_reset()        \
do                          \
{                           \
    wdt_enable(WDTO_15MS);  \
    for(;;)                 \
    {                       \
    }                       \
} while(0)

// Function Pototype
//void wdt_init(void) __attribute__((naked)) __attribute__((section(".init3")));

// Function Implementation
/*
void wdt_init(void)
{
    MCUSR = 0;
    wdt_disable();

    return;
}
*/
void setup() {
 Serial.begin(57600);
 Serial.println("\n[bmp085recv]\n");
 
 rf12_initialize(30, RF12_915MHZ, 5);
 
// return;
  
  if(ether.begin(sizeof Ethernet::buffer, mymac) == 0)
  {
    Serial.println("failed to access Ethernet controller");
  }
  if(!ether.dhcpSetup())
  {
    Serial.println("DHCP failed");    
    delay(5000);
    void (*softReset) (void) = 0; //declare reset function @ address 0
    softReset();
   }    
  ether.printIp("IP: ", ether.myip);
  ether.printIp("GW: ", ether.gwip);
  
  if(!ether.dnsLookup(PSTR("192.168.1.20")))
  {
    Serial.println("DNS failed");
    delay(5000);
    void (*softReset) (void) = 0; //declare reset function @ address 0
    softReset();
  }    
  ether.printIp("SRV: ", ether.hisip);
    
//  ether.registerPingCallback(gotPinged);
}

void loop() {
 
 if(rf12_recvDone() && rf12_crc == 0)
 if(rf12_len != sizeof(wx_data)) 
 Serial.println("have packet!\n");
 else
 {
     wx_data * data = (wx_data *) rf12_data;
     Serial.print((int)data->station_id);
     Serial.print(" BMP / RHumidity / Rain / Wind / Lux ");
     Serial.print(data->cookiea);
     Serial.print(data->cookieb);
     Serial.print(data->cookiec);
     Serial.print(data->cookied);
     Serial.print(' ');
     Serial.print((int)(data->uptime));
     Serial.print(": ");
     Serial.print(data->temp);
     Serial.print(' ');
     Serial.print(data->pres);
     Serial.print(" / ");
     Serial.print(data->relhx);
     Serial.print(' ');
     Serial.print(data->tempb);
     Serial.print(" / ");
     Serial.print(data->rainfall);
     Serial.print(" / ");
     Serial.print(data->windspeed);
     Serial.print(" / ");
     Serial.print(data->winddira);
//if(data->winddirb)
     Serial.print(data->winddirb);
     Serial.print(data->maxwindspeed);
     Serial.print(" / ");
     Serial.print(data->luxa);
     Serial.print(' ');
     Serial.print(data->luxb);
     Serial.print(' ');
     Serial.println(data->luxc);
    postData(ether.hisip, data);
 //    i++;
 } 
}

 void postData (uint8_t *dip, struct payload * pl) {
  ++dnstid_l; // increment for next request, finally wrap

  ether.udpPrepare((DNSCLIENT_SRC_PORT_H << 8) | dnstid_l,
                                                dip, WX_DATA_PORT);
  memset(gPB + UDP_DATA_P, 1, sizeof(struct payload));

  bufPtr = gPB + UDP_DATA_P;
  addPayload(pl);

  ether.udpTransmit((bufPtr - gPB) - UDP_DATA_P);
}

static void addToBuf (byte b) {
    *bufPtr++ = b;
}

static void addPayload (struct payload * data) {
  int len = sizeof(struct payload);
  byte * d;
  
  d = (byte *) data;
    while (len-- > 0)
        addToBuf(*d++);
}

