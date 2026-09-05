#include <Wire.h>
#include "MMA7660.h"
#include <Adafruit_NeoPixel.h>

// --- Existing hardware ----------------------------------------------------

#define FORCE_SENSOR_PIN A6
#define LED_PIN 6
#define LED_COUNT 1

const int POT_SLIDER_PIN = A7;
const int BUTTON1_PIN = 2;
const int BUTTON2_PIN = 3;
const int BUTTON3_PIN = 4;
const int BUTTON4_PIN = 5;

// Button 3 is now the deliberate calibration control. Button 4 remains the
// performance safety control and is still sent to Max as button_4.
const int CALIBRATION_BUTTON_PIN = BUTTON3_PIN;
const int KILL_ALL_BUTTON_PIN = BUTTON4_PIN;

MMA7660 accelerometer;
Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);

// --- Timing and tuning ----------------------------------------------------

// 30 readings per second: responsive enough for performance controls.
const unsigned long SAMPLE_INTERVAL_MS = 33;

// Exponential smoothing. Higher = quicker but more jittery.
const float FILTER_ALPHA = 0.22f;

// Approximate useful gesture ranges from today's tests.
const float LEFT_RIGHT_RANGE_G = 0.70f;
const float FORWARD_BACK_RANGE_RADIANS = 35.0f * DEG_TO_RAD;

// Ignore small changes near the calibrated centre.
const float CONTROL_DEAD_ZONE = 0.08f;

// Ignore tiny frame-to-frame changes when estimating movement strength.
const float MOTION_NOISE_FLOOR_G = 0.015f;
const float MOTION_FULL_SCALE_G = 0.20f;

// --- State ----------------------------------------------------------------

unsigned long lastSampleTime = 0;

float neutralX = 0.0f;
float neutralY = 0.0f;
float neutralZ = 0.0f;
float neutralForwardBackAngle = 0.0f;

float filteredX = 0.0f;
float filteredY = 0.0f;
float filteredZ = 0.0f;

float previousX = 0.0f;
float previousY = 0.0f;
float previousZ = 0.0f;
float filteredMotion = 0.0f;

const unsigned long CALIBRATION_HOLD_MS = 2000;
unsigned long calibrationButtonPressStart = 0;
bool calibrationTriggered = false;
bool calibrationAwaitingRelease = false;
bool previousKillButtonPressed = false;

void setup() {
  Serial.begin(57600);
  accelerometer.init();

  pinMode(BUTTON1_PIN, INPUT);
  pinMode(BUTTON2_PIN, INPUT);
  pinMode(BUTTON3_PIN, INPUT);
  pinMode(BUTTON4_PIN, INPUT);

  strip.begin();
  strip.show();

  calibrateNeutral();
}

void loop() {
  checkForRecalibration();
  updateKillAllLed();

  unsigned long currentTime = millis();
  if (currentTime - lastSampleTime < SAMPLE_INTERVAL_MS) {
    return;
  }
  lastSampleTime = currentTime;

  float rawX, rawY, rawZ;
  if (!accelerometer.getAcceleration(&rawX, &rawY, &rawZ)) {
    return;
  }

  // A simple low-pass filter: keep most of the previous result and add a
  // little of the new measurement. This reduces one-count sensor flicker.
  filteredX += FILTER_ALPHA * (rawX - filteredX);
  filteredY += FILTER_ALPHA * (rawY - filteredY);
  filteredZ += FILTER_ALPHA * (rawZ - filteredZ);

  float magnitude = sqrt(
    filteredX * filteredX +
    filteredY * filteredY +
    filteredZ * filteredZ
  );

  // In today's holding orientation, left/right mostly changed X.
  float roll = (filteredX - neutralX) / LEFT_RIGHT_RANGE_G;
  roll = applyDeadZone(constrain(roll, -1.0f, 1.0f), CONTROL_DEAD_ZONE);

  // Forward/back made Y and Z trade gravity between them. atan2 turns that
  // circular movement into one angle, then we subtract the neutral angle.
  float forwardBackAngle = atan2(filteredZ, filteredY);
  float pitch = wrappedAngleDifference(
    forwardBackAngle,
    neutralForwardBackAngle
  ) / FORWARD_BACK_RANGE_RADIANS;
  pitch = applyDeadZone(constrain(pitch, -1.0f, 1.0f), CONTROL_DEAD_ZONE);

  // Frame-to-frame vector change: zero while still, larger while gesturing.
  float deltaX = filteredX - previousX;
  float deltaY = filteredY - previousY;
  float deltaZ = filteredZ - previousZ;
  float vectorChange = sqrt(
    deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ
  );

  float motion = (vectorChange - MOTION_NOISE_FLOOR_G) /
                 (MOTION_FULL_SCALE_G - MOTION_NOISE_FLOOR_G);
  motion = constrain(motion, 0.0f, 1.0f);
  filteredMotion += 0.25f * (motion - filteredMotion);

  previousX = filteredX;
  previousY = filteredY;
  previousZ = filteredZ;

  printControls(magnitude, roll, pitch, filteredMotion);
}

void checkForRecalibration() {
  // Same active-low read used by the original working buttonPress().
  bool calibrationButtonPressed = !digitalRead(CALIBRATION_BUTTON_PIN);

  // Once the two-second hold has been recognised, wait for the user to
  // release Button 3 before collecting any neutral readings. This prevents
  // the pressure of holding the button from becoming part of calibration.
  if (calibrationAwaitingRelease) {
    if (calibrationButtonPressed) {
      return;
    }

    calibrationAwaitingRelease = false;
    calibrationButtonPressStart = 0;
    Serial.println("status settling_before_neutral_calibration");
    delay(500);

    calibrateNeutral();
    calibrationTriggered = false;
    lastSampleTime = millis();
    return;
  }

  if (!calibrationButtonPressed) {
    calibrationButtonPressStart = 0;
    calibrationTriggered = false;
    return;
  }

  if (calibrationButtonPressStart == 0) {
    calibrationButtonPressStart = millis();
    return;
  }

  if (!calibrationTriggered &&
      millis() - calibrationButtonPressStart >= CALIBRATION_HOLD_MS) {
    calibrationTriggered = true;
    calibrationAwaitingRelease = true;
    Serial.println("status release_button_and_hold_neutral");
    setLed(0, 0, 80);  // Blue: release Button 3 and hold the device still.
  }
}

void calibrateNeutral() {
  Serial.println("status hold_still_for_neutral_calibration");
  setLed(0, 0, 80);  // Blue while calibrating.

  const int CALIBRATION_SAMPLES = 60;
  int validSamples = 0;
  float sumX = 0.0f;
  float sumY = 0.0f;
  float sumZ = 0.0f;

  for (int i = 0; i < CALIBRATION_SAMPLES; i++) {
    float x, y, z;
    if (accelerometer.getAcceleration(&x, &y, &z)) {
      sumX += x;
      sumY += y;
      sumZ += z;
      validSamples++;
    }
    delay(SAMPLE_INTERVAL_MS);
  }

  if (validSamples > 0) {
    neutralX = sumX / validSamples;
    neutralY = sumY / validSamples;
    neutralZ = sumZ / validSamples;
  }

  filteredX = neutralX;
  filteredY = neutralY;
  filteredZ = neutralZ;
  previousX = neutralX;
  previousY = neutralY;
  previousZ = neutralZ;
  filteredMotion = 0.0f;
  neutralForwardBackAngle = atan2(neutralZ, neutralY);

  Serial.println("status ready");
  setLed(0, 80, 0);  // Green when ready.
}

void updateKillAllLed() {
  // The button remains active-low: LOW means that Button 4 is being pressed.
  bool killButtonPressed = !digitalRead(KILL_ALL_BUTTON_PIN);

  // Only update the NeoPixel when the state changes. This avoids repeatedly
  // writing the same colour on every pass through loop().
  if (killButtonPressed && !previousKillButtonPressed) {
    setLed(80, 0, 0);  // Red while kill-all is held.
  }

  if (!killButtonPressed && previousKillButtonPressed) {
    setLed(0, 80, 0);  // Return to green when released.
  }

  previousKillButtonPressed = killButtonPressed;
}

void printControls(float magnitude, float roll, float pitch, float motion) {
  // Existing labels remain compatible with the current Max serial routing.
  Serial.print("xg ");
  Serial.println(filteredX, 3);
  Serial.print("yg ");
  Serial.println(filteredY, 3);
  Serial.print("zg ");
  Serial.println(filteredZ, 3);

  // New audience-facing controls, each normalised to a useful 0 or -1..1.
  Serial.print("roll ");
  Serial.println(roll, 3);
  Serial.print("pitch ");
  Serial.println(pitch, 3);
  Serial.print("motion ");
  Serial.println(motion, 3);
  Serial.print("magnitude ");
  Serial.println(magnitude, 3);

  Serial.print("slider ");
  Serial.println(analogRead(POT_SLIDER_PIN));
  Serial.print("Force_sensor ");
  Serial.println(analogRead(FORCE_SENSOR_PIN));

  Serial.print("button_1 ");
  Serial.println(!digitalRead(BUTTON1_PIN));
  Serial.print("button_2 ");
  Serial.println(!digitalRead(BUTTON2_PIN));
  Serial.print("button_3 ");
  Serial.println(!digitalRead(BUTTON3_PIN));
  Serial.print("button_4 ");
  Serial.println(!digitalRead(BUTTON4_PIN));
}

float applyDeadZone(float value, float deadZone) {
  float amount = fabs(value);
  if (amount <= deadZone) {
    return 0.0f;
  }

  float rescaled = (amount - deadZone) / (1.0f - deadZone);
  return value < 0.0f ? -rescaled : rescaled;
}

float wrappedAngleDifference(float angle, float reference) {
  float difference = angle - reference;

  while (difference > PI) {
    difference -= TWO_PI;
  }
  while (difference < -PI) {
    difference += TWO_PI;
  }

  return difference;
}

void setLed(byte red, byte green, byte blue) {
  strip.setPixelColor(0, strip.Color(red, green, blue));
  strip.show();
}
