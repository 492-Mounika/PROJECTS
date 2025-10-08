# ⚡ Battery Voltage & Current Logger (ESP8266)

## 📘 Overview
This project logs **battery voltage** and **current** using an **ESP8266** microcontroller.  
It’s designed as a low-cost, Wi-Fi–enabled data logger for monitoring Li-ion battery behavior.  
Future extensions will include **power measurement**, **deep-sleep optimization**, and **wireless data upload**.

---

## 🧠 Project Goals
- Measure and log **battery voltage** using the ESP8266 ADC.  
- Add **current measurement** using an **INA219** I²C current sensor.  
- Log data via **Serial** or **Wi-Fi** (coming soon).  
- Experiment with **low-power modes** (deep sleep).  
- Demonstrate techniques relevant to **low-power embedded design** and **battery management systems (BMS)**.

---

## 🔩 Hardware Setup
| Component | Purpose | Notes |
|------------|----------|-------|
| **ESP8266 Dev Board** | Main controller | NodeMCU / Wemos D1 Mini |
| **Li-ion Cell (18650)** | Power source | Use a protection board! |
| **Voltage Divider (R1=100kΩ, R2=100kΩ)** | Scales battery voltage into ADC-safe range | 4.2 V → 2.1 V |
| **INA219 Module** | Measures current, bus voltage, and power via I²C | SDA → D2 (GPIO4), SCL → D1 (GPIO5) |
| **USB Cable** | Programming & Serial monitor |  |
| **Jumper Wires & Breadboard** | Connections |  |

---

## ⚙️ Software Setup

### 1. Arduino IDE Setup
- Install [Arduino IDE](https://www.arduino.cc/en/software)
- Add ESP8266 board support:  
- File → Preferences → Additional Boards Manager URLs:
- http://arduino.esp8266.com/stable/package_esp8266com_index.json
- Then go to **Tools → Board → Boards Manager**, search **“esp8266”**, and install it.

### 2. Required Libraries
- [Adafruit INA219](https://github.com/adafruit/Adafruit_INA219)
- **Wire.h** (built-in)
- **ESP8266WiFi.h** (for future Wi-Fi logging)
- **ArduinoJson** (optional, for structured data)

---

## 🧪 Current Progress

✅ **Voltage Logging (Completed):**
- Connected battery through voltage divider.
- Read ADC values from ESP8266.
- Converted ADC values to actual voltage using scaling:
- Vbat = ADC_value * (Vref / 1023) * (R1 + R2) / R2

---

## 📆 Development Timeline
| Week | Task |
|------|------|
| 1–2 | Setup ESP8266 & test voltage divider |
| 3–4 | Integrate INA219 for current & power |
| 5–6 | Implement Serial/Wi-Fi logging |
| 7–8 | Add deep sleep, measure power savings |
| 9–12 | Report, plots, polish & documentation |

---

## 📚 Learning Focus
- ADC scaling and calibration  
- I²C communication  
- Power-efficient firmware design  
- Data logging & visualization  

---

This project helps me connect **low-power embedded design** with **real-world hardware behavior**.  
Working on voltage and current logging deepens my understanding of **power management**, **ADC integration**, and **mixed-signal design** 
— core aspects of modern **low-power VLSI systems**.
