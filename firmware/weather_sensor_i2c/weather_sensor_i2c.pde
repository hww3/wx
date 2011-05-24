/*

  turn an atmega816 into a weather sensor controller
  with i2c communications on address 0x20

  mfg: davis instruments
  
  rain gauge  int 0 - digital 2 / pin 4
  anemometer  int 1 - digital 3 / pin 5
  wind vane   analog 1 / pin 24

  i2c slave
  sda analog 4 / pin 27
  scl analog 5 / pin 28

*/

//#include <Wire.h>

//#define DEBUG 1
#define I2C 1

#ifdef I2C
#define I2C_ADDRESS 0x20
#include <Wire.h>
#endif

#define RAIN_DEBOUNCE 150
#define WIND_DEBOUNCE 20

#define SENSE_WINDSPEED 0x01
#define SENSE_DIRECTION 0x02
#define SENSE_RAINFALL  0x03
#define SENSE_RESET     0x04
 
#define RAIN_PIN 3
#define SPEED_PIN 2
#define VANE_PIN 24

int commandToRespond = 0;

 volatile  unsigned long r_last_interrupt_time = 0;
 volatile unsigned long w_last_interrupt_time = 0;

 volatile unsigned long wind_time = 0;
 volatile unsigned long wind_interval = 0;
 
 volatile int16_t rainCount = 0;

void windInterrupt()
{
  unsigned long w_interrupt_time = millis();

  int x;
   
  // If interrupts come faster than 10ms, assume it's a bounce and ignore
  if (w_interrupt_time - w_last_interrupt_time > WIND_DEBOUNCE)
  {
    wind_interval = (w_interrupt_time - wind_time);
    wind_time = w_interrupt_time; 
  }
  
  w_last_interrupt_time = w_interrupt_time; 
}

void rainInterrupt()
{
  unsigned long r_interrupt_time = millis();
  int x;
   
  // If interrupts come faster than 200ms, assume it's a bounce and ignore
  if (r_interrupt_time - r_last_interrupt_time > RAIN_DEBOUNCE)
  {
     rainCount++;
  }
  
  r_last_interrupt_time = r_interrupt_time;
}

void setup()
{

#ifdef I2C
  Wire.begin(I2C_ADDRESS); // join i2c bus with address I2C_ADDRESS
  Wire.onReceive(receiveEvent);  // register event
  Wire.onRequest(requestEvent);  // register event
#endif /* I2C */

  pinMode(RAIN_PIN, INPUT);
  digitalWrite(RAIN_PIN, HIGH);

  pinMode(SPEED_PIN, INPUT);
  digitalWrite(SPEED_PIN, HIGH);

  attachInterrupt(1, rainInterrupt, FALLING);
  attachInterrupt(0, windInterrupt, FALLING);

#ifdef DEBUG  
  Serial.begin(9600);
  Serial.println("I2C WEATHER");
#endif /* DEBUG */ 
}

void loop()
{
 delay(1000);
 
 // reset wind trigger period if more than 5 seconds since last interrupt
 if((millis() - w_last_interrupt_time) > 5000) wind_interval = 0;

#ifdef DEBUG
 Serial.print(rainCount);
 Serial.print(' ');
    
 Serial.print(calcWindDir());
 Serial.print(' ');
  
 Serial.println(calcWindSpeed());
#endif /* DEBUG */

}

int16_t calcWindSpeed()
{
  int16_t t;

 double q;
  
 q = 1000.0/wind_interval*2.5;

  t = (int16_t)(q*10);
  return t;
}

int16_t calcWindDir()
{
  int16_t windDirX;
  
  int windDir = analogRead(0);
 
 if(windDir >= 959)
   windDirX = 0;
 else
   windDirX = (windDir+(64))/(128);
   
 return windDirX;
}

#ifdef I2C
void receiveEvent(int howMany)
{
  int i = 0;

  // drain the receive buffer, but only use the first byte as the request.  
  while(Wire.available())
  {
    if(i == 0)
      commandToRespond = Wire.receive();
    else
      Wire.receive();
    i++;
  }
}

// all requests return 16
void requestEvent()
{
  if(commandToRespond ==  SENSE_DIRECTION)
  {
    sendBytes(calcWindDir());
  }
  else if(commandToRespond == SENSE_RAINFALL)
  {
    sendBytes(rainCount);
  }
  else if(commandToRespond == SENSE_WINDSPEED)
  {
    sendBytes(calcWindSpeed());
  }
  else if(commandToRespond == SENSE_RESET)
  {
    rainCount = 0;
    wind_interval = 0;
    sendBytes(0x0000);
  }
  else
  {
    sendBytes(0xffff);
  }
  commandToRespond = 0;
}

void sendBytes(uint16_t x)
{
  uint8_t b[2] = {0x00, 0x00};
  uint32_t y;
  uint8_t toSend;

  y = x;  

  for(int i=0; i < 2; i++)
  {
    toSend = y & 0xff;
#ifdef DEBUG
    Serial.print((unsigned int)toSend);
#endif /* DEBUG */
    b[i] = toSend;
    y >>= 8;
  }
  
  Wire.send(b, 2);
}
#endif /* I2C */
