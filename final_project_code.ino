#include <Adafruit_NeoPixel.h>

Adafruit_NeoPixel strip(60, 12);

bool flashActive = false;
unsigned long flashStart = 0;
int flashDuration = 120; 

void setup() {
  Serial.begin(9600);

  strip.begin();
  strip.clear();
  strip.show();
}

void loop() {
  if (Serial.available() > 0) {
    char reading = Serial.read();

    if (reading == '1') {
      flashActive = true;
      flashStart = millis();

      for (int i = 0; i < strip.numPixels(); i++) {
        strip.setPixelColor(i, strip.Color(255, 255, 255)); 
      }
      strip.show();
    }
  }

  if (flashActive && millis() - flashStart >= flashDuration) {
    flashActive = false;
    strip.clear();
    strip.show();
  }
}