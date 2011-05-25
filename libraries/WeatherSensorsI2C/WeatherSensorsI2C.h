#ifndef WEATHER_SENSORS_I2C_H
#define WEATHER_SENSORS_I2C_H

#include <inttypes.h>

typedef enum {
    eWeatherSensorAddress = 0x20,
} WEATHER_SENSOR_T;

typedef enum {
    eResetCmd        = 0x04,
    eRainCountCmd  = 0x03,
    eWindSpeedCmd      = 0x01,
    eWindDirCmd = 0x02,
} WEATHER_SENSOR_CMD_T;

class WeatherSensorsI2C
{
  private:
    uint16_t readDelay;

    float calculateRainCustomary(uint16_t sensorValue);
	float calculateSpeedCustomary(uint16_t sensorValue);
	String calculateDirection(uint16_t sensorValue);
    uint16_t readSensor(uint8_t command);

  public:
    WeatherSensorsI2C(uint8_t sensorType);
    void SetReadDelay(uint16_t delay);
	float GetSpeedMPH(void);
	float GetRainfallInches(void);
	String GetWindDirection(void);

};

#endif
