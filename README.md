# SANA: Sound-Aware Notification Assistant

> **A Smartphone-Based Environmental Sound Classification and Acoustic Event Journaling System for the Deaf and Hard-of-Hearing**
> 
> *Bachelor of Science in Computer Science Thesis, Cor Jesu College*  
> *Developed by: Rhea Grace P. Balatero, Joachim B. Olaco, Jan Carlo G. Surig*

---

## 📌 Overview

**SANA (Sound-Aware Notification Assistant)** is an on-device, privacy-preserving mobile assistive platform tailored for the Deaf and Hard-of-Hearing (DHH). SANA addresses the widespread issue of **Notification Fatigue** and situational unawareness by pairing real-time **28-class environmental sound classification** with **context-aware priority ranking (CASPA)** and **longitudinal acoustic journaling & pattern mining (APMA)** based on *Ecological Momentary Assessment (EMA)* principles.

---

## 🏛 System Architecture

- **Mobile Framework**: Flutter (Dart, Android API 21+ & Web)
- **ML Engine**: On-device YAMNet 28-class classification with pre-inference **RMS Energy Gating**
- **Context Prioritization**: **CASPA Engine** (incorporating user urgency $U_{sound}$, time-of-day multipliers $T_{time}$, environmental geofences $E_{env}$, and exponential cooldowns $R_{decay}$)
- **Longitudinal Journaling**: SQLite **Acoustic Event Journal (AEJ)**
- **Behavioral Analytics**: **APMA Insights Engine** (24h temporal density clustering, $Z$-Score anomaly detection, sequential pattern mining)

---

## 🧮 Mathematical Formulations

### 1. Context-Aware Sound Prioritization Algorithm (CASPA)
$$S_p = C_{class} \times R_{decay}(c) \times \left(W_1 \cdot U_{sound}(c) + W_2 \cdot T_{time}(t) + W_3 \cdot E_{env}(z, c)\right)$$

*Exponential Cooldown:*
$$R_{decay}(c) = 1.0 - 0.9 \cdot e^{-\lambda (t - t_{last})}$$

**Decision Triage:**
- **$S_p \ge 5.0$ (HIGH)**: Visual Alert + Dynamic Screen Strobe + Differentiated Haptic Vibration
- **$2.5 \le S_p < 5.0$ (MEDIUM)**: Visual Alert Only + SQLite Journal Log
- **$S_p < 2.5$ (LOW)**: Silent Background Logging (Zero User Interruption)

---

### 2. Acoustic Pattern Mining Algorithm (APMA)
- **24-Hour Temporal Density**:
  $$D(c, h) = \frac{\text{Count}(c, h)}{\sum_{h'=0}^{23} \text{Count}(c, h')}$$
- **$Z$-Score Anomaly Detection**:
  $$z(c, d) = \frac{N(c, d) - \mu(c)}{\sigma(c)} > 2.0$$
- **Sequential Behavioral Rules**:
  Identifies co-occurrence rules ($A \xrightarrow{\Delta t} B$ within 30s).

---

## 🚀 Quick Start & Development

### Run in Development:
```bash
cd sana_app
flutter pub get
flutter run
```

### Run Unit & Algorithmic Tests:
```bash
cd sana_app
flutter test
```

### Analyze Codebase:
```bash
cd sana_app
flutter analyze
```
