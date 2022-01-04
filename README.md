# SwiftOccupancy

SwiftOccupancy is designed to provide room occupancy tracking using thermopile sensors. By placing
sensors at the top of a doorway two rooms can be tracked at once. Paired sensors allow quick and easy
presence detection.

People are counted as they walk between rooms, so walking out of one room decreases the count there
and increases it in the room you walk into. For privacy a sensor doesn't need both rooms, only
the specified rooms will be counted.

## Software Installation

SwiftOccupancy designed to be run on a cluster of Raspberry Pis, preferably a Raspberry Pi 4 or Raspberry Pi Zero 2. You can use anything you'd like so long as it:

- Can run Swift 5.5 (a 64-bit OS)
- Has I2C support

## Ubuntu Installation

The recommended way to run SwiftOccupancy is on a Raspberry Pi Zero 2 running the 64-bit version Ubuntu Server 21.10.

1. Flash the Ubuntu Server 21.10 to your SD card with Raspberry Pi Imager
2. Plug the SD card back into your computer for initial config
3. Add WiFi settings in `network-config`
   - Triple check that your editor hasn't fucked up the indentation because YAML is picky
4. Copy the `bcm2710-rpi-3-b.dtb` file to `bcm2710-rpi-zero-2.dtb`
  - Until Ubuntu officially supports 64-bit on the Zero 2 this needs to be done
5. Boot your Pi and SSH in
6. Install the [Swift repository](https://www.swiftlang.xyz)
7. Select Swift 5.5 (or latest) when prompted

## Installing SwiftOccupancy

Download the file. Done.

## Hardware Configuration

The sensor should be placed such that the _top_ and _bottom_ of the frame point across the door.
At this time there is no rotation support and people will only be detected when walking from
top to bottom and visa-versa.

## Usage

`SwiftOccupancy` has a number of command line options, but in order to run an instance the command to run is `SwiftOccupancy occupancy i2c`. You'll need to provide a number of options to configure the instance. The required ones are:

- host
- username
- password
- address
- At least one room
    - You don't technically need to provide any rooms, but it'll be a pretty useless sensor

```plain
OVERVIEW: Read data from an I2C sensor.

Data is read from an I2C sensor, occupancy changes are parsed and published to Home Assistant via MQTT.

USAGE: swift-occupancy occupancy i2c [<options>] --host <host> --address <address>

OPTIONS:
  --host <host>           MQTT server hostname
  --port <port>           MQTT server port (default: 1883)
  -u, --username <username>
                          MQTT username
  -p, --password <password>
                          MQTT password
  --enable-camera/--disable-camera
                          Publish the rendered sensor view. (default: false)
  --board <board>         The board for connecting via I2C (default: RaspberryPi4)
  --address <address>     The sensor address
  --top-room <top-room>   The top room name (default: ether)
  --bottom-room <bottom-room>
                          The bottom room name (default: ether)
  --reset-counts          Reset room counts.
  --delta <delta>         The delta between what is detected as foreground and background. (default: 2.0)
  --size <size>           The minimum number of pixels for a cluster to be included. (default: 5)
  --width <width>         The minimum width of a cluster's bounding box. (default: 3)
  --height <height>       The minimum height of a cluster's bounding box. (default: 2)
  --version               Show the version.
  -h, --help              Show help information.
```

