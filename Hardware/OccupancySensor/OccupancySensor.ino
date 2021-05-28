#include <ESP8266WiFi.h>
#include <Adafruit_AMG88xx.h>
#include <ArduinoMqttClient.h>
//#include "Adafruit_MQTT.h"
//#include "Adafruit_MQTT_Client.h"

#include "secrets-complete.h"

#define MQTT_DEBUG

WiFiClient client;

MqttClient mqttClient(client);

const char broker[] = mqttHost;
int        port     = mqttPort;
const char topic[]  = "swift-occupancy/sensor/" hostName;

//Adafruit_MQTT_Client mqtt(&client, mqttHost, mqttPort, mqttUsername, mqttPassword);

//Adafruit_MQTT_Publish thermoSensor = Adafruit_MQTT_Publish(&mqtt, "swift-occupancy/sensor/" hostName);

Adafruit_AMG88xx amg;

unsigned long lastSend = 0;

void setup() {
  Serial.begin(115200);
  delay(10);

  // Connect to WiFi access point.
  Serial.println(); Serial.println();
  Serial.print(F("Connecting to "));
  Serial.println(WLAN_SSID);

  WiFi.begin(WLAN_SSID, WLAN_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(F("."));
  }
  Serial.println();

  Serial.println(F("WiFi connected"));
  Serial.println(F("IP address: ")); Serial.println(WiFi.localIP());


    // You can provide a unique client ID, if not set the library uses Arduino-millis()
  // Each client must have a unique client ID
   mqttClient.setId(hostName);

  // You can provide a username and password for authentication
   mqttClient.setUsernamePassword(mqttUsername, mqttPassword);

  Serial.print("Attempting to connect to the MQTT broker: ");
  Serial.println(broker);

  if (!mqttClient.connect(broker, port)) {
    Serial.print("MQTT connection failed! Error code = ");
    Serial.println(mqttClient.connectError());

    while (1);
  }

  Serial.println("You're connected to the MQTT broker!");
  Serial.println();

  bool status;

  // default settings
  status = amg.begin();
  if (!status) {
    Serial.println("Could not find a valid AMG88xx sensor, check wiring!");
  }

}

char buffer[383];
void loop() {

  mqttClient.poll();

//  MQTT_connect();

  // Poll the sensor every 100 milliseconds and send the data to the clients
  if (millis() - 100 > lastSend) {

//    String dataToSend = handleRaw();

  float pixels[AMG88xx_PIXEL_ARRAY_SIZE];
  amg.readPixels(pixels);

  unsigned long size = 500;
  mqttClient.beginMessage(topic);
  for (int i = 1; i <= AMG88xx_PIXEL_ARRAY_SIZE; i++) {
    char pixel[10];
    dtostrf(pixels[i-1], 1, 1, pixel);
    mqttClient.print(pixel);
//    mqttClient.print(',');
//    payload += pixel;
//    if (i < AMG88xx_PIXEL_ARRAY_SIZE) {
//      mqttClient.print(',');
//    }
  }
    mqttClient.endMessage();
//  }

    // send message, the Print interface can be used to set the message contents
//    mqttClient.beginMessage(topic);
//    mqttClient.print(dataToSend);
    
    
//    Serial.println(sizeof(dataToSend));
//    dataToSend.toCharArray(buffer, 383);
//
//    Serial.println(buffer);
//    Serial.println(sizeof(buffer));
//    Serial.println(strlen(buffer));
//    Serial.println(MAXBUFFERSIZE);
//    
//
//    if (thermoSensor.publish(buffer)) {
//      Serial.println(F("Failed"));
//    } else {
//      Serial.println(F("OK!"));
//    }

    lastSend = millis();
  }
  
}

// MARK: - Sensor
String handleRaw() {
//  Serial.println("Reading raw sensor data");
  String payload;
  float pixels[AMG88xx_PIXEL_ARRAY_SIZE];
  amg.readPixels(pixels);
  for (int i = 1; i <= AMG88xx_PIXEL_ARRAY_SIZE; i++) {
    char pixel[10];
    dtostrf(pixels[i-1], 1, 2, pixel);
    payload += pixel;
    if (i < AMG88xx_PIXEL_ARRAY_SIZE) {
      payload += ',';
    }
  }

  return payload;
}

//// MARK: - MQTT
//// Function to connect and reconnect as necessary to the MQTT server.
//// Should be called in the loop function and it will take care if connecting.
//void MQTT_connect() {
//  int8_t ret;
//
//  // Stop if already connected.
//  if (mqtt.connected()) {
//    return;
//  }
//
//  Serial.print("Connecting to MQTT... ");
//
//  uint8_t retries = 3;
//  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
//       Serial.println(mqtt.connectErrorString(ret));
//       Serial.println("Retrying MQTT connection in 5 seconds...");
//       mqtt.disconnect();
//       delay(5000);  // wait 5 seconds
//       retries--;
//       if (retries == 0) {
//         // basically die and wait for WDT to reset me
//         while (1);
//       }
//  }
//  Serial.println("MQTT Connected!");
//}
