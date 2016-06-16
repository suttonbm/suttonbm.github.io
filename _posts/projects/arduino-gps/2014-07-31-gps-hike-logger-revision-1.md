---
title: "GPS Hike Logger, Revision 1"
date: 2014-07-31T02:58:38+00:00
author: suttonbm
layout: post
categories:
  - projects
tags:
  - adafruit
  - arduino
  - datalogger
  - gps
  - hiking
project: arduinogps
---
Finally getting around to writing up this project...

Background: For the past two years I've had the opportunity to coordinate and mentor senior design projects at one of the local universities. After this year's projects I ended up with a collection of half-baked contraptions littering my cubicle at work (boss says "clean up!"). As you might figure might happen with a bunch of college kids designing contraptions of any kind, there was a nice selection of Arduinos, Raspberry Pis, BeagleBones, and various peripherals. Of course, with the need to clean up my office without throwing everything away, I decided to snag a couple of the boards to tinker with.

Long story short, I got hooked.

It just so happens that when all these projects were wrapping up I was about to go on vacation with the family up in the Seattle area. We were planning on hiking around in the Olympic Peninsula and Rainier. Combine the power of an Arduino with a curious engineer and some hiking boots, and you get...

![GPS Logger v1 Image](http://i.imgur.com/o41rusO.jpg)


The original intent of this design was to log GPS and Altitude/Pressure data periodically to an SD card. I ended up running into some SPI issues getting both BoB's running... More on that later.

To see some of the results (GPS output), see my post [here]({{ site.url }}/2014/07/gps-logger-v1-0-hikes/).

### The Parts

For the sake of reusability and flexibility to support multiple MCU prototyping boards, I decided that a set of break-out-boards would make more sense than dedicated Arduino shields for the project. To source the shields, I headed over to the excellent [Adafruit](http://www.adafruit.com). This project makes use of three breakout boards:

  1. [The BMP180 BoB](http://www.adafruit.com/products/1900) ($9.95)
  2. [The Ultimate GPS BoB](https://www.adafruit.com/products/746) ($39.95)
  3. [The SD-Card BoB](https://www.adafruit.com/products/254) ($14.95)

Side note - I'm not affiliated with the folks over there at Adafruit, this just helps me keep track of where I got my parts :).

Of course, given that this is a mobile logger, there needs to be a power source as well. I did some brief research into bare Li-Ion cells from SparkFun or other suppliers, but didn't really want to mess with sourcing a dedicated charger, finding the right voltage, etc. Somewhere out on the interweb I found mention of using a portable phone charging battery. The benefit of this solution is built-in charging, fuel gauge monitoring, and output regulation to 5V (native for Arduino). I picked up a 5200 mAh battery from PowerAdd on [Amazon](http://www.amazon.com/Poweradd-trade-Pilot-X1-Flashlight/dp/B00DGJJNVO/ref=sr_1_1?ie=UTF8&qid=1406772344&sr=8-1&keywords=poweradd+5200) for $13.99.

Finally, since this thing was getting used in the Pacific Northwest (it rains a lot), it needed to be waterproof! The obvious solution in this case (no pun intended) was to pick up a [Pelican](http://www.frys.com/product/5718692?site=sr:SEARCH:MAIN_RSLT_PG) at Fry's for $17.49.

# Assembly and Wiring

The assembly of this little gadget was pretty straightforward. To hold the prototyping board and battery in place I used some industrial-strength double-sided tape from Lowes. The stuff that came on the protoboard was pretty low quality adhesive, and I didn't want everything to shake lose halfway through a hike. To affix the Arduino motherboard inside the case I drilled a few small (1/8&#8243;) holes and zip-tied the board to the Pelican lid. Finally, I used some silicone sealer to patch up the holes and keep any water off of the electronics (I hear that Arduino may in fact be an Italian cat).

Finally, once all the peripherals were installed in the case I wired up the system as shown below. You'll notice that I didn't wire up the CS pin on the BMP183 BoB; this was to just keep that guy off the communication loop. For whatever reason, there seems to be something goofy going on with the built-in SPI library when multiple devices are present. At some point I'll have to get in there and see if I can debug the problem.

![Schematic Image](http://i.imgur.com/x55OOV3.jpg)

# Programming Stuff

The code to run this guy was pretty straightforward - no funny business here.

```cpp
#include <sd.h>
#include <spi.h>
#include <adafruit_gps.h>
#include <softwareserial.h>

#define SD_CSEL 10
#define SDO_Pin 13
#define SDI_Pin 11
#define SCL_Pin 12

#define LOG_INTERVAL 5000

SoftwareSerial mySerial(3,2);
Adafruit_GPS GPS(&mySerial);

void setupSD();
void setupGPS();
File logFile;

//File Serial;

void setup()
{
  Serial.begin(9600);

  setupSD();
  setupGPS();
  delay(1000);
}

unsigned long timer = millis();
void loop()
{
  char c = GPS.read();

  /* Check for new GPS data and parse it */
  if (GPS.newNMEAreceived()) {
    /* It is possible the parsing may fail */
    if (!GPS.parse(GPS.lastNMEA())) {
      return;
    }
  }

  /* Fix timer wrapping */
  if (timer > millis()) timer = millis();

  /* Log GPS Stats */
  if (millis() - timer > LOG_INTERVAL) {
    timer = millis();
    logFile.print(GPS.hour, DEC); logFile.print(":");
    logFile.print(GPS.minute, DEC); logFile.print(":");
    logFile.print(GPS.seconds, DEC); logFile.print(",");
    logFile.print(GPS.fix); logFile.print("/");
    logFile.print(GPS.fixquality); logFile.print("/");
    logFile.print(GPS.satellites); logFile.print(",");
    if (GPS.fix) {
      logFile.print(GPS.latitude, 4); logFile.print(GPS.lat);
      logFile.print(",");
      logFile.print(GPS.longitude, 4); logFile.print(GPS.lon);
      logFile.print(",");
      logFile.print(GPS.speed); logFile.print(",");
      logFile.println(GPS.altitude);
    } else {
      logFile.println("");
    }
    logFile.flush();
  }
}

void setupSD()
{
  pinMode(SD_CSEL, OUTPUT);

  /* SD Card Setup */
  while (!SD.begin(SD_CSEL)) {
    Serial.println("Error Initializing SD!");
    delay(1000);
  }
  Serial.println("SD Initialization Successful");

  /* Create Log File */
  char charBuf[8];
  String logName = (String)random(1000,9999) + ".log";
  logName.toCharArray(charBuf, 8);
  while (SD.exists(charBuf)) {
    logName = (String)random(1000,9999) + ".log";
    logName.toCharArray(charBuf, 8);
  }
  logFile = SD.open(charBuf, FILE_WRITE);
}

void setupGPS()
{
  /* GPS Setup */
  GPS.begin(9600);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);
  GPS.sendCommand(PGCMD_ANTENNA);
}
```

# Closing Thoughts

This was a great introductory project for the world of Arduino. While I like the simplicity of flashing LEDs, I quickly felt that I needed a better challenge to go tackle. Plus, I can actually use this thing. Granted, it is bulky and heavy to carry around at length. Eventually it would be fun to go back and redesign into a smaller form-factor through the use of a single ATMega328 or Arduino Pro Mini.

The one topic that I still haven't solved is the issue of running multiple devices on an SPI bus. In theory, it should be straightforward, but for whatever reason the BMP BoB isn't playing well with the SD BoB. Another project for me to dig into...