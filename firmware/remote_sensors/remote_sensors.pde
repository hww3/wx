#include <WeatherSensorsI2C.h>

#include <RF12.h>
#include <Ports.h>
#include <PortsBMP085.h>
#include <Wire.h>
#include <LibHumidity.h>

PortI2C two (2);
PortI2C three (4);

LuxPlug lsensor(three, 0x29);
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
  rf12_easyInit(0);
  
  psensor.getCalibData();
  lsensor.begin();
} 

void loop() 
{ 
  while(!timer.poll(1000))
    rf12_easyPoll();

  uptime = millis()/60000;
    
  struct {int16_t uptime; int16_t temp; int32_t pres; float relhx; float tempb; float rainfall; float windspeed; float maxwindspeed; char winddira; char winddirb; word luxa; word luxb; word luxc;} payload;
 
  Serial.print("BMP / RHumidity / Rainfall / Wind / Lux ");
  Serial.print(uptime);
  Serial.print(" : ");
  
  payload.relhx = humidity.GetHumidity();
  payload.tempb = humidity.GetTemperatureC();

  const word * lux = lsensor.getData();
  
  payload.luxa = lux[0];
  payload.luxb = lux[1];
  payload.luxc = lsensor.calcLux();
  
  /*
  Serial.print(payload.relhx);
  Serial.print(" Temp in C: ");
  Serial.print(payload.tempb);
  Serial.print(" Temp in F: ");
  Serial.println(humidity.GetTemperatureF());
*/  
  uint16_t traw = psensor.measure(BMP085::TEMP);
  Serial.print(traw);
  
  uint16_t praw = psensor.measure(BMP085::PRES);
  Serial.print(' ');
  Serial.print(praw);
  
  payload.uptime = uptime;
  
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
  Serial.print(' ');
  Serial.print(payload.windspeed);
  Serial.print(' ');
  Serial.print(dir);
  Serial.print(' ');
  Serial.print(payload.maxwindspeed);
  Serial.print(' ');
  Serial.print(payload.luxa);
  Serial.print(' ');
  Serial.print(payload.luxb);
  Serial.print(' ');
  Serial.println(payload.luxc);

  rf12_easySend(&payload, sizeof(payload));
}

