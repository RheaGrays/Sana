import csv

sana_classes = [
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

with open(r"d:\SANA\sana_app\assets\labels\yamnet_class_map.csv", "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)
    yamnet_rows = list(reader)

mapping = {}
for idx, mid, display_name in yamnet_rows:
    dn_lower = display_name.lower()
    for sc in sana_classes:
        sc_lower = sc.lower()
        # Direct keyword matching
        if any(term in dn_lower for term in ["fire alarm", "smoke detector", "siren", "scream", "glass", "explosion", "gunshot", "doorbell", "knock", "telephone", "alarm clock", "baby cry", "infant cry", "bark", "meow", "water", "microwave", "horn", "honk", "brake", "motorcycle", "train", "rain", "thunder", "speech", "talk", "cough", "sneeze", "laughter", "gasp", "footstep", "dishes", "cutlery", "door", "beep"]):
            pass

print(f"Total YAMNet classes: {len(yamnet_rows)}")
