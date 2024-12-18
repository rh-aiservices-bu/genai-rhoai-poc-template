import os
import zipfile

import requests
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="ds4sd/docling-models",
    revision="v2.0.1",
)

urls = [
    "https://github.com/JaidedAI/EasyOCR/releases/download/v1.3/latin_g2.zip",
    "https://github.com/JaidedAI/EasyOCR/releases/download/pre-v1.1.6/craft_mlt_25k.zip"
]

local_zip_paths = [
    "/opt/app-root/src/latin_g2.zip",
    "/opt/app-root/src/craft_mlt_25k.zip"
]

extract_path = "/opt/app-root/src/.EasyOCR/model/"

for url, local_zip_path in zip(urls, local_zip_paths):
    # Download the file
    response = requests.get(url)
    with open(local_zip_path, "wb") as file:
        file.write(response.content)

    # Unzip the file
    with zipfile.ZipFile(local_zip_path, "r") as zip_ref:
        zip_ref.extractall(extract_path)

    # Clean up the zip file
    os.remove(local_zip_path)
