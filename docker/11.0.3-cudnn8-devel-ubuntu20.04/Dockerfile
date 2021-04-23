FROM nvidia/cuda:11.0.3-cudnn8-devel-ubuntu20.04
LABEL maintainer "Gemfield <gemfield@civilnet.cn>"

#version
EXPOSE 5900
EXPOSE 7030
ARG PYTHON_VERSION=3.8
ARG MKL_VER="2020.4-912"
ARG PROTOBUF_VER="3.15.8"
ARG CONDA_PKG_HANDLE_VER="1.6.0"
ARG MAGMA_CUDA_VER="110"

#uncomment it in mainland china 
#RUN rm -f /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/nvidia-ml.list
ENV DEBIAN_FRONTEND=noninteractive
ADD reduce_mkl_size.sh /
#base
RUN apt update && \
    mkdir /.gemfield_install && \
    apt install -y --no-install-recommends build-essential \
        vim wget curl bzip2 git autoconf automake libtool make unzip g++ binutils cmake locales \
        ca-certificates apt-transport-https gnupg gnupg2 software-properties-common \
        libjpeg-dev libpng-dev iputils-ping net-tools libgl1 libglib2.0-0 tree \
        nginx gettext-base ibus-sunpinyin \
        libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev \
        python3-pybind11 libssl-dev && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /.gemfield_install

#App
RUN cd /tmp && \
    wget -q https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB -O- | apt-key add - && \
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    wget -q https://dl-ssl.google.com/linux/linux_signing_key.pub -O- | apt-key add - && \
    wget -q http://archive.neon.kde.org/public.key -O- | apt-key add - && \
    echo "deb https://apt.repos.intel.com/mkl all main" > /etc/apt/sources.list.d/intel-mkl.list && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/gemfield-vs.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    add-apt-repository -y http://archive.neon.kde.org/user && \
    add-apt-repository -y ppa:kdenlive/kdenlive-stable && \
    apt update && \
    apt install -y intel-mkl-64bit-${MKL_VER} code \
        ubuntu-minimal ubuntu-standard neon-desktop plasma-workspace-wayland kwin-wayland \
        kwin-wayland-backend-x11 kwin-wayland-backend-wayland kwin-x11 \
        okular kdiff3 kompare gwenview \
        kdenlive \
        tigervnc-standalone-server tigervnc-xorg-extension && \
    apt dist-upgrade -y --allow-downgrades && \
    apt autoremove -y && \
    apt clean && \
    bash -x /reduce_mkl_size.sh && \
    rm -rf /var/lib/apt/lists/*

#env
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && locale-gen zh_CN.utf8
ENV LC_ALL zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV DESKTOP_SESSION plasma
ENV KDE_FULL_SESSION=true
ENV SHELL=/bin/bash
ENV XDG_RUNTIME_DIR=/run/gemfield

ENV PATH_PREFIX=/ \
    VNC_RESIZE=scale \
    RECON_DELAY=250 \
    PAGE_TITLE="MLab HomePod"

ENV DISPLAY=:0 \
    SCR_WIDTH=1920 \
    SCR_HEIGHT=1080

ENV GTK_IM_MODULE=ibus \
    QT_IM_MODULE=ibus \
    XMODIFIERS=@im=ibus

## USER
ENV PGID=1000 \
    PUID=1000 \
    HOME=/home/gemfield \
    DEEPVAC_USER=gemfield

#im
RUN ibus-daemon -r -d -x

#conda
RUN curl -o /.gemfield_install/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /.gemfield_install/miniconda.sh && \
    /.gemfield_install/miniconda.sh -b -p /opt/conda && \
    rm /.gemfield_install/miniconda.sh && \
    /opt/conda/bin/conda install -y python=$PYTHON_VERSION conda-build anaconda-client numpy pyyaml scipy ipython mkl mkl-include \
        cffi ninja setuptools typing_extensions future six requests dataclasses cython typing conda-package-handling=${CONDA_PKG_HANDLE_VER} && \
    /opt/conda/bin/conda install -c pytorch magma-cuda${MAGMA_CUDA_VER} &&  \
    /opt/conda/bin/pip3 install --no-cache-dir Pillow opencv-python easydict sklearn matplotlib tensorboard fonttools \
        onnx onnxruntime onnx-coreml coremltools onnx-simplifier \
        requests protobuf && \
    /opt/conda/bin/conda clean -ya && \
    /opt/conda/bin/conda clean -y --force-pkgs-dirs

ENV PATH /opt/conda/bin:$PATH
RUN conda config --add channels pytorch
RUN ln -sf /opt/conda/bin/python3 /opt/conda/bin/python

#kde
COPY homepod_root /
COPY focal_root /
COPY deepvac.png /
COPY ibus-daemon.desktop /etc/xdg/autostart/

# libprotobuf
RUN git clone https://github.com/protocolbuffers/protobuf.git && \
    cd protobuf && \
    git checkout --recurse-submodules tags/v${PROTOBUF_VER} -b v${PROTOBUF_VER}-branch && \
    git submodule update --init --recursive && \
    bash -x ./autogen.sh && \
    ./configure && \
    make && make check && make install && \
    ldconfig && \
    cd .. && rm -rf protobuf

#pytorch
RUN conda install -c gemfield pytorch && \
    conda clean -ya && \
    /opt/conda/bin/conda clean -y --force-pkgs-dirs

#torchvision
RUN pip install --no-cache-dir --no-deps torchvision
