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

The recommended way to run SwiftOccupancy is on a Raspberry Pi Zero 2 running the 64-bit version Ubuntu Server 22.04 LTS.

1. Select `Ubuntu Server 22.04 LTS (RPi Zero2/3/4/400)` in Raspberry Pi Imager
2. Choose your Micro-SD card
3. Click the gear icon to provide initial configuration
4. Flash the SD card
5. Boot your Pi and SSH in
6. Install the [Swift repository](https://www.swiftlang.xyz)
7. Select Swift 5.5 (or latest) when prompted

## Installing SwiftOccupancy

For now clone the repository and either build it on a Pi or use a cross-compiler toolchain. 

```shell
git clone https://github.com/emorydunn/SwiftOccupancy.git
cd SwiftOccupancy
swift build
```

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

### systemd

Additionally there is a sample `systemd` service in Support that can be used to run `SwiftOccupancy` on boot. 
1. Copy the sample file to `/lib/systemd/system/`
2. Edit the file and set your desired command line options
3. Copy the `SwiftOccupancy` binary to `/home/ubuntu/.bin`
4. Add execution permission: 
  ```plain
  sudo chmod +x /lib/systemd/system/occpancy.service
  ```

5. Start the service:
  ```plain
  sudo systemctl daemon-reload
  sudo systemctl enable occpancy.service
  sudo systemctl start occpancy.service
  ```
  
## Home Assistant Automation

Included in the Support directory is a blueprint for easily controlling lights based on occupancy and the sun. There are four states you can configure:

- Empty Room
- Occupied during the day
- Occupied in the evening
- Occupied at night after a specified time

In order to use it you'll need to [import the blueprint](https://www.home-assistant.io/docs/automation/using_blueprints/#importing-blueprints) into Home Assistant.
