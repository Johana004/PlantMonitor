#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

const char* ssid = "PlantMonitor";
const char* password = "12345678";

WebServer server(80);

void addSensor(
    JsonArray &array,
    const char* sensorName,
    int temperature,
    int humidity,
    int light,
    int soilMoisture,
    int battery,
    int rain)
{
    JsonObject sensor = array.createNestedObject();

    sensor["sensorName"] = sensorName;
    sensor["temperature"] = temperature;
    sensor["humidity"] = humidity;
    sensor["light"] = light;
    sensor["soilMoisture"] = soilMoisture;
    sensor["battery"] = battery;
    sensor["rain"] = rain;
}

void handleRoot() {
  server.send(200, "text/plain", "LoRa Monitor Server");
}

void handleGetName() {
  server.send(200, "text/plain", "loraMonitor");
}

void handleGetAllData() {

    StaticJsonDocument<1024> doc;
    JsonArray sensors = doc.to<JsonArray>();

    addSensor(sensors, "sensorOne",   30, 80, 13, 88, -50, 89);
    addSensor(sensors, "sensorTwo",   31, 81, 14, 87, -49, 88);
    addSensor(sensors, "sensorThree", 32, 82, 15, 86, -48, 87);
    addSensor(sensors, "sensorFour",  29, 78, 12, 84, -47, 86);
    

    String response;
    serializeJson(doc, response);

    server.send(200, "application/json", response);
}

void handleDeleteAllData() {

  // Fake delete for testing
  // Replace with actual file deletion if needed

  Serial.println("[Server] deleteAllData");

  server.send(200, "text/plain", "ok");
}

void setup() {

  Serial.begin(115200);

  Serial.println();
  Serial.println("Starting AP...");
  IPAddress local_ip(192, 168, 1, 22);
  IPAddress gateway(192, 168, 1, 1);
  IPAddress subnet(255, 255, 255, 0);

  WiFi.softAPConfig(local_ip, gateway, subnet);
  
  WiFi.softAP(ssid, password);

  Serial.print("AP IP Address: ");
  Serial.println(WiFi.softAPIP());

  server.on("/", HTTP_GET, handleRoot);

  server.on("/getName", HTTP_GET, handleGetName);

  server.on("/getAllData", HTTP_GET, handleGetAllData);

  server.on("/deleteAllData", HTTP_GET, handleDeleteAllData);

  server.begin();

  Serial.println("Web server started");
}

void loop() {
  server.handleClient();
}