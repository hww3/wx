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
int uptime;

void setup() 
{ 
  Serial.begin(57600);   
  Serial.print("\n[bmp085demo]\n");
 
  // fire up the wireless!
  rf12_initialize(3, RF12_915MHZ, 5);
 // rf12_easyInit(15);
  
  psensor.getCalibData();
  lsensor.begin();
} 

void loop() 
{ 
  if(timer.poll(10000))
  {

    rf12_recvDone;
  uptime = millis()/60000;
    
  struct {      char cookiea;
                char cookieb;
                char cookiec;
                char cookied;
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
              } payload;
 
 
  Serial.print("BMP / RHumidity / Rainfall / Wind / Lux ");
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
  
 
// delay(5);
  payload.rainfall = ws.GetRainfallInches();
  payload.windspeed = ws.GetSpeedMPH();
  payload.maxwindspeed = ws.GetMaxSpeedMPH();
  
  char * dir = ws.GetWindDirection();
  
  payload.winddira = dir[1];

  if(dir[1])
    payload.winddirb = dir[2];
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
 //     Serial.println("sending");
      rf12_sendStart(0, &payload, sizeof payload);
 //     Serial.println("Sent");
      break;
    }
  //rf12_easySend(&payload, sizeof(payload));
  }
  }
}

