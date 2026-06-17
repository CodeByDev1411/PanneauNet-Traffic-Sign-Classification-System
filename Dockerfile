# PanneauNet — Belgian Traffic Sign Recognition
#
# Renamed / modernized / bug-fixed derivative of the Dockerfile from
# https://github.com/waleedka/traffic-signs-tensorflow
#
# FIXES vs. the original Dockerfile:
#   1. Base image was pinned to a long-abandoned TensorFlow 0.11 image
#      (waleedka/modern-deep-learning). Replaced with the official,
#      maintained TensorFlow 2.x + Jupyter image.
#   2. `git clone https://github.com/waleedka/traffic-signs-tensorflow /traffic`
#      pulled someone else's repo at build time. Since this is now its own
#      project, we COPY the local project files into the image instead.
#   3. `curl -o file.zip <url>` had no `-L` flag, so curl did not follow
#      HTTP redirects. ETH Zurich's dataset server redirects requests,
#      which meant the original command silently downloaded a small HTML
#      page instead of the actual zip file, and `unzip` would then fail.
#      Added `-L` (and `-f` to fail loudly on HTTP errors) to fix this.
#   4. Added the scikit-image / imageio / matplotlib packages that the
#      notebook needs but the base image does not ship with.
#   5. Cleaned up apt cache and added --no-cache-dir to pip to keep the
#      image smaller.

FROM tensorflow/tensorflow:2.16.1-jupyter

LABEL maintainer="Your Name <you@example.com>"
LABEL description="PanneauNet - Belgian traffic sign classifier (TensorFlow 2.x)"

# System packages needed to fetch/unpack the dataset and to support
# scikit-image / matplotlib in a headless container.
RUN apt-get update && apt-get install -y --no-install-recommends \
        unzip \
        curl \
        libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies not already bundled with the base image.
RUN pip install --no-cache-dir \
        scikit-image \
        imageio \
        matplotlib

# Copy the project (notebook, README, etc.) into the image.
WORKDIR /panneaunet
COPY . /panneaunet

# Download the Belgian Traffic Sign Dataset (BelgiumTSC).
# Source: http://btsd.ethz.ch/shareddata/
WORKDIR /panneaunet/datasets
RUN curl -fL -o test.zip http://btsd.ethz.ch/shareddata/BelgiumTSC/BelgiumTSC_Testing.zip && \
    unzip -q test.zip -d BelgiumTS/ && \
    rm test.zip
RUN curl -fL -o train.zip http://btsd.ethz.ch/shareddata/BelgiumTSC/BelgiumTSC_Training.zip && \
    unzip -q train.zip -d BelgiumTS/ && \
    rm train.zip

WORKDIR /panneaunet
ENV DATA_ROOT=/panneaunet/datasets
EXPOSE 8888

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
