import numpy as np
from scipy.io import wavfile

# Configuration pour une boucle parfaite et légère
duree_secondes = 3600/4 # 15 minutes
sample_rate = 44100

# Les fréquences "Deep Bass" que nous avions validées
pistes = [
    {"nom": "1_binaural_sleep_delta", "f_gauche": 60, "f_droite": 63},
    {"nom": "2_binaural_meditation_theta", "f_gauche": 70, "f_droite": 76},
    {"nom": "3_binaural_relax_alpha", "f_gauche": 80, "f_droite": 90},
    {"nom": "4_binaural_focus_beta", "f_gauche": 90, "f_droite": 105}
]

t = np.linspace(0, duree_secondes, int(sample_rate * duree_secondes), endpoint=False)

print("Génération des boucles WAV parfaites (10 secondes)...")

for piste in pistes:
    onde_gauche = 0.5 * np.sin(2 * np.pi * piste['f_gauche'] * t)
    onde_droite = 0.5 * np.sin(2 * np.pi * piste['f_droite'] * t)
    
    signal_stereo = np.vstack((onde_gauche, onde_droite)).T
    signal_stereo = np.int16(signal_stereo * 32767)
    
    # On sauvegarde directement en WAV
    wavfile.write(f"{piste['nom']}.wav", sample_rate, signal_stereo)
    
print("Terminé ! Prêt pour une intégration 100% seamless dans Expo.")