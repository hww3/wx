#include <WeatherSensorsI2C.h>

#include <RF12.h>
#include <Ports.h>
#include <PortsBMP085.h>
#include <Wire.h>
#include <LibHumidity.h>

PortI2C two (2);
PortI2C four (4);

LuxPlug lsensor(four, 0x29);
BMP085 psensor(two);
LibHumidity humidity = LibHumidity(0);
WeatherSensorsI2C ws =  WeatherSensorsI2C();

MilliTimer timer;
uint16_t uptime;
uint8_t id;

struct wx_cmd{
  char cookie0;
  char cookie1;
  char cookie2;
  char cookie3;
  char cmd0;
  char cmd1;
  char cmd2;
  char cmd3;
  uint8_t station_id;
};

typedef struct wx_cmd wx_cmd_t;

#include <avr/wdt.h>

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
void wx_handle_remote_command(char * data);

EMPTY_INTERRUPT(WDT_vect);

// Function Implementation
/*
void wdt_init(void)
{
    MCUSR = 0;
    wdt_disable();

    return;
}
*/
void setup() 
{ 
  Serial.begin(57600);   
  Serial.print("\n[remote_sensors]\n");
 
  // fire up the wireless!
  rf12_initialize(3, RF12_915MHZ, 5);
 // rf12_easyInit(15);
  
  psensor.getCalibData();
  lsensor.begin();
  
  // digital pins 5&6 select station id.
  pinMode(5, INPUT);
  digitalWrite(5, HIGH);
  pinMode(6, INPUT);
  digitalWrite(6, HIGH);
  
  id = get_id();
  Serial.print("[station id ");
  Serial.print((int)id);
  Serial.println("]");
} 

uint8_t get_id()
{
  // digital pins 5&6 select station id.
  uint8_t b = digitalRead(5);
  uint8_t b2 = digitalRead(6);
  
  if(b && b2) return 3;
  else if (b2) return 2;
  else if (b) return 1;
  else return 0;
}

void wx_handle_remote_command(char * data)
{
  wx_cmd_t * wx = (wx_cmd_t *)data;

  if(wx->cmd0 == 'H' && wx->cmd1 == 'R' && wx->cmd2 == 'S' && wx->cmd3 == 'T')
  {
    if(RF12_WANTS_ACK)
    {
      int i;
      Serial.println("Resetting.");
      ws.ResetHardware();
      delay(20);
      
      do
      {
        i = rf12_canSend();
        if(i)
          rf12_sendStart(RF12_ACK_REPLY, 0, 0);
          rf12_sendWait(1);
      } while(!i);
    }
    delay(50);
    void (*softReset) (void) = 0; //declare reset function @ address 0
    softReset();
  }
}

void loop() 
{ 
  wx_cmd_t * data;
 
 if(rf12_recvDone() && rf12_crc == 0 && rf12_len == sizeof(wx_cmd_t)) 
 {
     data = (wx_cmd_t *) rf12_data;
     
     // verify that it's a command packet
     if(data->cookie0 == 'W' && data->cookie1 == 'X' && data->cookie2 == 'C' && data->cookie3 == 'D')
     {
       // verify that it's addressed to us.
       if(data->station_id == id || data->station_id == '*')
       {
         Serial.println("received remote command.\n");
         wx_handle_remote_command((char *)data);
       }
     }
 }
 if(timer.poll(1000))
  {

//rf12_recvDone();
  uptime = millis()/5800;
    
  struct {      char cookiea;
                char cookieb;
                char cookiec;
                char cookied;
                uint8_t station_id;
                uint16_t uptime; 
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
              } payload;
 
  Serial.print((int)id);
  Serial.print(" BMP / RHumidity / Rainfall / Wind / Lux ");
  Serial.print(uptime);
  Serial.print(" : ");
  payload.cookiea = 'W'; 
  payload.cookieb = 'X'; 
  payload.cookiec = 'R'; 
  payload.cookied = '1'; 

  payload.relhx = humidity.GetHumidity();
  payload.tempb = humidity.GetTemperatureC();

//  uint16_t v = ws.readSensor(eWindDirCmd);
//Serial.println("");
//Serial.print("v ");
//Serial.println(v);

  const word * lux = lsensor.getData();
  
  payload.luxa = lux[0];
  payload.luxb = lux[1];
  payload.luxc = lsensor.calcLux();
  
  
//  Serial.print(payload.relhx);
//  Serial.print(' ');
//  Serial.print(" Temp in C: ");
//  Serial.print(payload.tempb);
/*
  Serial.print(" Temp in F: ");
  Serial.println(humidity.GetTemperatureF());
*/  
//Serial.print(' ');
  uint16_t traw = psensor.measure(BMP085::TEMP);
//  Serial.print(traw);
  
  uint16_t praw = psensor.measure(BMP085::PRES);
//  Serial.print(' ');
//  Serial.print(praw);
  

  payload.uptime = uptime;
  payload.station_id = id;  
 
// delay(5);
  payload.rainfall = ws.GetRainfallInches();
  payload.windspeed = ws.GetSpeedMPH();
  payload.maxwindspeed = ws.GetMaxSpeedMPH();
  
  char * dir = ws.GetWindDirection();
  
  payload.winddira = dir[0];

  if(dir[1])
    payload.winddirb = dir[1];
  else
    payload.winddirb = 0;
    
  psensor.calculate(payload.temp, payload.pres);
  Serial.print(' ');
  Serial.print(payload.temp);
  Serial.print(' ');
  Serial.print(payload.pres);
  Serial.print(" / "); 
  Serial.print(payload.relhx);
  Serial.print(' ');
  Serial.print(payload.tempb);
  Serial.print(" / "); 
  Serial.print(payload.rainfall);
  Serial.print(" / ");
  Serial.print(payload.windspeed);
  Serial.print(' ');
  Serial.print(dir);
  Serial.print(' ');
  Serial.print(payload.maxwindspeed);
  Serial.print(" / ");
  Serial.print(payload.luxa);
  Serial.print(' ');
  Serial.print(payload.luxb);
  Serial.print(' ');
  Serial.println(payload.luxc);

 // Serial.println("sending");
  while(1)
  {
    rf12_recvDone();
    if(rf12_canSend())
    {
      rf12_onOff(true);
 //     Serial.println("sending");
      rf12_sendStart(0, &payload, sizeof payload);
      rf12_sendWait(1);
      rf12_onOff(false);
 //     Serial.println("Sent");
      break;
    }
  //rf12_easySend(&payload, sizeof(payload));
  }
    Sleepy::loseSomeTime(10000);
 
  }
}

