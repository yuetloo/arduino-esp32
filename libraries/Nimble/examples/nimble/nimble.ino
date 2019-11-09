#include "Nimble.h"

Nimble nimble;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial.println("ESP32 SDK: ");
  Serial.println(ESP.getSdkVersion());
  nimble.begin("nimble esp32");

  Serial.println("Advertising started with device name: nimble esp32");
}

void loop() {
  // put your main code here, to run repeatedly:

}
