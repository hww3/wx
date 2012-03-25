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

#include "PinChangeIntConfig.h"
#include <PinChangeInt.h>
#include <avr/power.h>
#include <avr/sleep.h>

//#define DEBUG 1
#define I2C 1

#ifdef I2C
#define I2C_ADDRESS 0x20
#include <Wire.h>
#endif

#define RAIN_DEBOUNCE 150
#define WIND_DEBOUNCE 25

#define SENSE_WINDSPEED 0x01
#define SENSE_MAX_WINDSPEED 0x05
#define SENSE_DIRECTION 0x02
#define SENSE_RAINFALL  0x03
#define SENSE_DEGREES 0x07
#define SENSE_RESET     0x04
#define SENSE_RESTART   0x06

#define RAIN_PIN 3
#define SPEED_PIN 2
#define VANE_PIN 24

// the following are used in setup() to disable the internal analog reference voltage.

//#ifndef cbi
//#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
//#endif
//#ifndef sbi
//#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
//#endif 

int commandToRespond = 0;

 volatile  unsigned long r_last_interrupt_time = 0;
 volatile unsigned long w_last_interrupt_time = 0;

 volatile unsigned long wind_time = 0;
 volatile unsigned long wind_interval = 0;
 volatile unsigned long max_wind_interval = 0;
 
 volatile int16_t rainCount = 0;
volatile int last_awoke = 0;

#include <avr/wdt.h>

// Function Pototype
//void wdt_init(void) __attribute__((naked)) __attribute__((section(".init3")));

#define soft_reset()        \
do                          \
{                           \
    wdt_enable(WDTO_15MS);  \
    for(;;)                 \
    {                       \
    }                       \
} while(0)

// Function Implementation
/*
void wdt_init(void)
{
    MCUSR = 0;
    wdt_disable();

    return;
}
*/

uint8_t get_id()
{
  // digital pins 5&6 select i2c id.
  uint8_t b = digitalRead(11);
  uint8_t b2 = digitalRead(12);
  
  if(b && b2) return 3;
  else if (b2) return 2;
  else if (b) return 1;
  else return 0;
}
 
void windInterrupt()
{
  last_awoke = 0;
  power_timer0_enable();

  unsigned long w_interrupt_time = millis();
  int x;
   
  // If interrupts come faster than 10ms, assume it's a bounce and ignore
  if (w_interrupt_time - w_last_interrupt_time > WIND_DEBOUNCE)
  {
    if(wind_time)
      wind_interval = (w_interrupt_time - wind_time);
    if(wind_interval && (!max_wind_interval || (max_wind_interval > wind_interval)))
      max_wind_interval = wind_interval;
    wind_time = w_interrupt_time; 
  }
  
  w_last_interrupt_time = w_interrupt_time; 
}

void rainInterrupt()
{
    power_timer0_enable();
last_awoke = 0;
  unsigned long r_interrupt_time = millis();
  int x;
   
  // If interrupts come faster than 200ms, assume it's a bounce and ignore
  if (r_interrupt_time - r_last_interrupt_time > RAIN_DEBOUNCE)
     rainCount++;
  
  r_last_interrupt_time = r_interrupt_time;
}

void setup()
{
   clock_prescale_set(clock_div_8);

  // First, let's shut things down and bring up the things we need.
  power_all_disable();
  power_timer0_enable();
//  power_timer1_enable();

//  cbi(ADMUX, REFS1); //clear REFS1 bit (0)
//  cbi(ADMUX, REFS0); //clear REFS0 bit (0)
 
  analogReference(EXTERNAL);

#ifdef I2C
  power_twi_enable();
#endif /* I2C */

#ifdef DEBUG
  power_usart0_enable();
#endif /* DEBUG */

#ifdef I2C
  Wire.begin(I2C_ADDRESS); // join i2c bus with address I2C_ADDRESS
  Wire.onReceive(receiveEvent);  // register event
  Wire.onRequest(requestEvent);  // register event
#endif /* I2C */

  pinMode(RAIN_PIN, INPUT);
  digitalWrite(RAIN_PIN, HIGH);

  pinMode(SPEED_PIN, INPUT);
  digitalWrite(SPEED_PIN, HIGH);

// we use pin 6 (digital 4) to drive the windvane, so we normally want it off.
  pinMode(4, OUTPUT);
  digitalWrite(4, LOW);
//  pinMode(4, INPUT);
//  digitalWrite(4, HIGH);
  pinMode(5, INPUT);
  digitalWrite(5, HIGH);
  pinMode(6, INPUT);
  digitalWrite(6, HIGH);


  pinMode(7, INPUT);
  digitalWrite(7, HIGH);
  pinMode(8, INPUT);
  digitalWrite(8, HIGH);
  pinMode(9, INPUT);
  digitalWrite(9, HIGH);
  pinMode(10, INPUT);
  digitalWrite(10, HIGH);
  pinMode(11, INPUT);
  digitalWrite(11, HIGH);
  pinMode(12, INPUT);
  digitalWrite(12, HIGH);
  pinMode(13, INPUT);
  digitalWrite(13, HIGH);
  pinMode(14, INPUT);
  digitalWrite(14, HIGH);

  PCattachInterrupt(RAIN_PIN, rainInterrupt, FALLING);
  PCattachInterrupt(SPEED_PIN, windInterrupt, FALLING);

#ifdef DEBUG  
  Serial.begin(9600);
  Serial.println("I2C WEATHER");
#endif /* DEBUG */ 
}

void loop()
{
 // reset wind trigger period if more than 5 seconds since last interrupt
 if((millis() - w_last_interrupt_time) > 2000) wind_interval = 0;

 if( ++last_awoke > 180)  // sleep more deeply
 {
   #ifdef DEBUG  
  Serial.println("Sleeping");
  delay(100);
#endif /* DEBUG */
   set_sleep_mode(SLEEP_MODE_PWR_SAVE);
#ifdef DEBUG  
   power_usart0_disable();
#endif /* DEBUG */
   delay(20);
   sleep_enable();
   w_last_interrupt_time = 0;
   r_last_interrupt_time = 0;
   wind_time = 0;
   //wind_interval = 0;
   sleep_mode();
   sleep_disable();
   last_awoke = 0;
#ifdef DEBUG  
   power_usart0_enable();
#endif /* DEBUG */
#ifdef DEBUG  
  Serial.println("Awake");
#endif /* DEBUG */
 }
 else // just save some power
 {
   set_sleep_mode(SLEEP_MODE_IDLE);
   delay(1);
   sleep_enable();
   sleep_mode();
   sleep_disable();
 } 
 
#ifdef DEBUG
 Serial.print(rainCount);
 Serial.print(' ');
    
 Serial.print(calcWindDir());
 Serial.print(' ');
  
 Serial.println(calcWindSpeed());
#endif /* DEBUG */

}

int16_t calcMaxWindspeed()
{
  int16_t t;

 double q;
  
 q = 1000.0/max_wind_interval*2.5;

  t = (int16_t)(q*10);
  return t;
}


int16_t calcWindSpeed()
{
  int16_t t;

 double q;
  
 q = 1000.0/wind_interval*2.5;

  t = (int16_t)(q*10);
  return t;
}

uint16_t getWindDirReading()
{
  delay(10);
  power_adc_enable();
  
  analogReference(EXTERNAL);
  digitalWrite(4, HIGH);
  delay(5);
  uint16_t windDir = analogRead(0);
  digitalWrite(4, LOW); 

  power_adc_disable();
  return windDir;
}

uint16_t calcWindDirDegrees()
{
  uint16_t windDirX;
 
  windDirX = getWindDirReading();
  
  windDirX = (uint16_t)(windDirX/2.84);
  
  return windDirX;
  
}
uint16_t calcWindDir()
{
  uint16_t windDirX;
 
 windDirX = getWindDirReading();
 if(windDirX >= 959)
   windDirX = 0;
 else
   windDirX = (windDirX+(64))/(128);
   
 return windDirX;
}

#ifdef I2C
void receiveEvent(int howMany)
{
  int i = 0;
   // reset wind trigger period if more than 5 seconds since last interrupt
 if((millis() - w_last_interrupt_time) > 2000) wind_interval = 0;

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
  last_awoke = 0;
   // reset wind trigger period if more than 5 seconds since last interrupt
 if((millis() - w_last_interrupt_time) > 2000) wind_interval = 0;

  if(commandToRespond ==  SENSE_DEGREES)
  {
    sendBytes(calcWindDirDegrees());
  }
 else if(commandToRespond ==  SENSE_DIRECTION)
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
  else if(commandToRespond == SENSE_MAX_WINDSPEED)
  {
    sendBytes(calcMaxWindspeed());
  }
  else if(commandToRespond == SENSE_RESTART)
  {
    sendBytes(0xFFFF);
    delay(20);
    void (*softReset) (void) = 0; //declare reset function @ address 0
    softReset();
  }
  else if(commandToRespond == SENSE_RESET)
  {
    rainCount = 0;
    wind_interval = 0;
    max_wind_interval = 0;
    sendBytes(0x0000);
  }
  else
  {
    sendBytes(0xfff3);
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
