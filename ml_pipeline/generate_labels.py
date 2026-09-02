labels = [
    "Fire Alarm / Smoke Detector",
    "Emergency Siren",
    "Screaming",
    "Glass Breaking",
    "Explosion / Gunshot",
    "Doorbell / Chime",
    "Door Knocking",
    "Phone Ringing / Alarm Clock",
    "Baby Cry",
    "Dog Barking",
    "Cat Meowing",
    "Water Running",
    "Microwave Beep",
    "Smoke / CO Detector",
    "Vehicle Horn / Car Honking",
    "Brake Squeal",
    "Motorcycle Engine",
    "Train Whistle",
    "Rain / Thunder",
    "Speech / Talking",
    "Coughing",
    "Sneezing",
    "Laughter",
    "Footsteps",
    "Kitchen Clatter",
    "Door Open / Slam",
    "Ambient / Background Noise",
    "Appliance Alert Beep"
]

with open(r"d:\SANA\sana_app\assets\labels\labels.txt", "w", encoding="utf-8") as f:
    for label in labels:
        f.write(label + "\n")

print(f"Generated {len(labels)} labels in assets/labels/labels.txt")
