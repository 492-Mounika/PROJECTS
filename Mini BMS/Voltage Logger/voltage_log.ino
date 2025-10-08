// Battery voltage monitoring on ESP8266 (NodeMCU / Wemos D1 Mini)
// Using external divider: R1 = 47k, R2 = 150k

const float R1 = 47000.0;   // Resistor from battery+ to A0
const float R2 = 150000.0;  // Resistor from A0 to GND

void setup() {
  Serial.begin(57600);
  delay(2000);
  Serial.println("Battery Voltage Monitor Started");
}

void loop() {
  int raw = analogRead(A0);   // 10-bit ADC → 0–1023
  float Vadc = (raw / 1023.0) * 3.2;  // A0 max = 3.2V (already has internal divider)
  
  // Calculate battery voltage using resistor divider
  float Vbat = Vadc * ((R1 + R2) / R2);

  Serial.print("Raw ADC: ");
  Serial.print(raw);
  Serial.print("  |  ADC Voltage: ");
  Serial.print(Vadc, 3);
  Serial.print(" V  |  Battery Voltage: ");
  Serial.print(Vbat, 3);
  Serial.println(" V");

  delay(2000); // Read every 2 seconds
}
