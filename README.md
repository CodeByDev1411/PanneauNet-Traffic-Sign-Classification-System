    # PanneauNet 🚦

**Belgian traffic sign recognition with TensorFlow 2 — a modernized, bug-fixed rebuild of a classic deep-learning tutorial.**

*"Panneau"* is French for "sign" or "panel" — a nod to the Belgian dataset this project is trained on.

---

## What this is

PanneauNet trains a neural network to classify cropped photos of Belgian traffic signs into one of 62 categories (stop signs, speed limits, yield signs, and so on). It's a renamed, updated, and corrected version of an older tutorial that no longer runs on current software — see [Origin & credit](#origin--credit) and [What was fixed](#what-was-fixed-and-why) below for details.

## Project structure

```
panneaunet/
├── Dockerfile                            # Reproducible environment + dataset download
├── PanneauNet_Part1_Classification.ipynb # Part 1: data loading, preprocessing, training, evaluation
├── README.md                             # You are here
└── datasets/                             # Created at build/setup time (see below)
    └── BelgiumTS/
        ├── Training/   (62 sub-folders, 00000–00061)
        └── Testing/    (62 sub-folders, 00000–00061)
```

## Getting the dataset

This project uses the **BelgiumTSC — Belgian Traffic Sign Dataset for Classification**, published by ETH Zürich.

* Source: **http://btsd.ethz.ch/shareddata/**
* You only need the two files listed under **"BelgiumTS for Classification (cropped images)"**:
  * `BelgiumTSC_Training` (171.3 MB)
  * `BelgiumTSC_Testing` (76.5 MB)

After downloading and extracting, you should have:

```
datasets/BelgiumTS/Training/
datasets/BelgiumTS/Testing/
```

Each contains 62 sub-directories, numbered `00000` to `00061`. The directory name is the label; the `.ppm` images inside it are examples of that label.

If you use the included Dockerfile, this download happens automatically during `docker build`.

## Running it

### Option 1 — Docker (recommended, matches the tested environment)

```bash
docker build -t panneaunet .
docker run -it -p 8888:8888 -v $(pwd):/panneaunet panneaunet
```

This builds an image with TensorFlow 2.x, Jupyter, scikit-image, and the dataset already downloaded into `/panneaunet/datasets`, then starts Jupyter on port 8888.

### Option 2 — Local Python environment

```bash
pip install tensorflow scikit-image imageio matplotlib jupyter
# Download & extract the dataset yourself (see above) into ./datasets
export DATA_ROOT=./datasets   # optional — this is the default
jupyter notebook PanneauNet_Part1_Classification.ipynb
```

## What's in the notebook

`PanneauNet_Part1_Classification.ipynb` walks through:

1. Loading the `.ppm` training/testing images and their labels.
2. Exploring the dataset (image counts, sizes, per-label samples).
3. Resizing images to a fixed 32×32 input.
4. Building a minimal single-layer neural network in `tf.keras`.
5. Training it and visualizing predictions vs. ground truth.
6. Evaluating accuracy on the held-out test set.

This is intentionally a *minimum viable model* — a starting point, not a state-of-the-art classifier. It typically reaches roughly 40–60% test accuracy depending on random initialization and training length, which leaves plenty of room for adding convolutional layers, data augmentation, and longer training as next steps.

## What was fixed (and why)

The original tutorial this is based on was written in 2016 for Python 3.5 and TensorFlow 0.11. Running it as-is today fails outright in several places. Here's everything that was broken and how it was addressed:

| # | Problem | Fix |
|---|---|---|
| 1 | `skimage.data.imread(...)` — this function was removed from scikit-image years ago, so loading any image raised an `AttributeError`. | Switched to `skimage.io.imread(...)`, the supported equivalent. |
| 2 | The model was built with TensorFlow 1.x-era APIs (`tf.placeholder`, `tf.Session`, `tf.contrib.layers.flatten`, `tf.contrib.layers.fully_connected`, `tf.train.AdamOptimizer`, `tf.global_variables_initializer`) — **none of these exist in TensorFlow 2**, so the notebook couldn't even build the computation graph. | Rebuilt the same single-layer network using `tf.keras.Sequential`, and replaced the manual session/training loop with `model.compile()` + `model.fit()`. Evaluation now uses `model.evaluate()` / `model.predict()` instead of manual `session.run()` calls. |
| 3 | The closing `session.close()` call has no equivalent need in TensorFlow 2, which runs eagerly by default — leaving it in would just error on a name that no longer exists. | Removed, with a note explaining why it's unnecessary now. |
| 4 | The dataset root was hardcoded to `/traffic`, which only existed inside the original author's specific Docker setup. | Replaced with a `DATA_ROOT` environment variable (defaulting to `./datasets`), so the same notebook works inside or outside Docker. |
| 5 | The Dockerfile's `curl -o file.zip <url>` calls had no `-L` flag. ETH Zürich's data server issues an HTTP redirect for these URLs, so curl was silently saving a small HTML redirect page instead of the actual dataset archive — `unzip` would then fail with a cryptic "End-of-central-directory signature not found" error. | Added `-fL` to both `curl` calls so redirects are followed and HTTP errors fail the build loudly instead of silently. |
| 6 | The base Docker image (`waleedka/modern-deep-learning`) is several years unmaintained and pinned to TensorFlow 0.11. | Switched to the official, actively maintained `tensorflow/tensorflow:2.16.1-jupyter` image, and added the extra packages (scikit-image, imageio, matplotlib) it doesn't ship with by default. |
| 7 | The Dockerfile `git clone`'d the original author's GitHub repo at build time rather than using local project files. | Replaced with `COPY . /panneaunet`, since this is now a standalone project rather than a fork being rebuilt in-place. |
| 8 | The README text said sub-directories were numbered "00000 to 00062" — off by one, since there are 62 directories numbered 0 through 61. | Corrected throughout. |


## Roadmap

The original tutorial was explicitly planned as a multi-part series. Parts 2 and 3 — adding convolutional layers and building a full sign-detection pipeline on video — are natural next steps and not yet included here.
