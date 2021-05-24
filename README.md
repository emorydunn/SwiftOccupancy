# SwiftOccupancy

SwiftOccupancy is designed to provide room occupancy tracking using thermopile sensors. By placing
sensors at the top of a doorway two rooms can be tracked at once. Paired sensors allow quick and easy
presence detection.

People are counted as they walk between rooms, so walking out of one room decreases the count there
and increases it in the room you walk into. For privacy a sensor doesn't need both rooms only only
the specified rooms will be counted.

## Software Installation

SwiftOccupancy is primarily designed to be run as a Home Assistant add-on, but can be run anywhere.

**Configuration**

There are two sections to the config file. The Home Assistant config is only needed if not running
as an add-on.

The other section is a list of sensors. Each sensor needs a URL, and optionally, names for the two
rooms to be tracked. If a room isn't provided it will be ignored.

```json
{
	"homeAssistant": {
		"url": "http://homeassistant.local:8123",
		"token": "<long-lived-token>"
	},
	"sensors": [{
			"url": "ws://10.0.2.163",
			"topName": "Hall",
			"bottomName": "Office"
		},
		{
			"url": "ws://10.0.2.85",
			"topName": "Hall",
			"bottomName": "Upstairs Bedroom"
		}
	]
}
```

**Home Assistant**

You can add the repository to Home Assistant OS to [install it](https://www.home-assistant.io/hassio/installing_third_party_addons/).

SwiftOccupancy will automatically detect the Home Assistant credentials.

SwiftOccupancy uses the Home Assistant HTTP API to create sensors for each room who's state is the number
of people in the room.

```
friendly_name: Office Occupancy
unit_of_measurement: person
icon: 'mdi:account'
```

## Hardware Configuration

Upload the sketch in `Hardware/OccupancySensor` to an ESP8266. The sensor creates a WebSocket for the
server to connect to. The sensors are best powered via USB, unless you want to tape a massive battery to your wall.

Fill in your WiFi details in `secrets.h`.

**Placement**

The sensor should be placed such that the _top_ and _bottom_ of the frame point across the door.
At this time there is no rotation support and people will only be detected when walking from
top to bottom and visa-versa.
