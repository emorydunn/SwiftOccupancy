#include <ESP8266WiFi.h>
#include <Adafruit_AMG88xx.h>
#include <ArduinoMqttClient.h>

#include "secrets-complete.h"

#define MQTT_DEBUG

WiFiClient client;

MqttClient mqttClient(client);

const char broker[] = mqttHost;
int        port     = mqttPort;
const char topic[]  = "swift-occupancy/sensor/" hostName;

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

  // Poll the sensor every 100 milliseconds and send the data to the clients
  if (millis() - 100 > lastSend) {

  float pixels[AMG88xx_PIXEL_ARRAY_SIZE];
  amg.readPixels(pixels);

  mqttClient.beginMessage(topic);
  
  for (int i = 1; i <= AMG88xx_PIXEL_ARRAY_SIZE; i++) {
    char pixel[10];
    // Round the temp to one decimal point
    dtostrf(pixels[i-1], 1, 1, pixel);
    mqttClient.print(pixel);
  }
    mqttClient.endMessage();

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
