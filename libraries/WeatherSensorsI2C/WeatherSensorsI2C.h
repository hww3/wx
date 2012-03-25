#ifndef WEATHER_SENSORS_I2C_H
#define WEATHER_SENSORS_I2C_H

#include <inttypes.h>

typedef enum {
    eWeatherSensorAddress = 0x20,
} WEATHER_SENSOR_T;

#define SENSE_WINDSPEED 0x01
#define SENSE_MAX_WINDSPEED 0x05
#define SENSE_DIRECTION 0x02
#define SENSE_RAINFALL  0x03
#define SENSE_RESET     0x04
#define SENSE_RESTART     0x06
#define SENSE_DEGREES 0x07

typedef enum {
    eResetCmd        = 0x04,
    eHardwareResetCmd        = 0x06,
    eRainCountCmd  = 0x03,
    eWindSpeedCmd      = 0x01,
    eWindDirCmd = 0x02,
	eMaxWindSpeedCmd = 0x05,
  eWindDegCmd = 0x07,
} WEATHER_SENSOR_CMD_T;

class WeatherSensorsI2C
{
  private:
    uint16_t readDelay;

    float calculateRainCustomary(uint16_t sensorValue);
	float calculateSpeedCustomary(uint16_t sensorValue);
	char * calculateDirection(uint16_t sensorValue);

  public:
    WeatherSensorsI2C();
    uint16_t readSensor(uint8_t command);
    void SetReadDelay(uint16_t delay);
	float GetSpeedMPH(void);
	float GetRainfallInches(void);
	float GetMaxSpeedMPH(void);
	char * GetWindDirection(void);
	uint16_t GetWindDirectionDegrees(void);
	void ResetCounters(void);
	void ResetHardware(void);

};

#endif
