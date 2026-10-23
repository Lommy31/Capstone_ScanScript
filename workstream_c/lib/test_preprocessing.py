
import os
import numpy as np
from datasets import load_dataset

from preprocessing.preprocessing import (
    preprocess_image,
    save_preprocessed_image,
)

# Load dataset IAM-line
ds = load_dataset("Teklia/IAM-line")
samples = ds["train"].select(range(10))

# Folder untuk menyimpan hasil preprocessing
output_dir = os.path.abspath("experiments/preprocessed")
os.makedirs(output_dir, exist_ok=True)

for i, sample in enumerate(samples, start=1):
    # Ubah gambar menjadi grayscale
    image = np.array(sample["image"].convert("L"))

    # Terapkan preprocessing
    processed = preprocess_image(
        image,
        method="contrast_binarization",
    )

    # Simpan setiap gambar dengan nama berbeda
    output_path = os.path.join(
        output_dir,
        f"preprocessed_{i:02d}.png",
    )

    save_preprocessed_image(processed, output_path)

    print(f"[{i}/10] Ground truth: {sample['text']}")
    print(f"      Output: {output_path}")

print("\nPreprocessing 10 gambar berhasil!")
