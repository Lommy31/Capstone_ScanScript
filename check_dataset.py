
from datasets import load_dataset
import matplotlib.pyplot as plt
import numpy as np
from preprocessing.preprocessing import preprocess_image

# Load dataset
ds = load_dataset("Teklia/IAM-line")

# Test 10 different images
num_images = 10
methods = [
    "original",
    "contrast",
    "binarization",
    "contrast_binarization",
]

titles = [
    "Original",
    "CLAHE Contrast",
    "Otsu Binarization",
    "CLAHE + Otsu",
]

for i in range(num_images):
    sample = ds["train"][i]
    image = np.array(sample["image"].convert("L"))
    text = sample["text"]

    fig, axes = plt.subplots(4, 1, figsize=(14, 7))

    for ax, method, title in zip(axes, methods, titles):
        result = preprocess_image(image, method=method)
        ax.imshow(result, cmap="gray")
        ax.set_title(title)
        ax.axis("off")

    fig.suptitle(f"Image {i + 1}/10 | Ground Truth: {text}")
    plt.tight_layout()

    # Save results for each image
    import os
    os.makedirs("experiments", exist_ok=True)
    fig.savefig(f"experiments/image_{i + 1}.png", dpi=150,
                bbox_inches="tight")

    plt.close(fig)

print("Done! Results saved in the experiments folder.")
