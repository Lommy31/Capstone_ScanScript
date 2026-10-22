
import cv2
import numpy as np


def load_image(image_path):
    """Load an image from a file path."""
    image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

    if image is None:
        raise FileNotFoundError(
            f"Could not load image: {image_path}"
        )

    return image


def normalize_contrast(image):
    """Improve local contrast using CLAHE."""
    clahe = cv2.createCLAHE(
        clipLimit=2.0,
        tileGridSize=(8, 8)
    )
    return clahe.apply(image)


def binarize_image(image):
    """Convert grayscale image to binary using Otsu thresholding."""
    _, result = cv2.threshold(
        image,
        0,
        255,
        cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )
    return result


def preprocess_image(image, method="original"):
    """Apply a selected preprocessing method to a grayscale image."""
    if len(image.shape) != 2:
        raise ValueError("Input image must be grayscale.")

    if method == "original":
        return image.copy()

    elif method == "contrast":
        return normalize_contrast(image)

    elif method == "binarization":
        return binarize_image(image)

    elif method == "contrast_binarization":
        contrast = normalize_contrast(image)
        return binarize_image(contrast)

    else:
        raise ValueError(f"Unknown method: {method}")