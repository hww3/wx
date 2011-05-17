#include <RF12.h>
#include <Ports.h>
#include <PortsBMP085.h>
#include <Wire.h>
#include <LibHumidity.h>

#define WEATHER_ADDRESS 0x20

#define SENSE_WINDSPEED 0x01
#define SENSE_DIRECTION 0x02
#define SENSE_RAINFALL  0x03
#define SENSE_RESET     0x04

PortI2C two (2);
PortI2C three (4);

int rainPin = 4;

LuxPlug lsensor(three, 0x29);
BMP085 psensor(two);
LibHumidity humidity = LibHumidity(0);

MilliTimer timer;
int uptime;
int rainCounter = 0;
int interrupts = 0;
int r = 0;
 static unsigned long last_interrupt_time = 0;

void caughtInterrupt()
{
   unsigned long interrupt_time = millis();
  // If interrupts come faster than 200ms, assume it's a bounce and ignore

  interrupts ++;
  int x = digitalRead(rainPin);
  int y = digitalRead(6);
  if (interrupt_time - last_interrupt_time > 200)
  {
    if(x == LOW)
      rainCounter++;
      
    if(y == HIGH)
      r++;
  }
  
  last_interrupt_time = interrupt_time;
}

void setup() 
{ 
  Serial.begin(57600); 
  Serial.print("\n[bmp085demo]\n");


 pinMode(16, OUTPUT);
  digitalWrite(16, LOW);  //GND pin
  pinMode(17, OUTPUT);
  digitalWrite(17, HIGH); //VCC pin
  pinMode(17, OUTPUT);

  pinMode(3, INPUT);
  digitalWrite(3, HIGH);
  pinMode(rainPin, INPUT);
  digitalWrite(rainPin, HIGH);
  pinMode(6, INPUT);
   digitalWrite(6, HIGH);

  attachInterrupt(1, caughtInterrupt, CHANGE);

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
    
  struct {int16_t uptime; int16_t temp; int32_t pres; float relhx; float tempb; word luxa; word luxb; word luxc;} payload;
 
  int q = analogRead(2);
 Serial.print(q);
  Serial.print(' cycle');
 Serial.print(r);
  Serial.print(' ');
 Serial.println(interrupts); 
 Serial.println(rainCounter); 
  Serial.print("BMP / RHumidity / Lux ");
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
  Serial.print(payload.luxa);
  Serial.print(' ');
  Serial.print(payload.luxb);
  Serial.print(' ');
  Serial.println(payload.luxc);

  uint16_t wsr = readWeatherSensor(SENSE_RAINFALL);
  Serial.println(wsr);  

  rf12_easySend(&payload, sizeof(payload));
}



uint16_t readWeatherSensor(uint8_t command) {

    uint16_t result;

    Wire.beginTransmission(WEATHER_ADDRESS);   //begin
    Wire.send(command);                      //send the pointer location
    delay(100);
    Wire.endTransmission();                  //end

    Wire.requestFrom(WEATHER_ADDRESS, 2);
    while(Wire.available() < 2) {
      ; //wait
    }

    //Store the result
    result = ((Wire.receive()) << 8);
    result += Wire.receive();
    // result &= ~0x0003;   // clear two low bits (status bits)
    return result;
}
