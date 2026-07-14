/**
 * Arduino Robot Bluetooth Controller Test Sketch
 * 
 * This code controls the built-in LED (usually Pin 13) via serial bluetooth.
 * 
 * Behavior:
 * - When any movement button is HELD (sending 'F', 'B', 'L', or 'R'), the built-in LED blinks.
 * - When the button is RELEASED (sending 'S'), the built-in LED turns off.
 * 
 * Communication details:
 * - HC-05/06 modules typically communicate at 9600 Baud by default.
 * - Uses non-blocking timing (millis()) to keep the serial reader responsive.
 */

// Define Pins
const int LED_PIN = 13; // Built-in LED on most Arduinos (Uno, Nano, Mega)

// Blinking Interval
const unsigned long BLINK_INTERVAL = 200; // ms between blink state changes

// State Variables
bool isBlinking = false;
unsigned long lastBlinkTime = 0;
int ledState = LOW;

void setup() {
  // Initialize built-in LED pin as output
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW); // Start with LED off
  
  // Initialize Serial Communication.
  // Note: HC-05 and HC-06 modules use 9600 Baud by default.
  // Connect HC-05 TX to Arduino RX (Pin 0) and HC-05 RX to Arduino TX (Pin 1).
  // REMEMBER: Disconnect the Bluetooth RX/TX lines when uploading this sketch!
  Serial.begin(38400);
  
  // Print status to debug console if connected to computer
  Serial.println("Arduino Bluetooth Controller Test Ready.");
}

void loop() {
  // Check if serial data is available
  if (Serial.available() > 0) {
    // Read the incoming byte
    char command = Serial.read();
    
    // Process the received command character
    switch (command) {
      case 'F': // Forward
      case 'B': // Backward
      case 'L': // Left
      case 'R': // Right
        isBlinking = true;
        // Optional: Echo back status to the mobile app console
        Serial.println("ACK: LED Blinking");
        break;
        
      case 'S': // Stop (button released)
        isBlinking = false;
        digitalWrite(LED_PIN, LOW); // Turn off LED immediately
        Serial.println("ACK: LED Stopped");
        break;
        
      default:
        // Ignore other control messages (e.g. speed updates, auxiliary logs)
        break;
    }
  }

  // Handle non-blocking LED blinking
  if (isBlinking) {
    unsigned long currentMillis = millis();
    if (currentMillis - lastBlinkTime >= BLINK_INTERVAL) {
      lastBlinkTime = currentMillis;
      
      // Toggle LED state
      if (ledState == LOW) {
        ledState = HIGH;
      } else {
        ledState = LOW;
      }
      digitalWrite(LED_PIN, ledState);
    }
  }
}
