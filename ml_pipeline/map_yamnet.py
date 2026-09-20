import csv
import json

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
    rows = list(reader)

mapping = {}

keywords = {
    "Fire Alarm / Smoke Detector": ["fire alarm", "smoke alarm", "fire", "alarm"],
    "Emergency Siren": ["siren", "ambulance", "police car", "fire engine", "emergency vehicle"],
    "Screaming": ["screaming", "scream", "shout", "yell"],
    "Glass Breaking": ["glass", "shatter", "breaking"],
    "Explosion / Gunshot": ["explosion", "gunshot", "gunfire", "artillery fire", "blast", "burst"],
    "Doorbell / Chime": ["doorbell", "ding-dong", "chime", "bell"],
    "Door Knocking": ["knock", "tap", "door"],
    "Phone Ringing / Alarm Clock": ["telephone", "ringtone", "telephone bell", "alarm clock", "cell phone buzzer"],
    "Baby Cry": ["baby cry", "crying, sob", "infant cry", "whimper"],
    "Dog Barking": ["bark", "dog", "howl", "growling", "bow-wow"],
    "Cat Meowing": ["meow", "cat", "purr", "caterwaul"],
    "Water Running": ["water", "stream", "liquid", "fill (with liquid)", "gargling", "drip", "flush"],
    "Microwave Beep": ["microwave oven", "microwave"],
    "Smoke / CO Detector": ["carbon monoxide detector", "detector", "beep"],
    "Vehicle Horn / Car Honking": ["vehicle horn", "car horn", "honk", "toot", "klaxon"],
    "Brake Squeal": ["screeching", "skidding", "squeal", "brake"],
    "Motorcycle Engine": ["motorcycle", "motorbike"],
    "Train Whistle": ["train", "train horn", "whistle", "locomotive"],
    "Rain / Thunder": ["rain", "thunder", "thunderstorm", "raindrop", "lightning"],
    "Speech / Talking": ["speech", "conversation", "narration", "whispering", "babbling", "singing"],
    "Coughing": ["cough", "throat clearing"],
    "Sneezing": ["sneeze"],
    "Laughter": ["laughter", "giggle", "snicker", "chuckle"],
    "Footsteps": ["footsteps", "run", "patter", "walk"],
    "Kitchen Clatter": ["dishes, pots, and pans", "cutlery, silverware", "frying (food)", "boiling"],
    "Door Open / Slam": ["door", "slam", "sliding door"],
    "Ambient / Background Noise": ["silence", "white noise", "pink noise", "static", "hum", "environmental noise"],
    "Appliance Alert Beep": ["beep, bleep", "buzzer", "timer", "alarm"]
}

for idx_str, mid, name in rows:
    idx = int(idx_str)
    name_lower = name.lower()
    matched = None
    
    for sana_class, terms in keywords.items():
        if any(term in name_lower for term in terms):
            matched = sana_class
            break
            
    if matched:
        mapping[idx] = matched
    else:
        mapping[idx] = "Ambient / Background Noise"

with open(r"d:\SANA\sana_app\assets\labels\yamnet_mapping.json", "w", encoding="utf-8") as f:
    json.dump(mapping, f, indent=2)

print(f"Mapped {len(mapping)} YAMNet classes to SANA taxonomy.")
