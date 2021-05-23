#include <ESP8266WiFi.h>
#include <ArduinoWebsockets.h>
#include <Adafruit_AMG88xx.h>

#include "secrets.h"

using namespace websockets;

// Define how many clients we accpet simultaneously.
const byte maxClients = 4;

WebsocketsClient clients[maxClients];
WebsocketsServer server;

Adafruit_AMG88xx amg;
static float pixels[AMG88xx_PIXEL_ARRAY_SIZE];

// a collection of all connected clients
std::vector<WebsocketsClient> allClients;

unsigned long lastSend = 0;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  wifiInit();
  wifiConnect();

  bool status;

  // default settings
  status = amg.begin();
  if (!status) {
    Serial.println("Could not find a valid AMG88xx sensor, check wiring!");
  }

  Serial.println("Starting WebSocket server");
  server.listen(80);
  if (server.available()) {
    Serial.println("Server is available");
  }

}


void loop() {

  listenForClients();
  pollClients();

  // Poll the sensor every 100 milliseconds and send the data to the clients
  if (millis() - 100 > lastSend) {
    String dataToSend = handleRaw();
    for (byte i = 0; i < maxClients; i++) {
      clients[i].send(dataToSend);
    }
    lastSend = millis();
  }
  
}

// MARK: - WiFi
void wifiInit() {
  WiFi.mode(WIFI_STA);
  WiFi.hostname(hostName);
  WiFi.begin(ssid, password);
}

void wifiConnect() {
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.print("\nIP address: ");
  Serial.println(WiFi.localIP());
}


// MARK: - WebSockets
void handleMessage(WebsocketsClient &client, WebsocketsMessage message) {
  auto data = message.data();

  // Log message
  Serial.print("Got Message: ");
  Serial.println(data);

  // Echo message
  client.send("Echo: " + data);
}

void handleEvent(WebsocketsClient &client, WebsocketsEvent event, String data) {
  if (event == WebsocketsEvent::ConnectionClosed) {
    Serial.println("Connection closed");
  }
}

int8_t getFreeClientIndex() {
  // If a client in our list is not available, it's connection is closed and we
  // can use it for a new client.  
  for (byte i = 0; i < maxClients; i++) {
    if (!clients[i].available()) return i;
  }
  return -1;
}

void listenForClients() {
  if (server.poll()) {
    int8_t freeIndex = getFreeClientIndex();
    if (freeIndex >= 0) {
      WebsocketsClient newClient = server.accept();
//      Serial.printf("Accepted new websockets client at index %d\n", freeIndex);
      newClient.onMessage(handleMessage);
      newClient.onEvent(handleEvent);
      newClient.send("Hello from Teensy");
      clients[freeIndex] = newClient;
    }
  }
}

void pollClients() {
  for (byte i = 0; i < maxClients; i++) {
    clients[i].poll();
  }
}

void sendReadings() {
  String dataToSend = handleRaw();
  for (byte i = 0; i < maxClients; i++) {
    clients[i].send(dataToSend);
  }
}

// MARK: - Sensor
String handleRaw() {
  Serial.println("Reading raw sensor data");
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

  return payload.c_str();
}
