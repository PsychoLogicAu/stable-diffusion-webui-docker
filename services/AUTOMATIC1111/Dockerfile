FROM alpine/git:2.36.2 as download

COPY clone.sh /clone.sh

RUN . /clone.sh stable-diffusion-stability-ai https://github.com/Stability-AI/stablediffusion.git cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf \
  && rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

# c5b4593074ba6214284d6acd5f1719b6c5d739af
RUN . /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git 8392d0334956108ab53d9439c4b9fc9c4af0d66d \
  && rm -rf assets inputs

# 48211a1594f1321b00f14c9f7a5b4813144b2fb9
RUN . /clone.sh BLIP https://github.com/salesforce/BLIP.git 3a29b7410476bf5f2ba0955827390eb6ea1f4f9d
# ab527a9a6d347f364e3d185ba6d714e22d80cb3c
RUN . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 045515774882014cc14c1ba2668ab5bad9cbf7c0
# 2cf03aaf6e704197fd0dae7c7f96aa59cf1b11c9
RUN . /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator bc07ce62c179d3aab3053a623d96a071101d11cb
# 45c443b316737a4ab6e40413d7794a7f5657c19f
RUN . /clone.sh generative-models https://github.com/Stability-AI/generative-models fbdc58cab9f4ee2be7a5e1f2e2787ecd9311942f


FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install tensorrt

RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && \
  # we need those
  apt-get install -y fonts-dejavu-core rsync git jq moreutils aria2 \
  # extensions needs those
  ffmpeg libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 libcairo2-dev build-essential


WORKDIR /
# cf2772fab0af5573da775e7437e6acdca424f26e
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
  cd stable-diffusion-webui && \
  git reset --hard v1.8.0 && \
  git submodule update --init --recursive && \
  pip install -r requirements_versions.txt && \
  mkdir -p repositories && \
  cd repositories && \
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets.git && \
  cd stable-diffusion-webui-assets && \
  git reset --hard 6f7db241d2f8ba7457bac5ca9753331f0c266917

ENV ROOT=/stable-diffusion-webui

COPY --from=download /repositories/ ${ROOT}/repositories/
RUN mkdir ${ROOT}/interrogate && cp ${ROOT}/repositories/clip-interrogator/clip_interrogator/data/* ${ROOT}/interrogate
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r ${ROOT}/repositories/CodeFormer/requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install dctorch

# GFPGAN: 8d2447a2d918f8eba5a4a01463fd48e45126a379
# CLIP: d50d76daa670286dd6cacf3bcd80b5e4823fc8e1
# open_clip: v2.20.0
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install pyngrok xformers==0.0.23.post1 \
  git+https://github.com/TencentARC/GFPGAN.git@7552a7791caad982045a7bbe5634bbf1cd5c8679 \
  git+https://github.com/openai/CLIP.git@a1d071733d7111c9c014f024669f959182114e33 \
  git+https://github.com/mlfoundations/open_clip.git@v2.24.0

# there seems to be a memory leak (or maybe just memory not being freed fast enough) that is fixed by this version of malloc
# maybe move this up to the dependencies list.
RUN apt-get -y install libgoogle-perftools-dev && apt-get clean
ENV LD_PRELOAD=libtcmalloc.so

COPY . /docker

RUN \
  # mv ${ROOT}/style.css ${ROOT}/user.css && \
  # one of the ugliest hacks I ever wrote \
  sed -i 's/in_app_dir = .*/in_app_dir = True/g' /opt/conda/lib/python3.10/site-packages/gradio/routes.py && \
  git config --global --add safe.directory '*'

WORKDIR ${ROOT}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python -u webui.py --listen --port 7860 ${CLI_ARGS}
