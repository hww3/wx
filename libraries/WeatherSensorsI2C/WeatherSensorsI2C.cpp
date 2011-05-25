
#include <inttypes.h>
#include <Wire.h>
#include <wiring.h>
#include "WeatherSensorsI2C.h"

/******************************************************************************
 * Constructors
 ******************************************************************************/

/**********************************************************
 * Initialize the sensor based on the specified type.
 **********************************************************/
WeatherSensorsI2C::WeatherSensorsI2C() {
    Wire.begin();
    readDelay = 10;
}

/******************************************************************************
 * Global Functions
 ******************************************************************************/

/**********************************************************
 * GetWindDirection
 *  Gets the current direction from the sensor.
 *
 * @return char * - The direction in as a compass direction (N, SW, etc)
 **********************************************************/
char * WeatherSensorsI2C::GetWindDirection(void) {

    char * direction;

    direction = calculateDirection(readSensor(eWindDirectionCmd));

    return direction;
}

/**********************************************************
 * GetSpeedMPH
 *  Gets the current wind speed from the sensor.
 *
 * @return float - The wind speed in miles per hour
 **********************************************************/
float WeatherSensorsI2C::GetSpeedMPH(void) {
	
    float speed;
	
    temperature = calculateSpeedCustomary(readSensor(eTempHoldCmd));
	
    return speed;
}


/**********************************************************
 * GetRainfallInches
 *  Gets the current rainfall measurement from the counter since last reset or power on.
 *
 * @return float - Collected rain amount in inches
 **********************************************************/
float WeatherSensorsI2C::GetRainfallInches(void) {
	
    float inches;
	
    temperature = calculateRainCustomary(readSensor(eRainCountCmd));
	
    return inches;
}

/**********************************************************
 * SetReadDelay
 *  Set the I2C Read delay from the sensor.
 *
 **********************************************************/
void WeatherSensorsI2C::SetReadDelay(uint16_t delay) {
    readDelay = delay;
}

/******************************************************************************
 * Private Functions
 ******************************************************************************/

uint16_t WeatherSensorsI2C::readSensor(uint8_t command) {

    uint16_t result;

    Wire.beginTransmission(eWeatherSensorAddress);   //begin
    Wire.send(command);                      //send the pointer location
    delay(readDelay);
    Wire.endTransmission();                  //end

    Wire.requestFrom(eWeatherSensorAddress, 2);
    while(Wire.available() < 2) {
      ; //wait
    }

    //Store the result
    result = ((Wire.receive()) << 8);
    result += Wire.receive();
    return result;
}

float WeatherSensorsI2C::calculateSpeedCustomary(uint16_t sensorValue)
{
	float svf = (float)sensorValue / 10.0;
	return svf;
}

float WeatherSensorsI2C::calculateRainCustomary(uint16_t sensorValue)
{
	float svf = (float)sensorValue / 0.01;
	return svf;
}

char * WeatherSensorsI2C::calculateDirection(uint16_t sensorValue)
{
	char * dir;
	
	switch(sensorValue)
	{
		case 0:
 		  dir = strdup("N");
  		  break;
		case 1:
 		  dir = strdup("NE");
  		  break;
		case 2:
 		  dir = strdup("E");
  		  break;
		case 3:
 		  dir = strdup("SE");
  		  break;
		case 4:
 		  dir = strdup("S");
  		  break;
		case 5:
 		  dir = strdup("SW");
  		  break;
		case 6:
 		  dir = strdup("W");
  		  break;
		case 7:
 		  dir = strdup("NW");
  		  break;
		default:
		  dir = strdup("--")
	}
	
	return dir;
}

