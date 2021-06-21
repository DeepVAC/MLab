FROM nvidia/cuda:11.0.3-cudnn8-devel-ubuntu20.04
maintainer "Gemfield <gemfield@civilnet.cn>"

#uncomment it in mainland china 
#RUN rm -f /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/nvidia-ml.list
ENV DEBIAN_FRONTEND=noninteractive
#base
RUN apt update && \
    apt dist-upgrade -y && \
    apt install -y ubuntu-minimal ubuntu-standard && \
    apt purge -y command-not-found && \
    apt update && \
    mkdir /.gemfield_install && \
    apt install -y --no-install-recommends build-essential \
        vim wget curl bzip2 git autoconf automake libtool make unzip g++ binutils cmake locales \
        ca-certificates apt-transport-https gnupg gnupg2 software-properties-common \
        libjpeg-dev libpng-dev iputils-ping net-tools libgl1 libglib2.0-0 tree \
        nginx gettext-base ibus-sunpinyin pybind11-dev libssl-dev libprotobuf-dev protobuf-compiler && \
    wget --no-check-certificate -q http://archive.neon.kde.org/public.key -O- | apt-key add - && \
    add-apt-repository -y http://archive.neon.kde.org/user && \
    apt update && \
    apt install -y neon-desktop plasma-workspace-wayland kwin-wayland kwin-wayland-backend-wayland kwin-x11 && \
    apt install -y xrdp supervisor supervisor-doc && \
    apt dist-upgrade -y && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

#args
EXPOSE 5900
EXPOSE 7030
EXPOSE 3389
ARG PYTHON_VERSION=3.8
ARG MKL_VER="2020.4-912"
ARG PROTOBUF_VER="3.15.8"
ARG CONDA_PKG_HANDLE_VER="1.6.0"
ARG MAGMA_CUDA_VER="110"

#vnc & boost & kde app
RUN apt update && \
    apt install -y tigervnc-standalone-server tigervnc-xorg-extension \
        openssh-server \
        libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev \
        okular kdiff3 kompare gwenview && \
    apt clean && \
    service ssh restart && \
    rm -rf /var/lib/apt/lists/*

#kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/kubectl

#dbus
RUN mkdir -p /var/run/dbus
RUN chown messagebus:messagebus /var/run/dbus
RUN dbus-uuidgen --ensure

#locale
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && locale-gen zh_CN.utf8
ENV LC_ALL zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8

#code & mkl
COPY homepod_root /
RUN wget -q https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB -O- | apt-key add - && \
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    wget -q https://dl-ssl.google.com/linux/linux_signing_key.pub -O- | apt-key add - && \
    echo "deb https://apt.repos.intel.com/mkl all main" > /etc/apt/sources.list.d/intel-mkl.list && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/gemfield-vs.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt update && \
    apt install -y intel-mkl-64bit-${MKL_VER} code && \
    apt dist-upgrade -y && \
    apt autoremove -y && \
    apt clean && \
    bash -x /reduce_mkl_size.sh && \
    rm -rf /var/lib/apt/lists/*

#user
ENV PGID=1000 \
    PUID=1000 \
    HOME=/home/gemfield \
    DEEPVAC_USER=gemfield \
    DEEPVAC_PASSWORD=deepvac

#im
ENV GTK_IM_MODULE=ibus \
    QT_IM_MODULE=ibus \
    XMODIFIERS=@im=ibus
RUN ibus-daemon -r -d -x

#conda
RUN curl -o /.gemfield_install/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /.gemfield_install/miniconda.sh && \
    /.gemfield_install/miniconda.sh -b -p /opt/conda && \
    rm /.gemfield_install/miniconda.sh && \
    /opt/conda/bin/conda install -y python=$PYTHON_VERSION conda-build anaconda-client numpy pyyaml scipy ipython mkl mkl-include \
        cffi ninja setuptools typing_extensions future six requests dataclasses cython typing conda-package-handling=${CONDA_PKG_HANDLE_VER} && \
    /opt/conda/bin/conda install -c pytorch magma-cuda${MAGMA_CUDA_VER} &&  \
    /opt/conda/bin/conda clean -ya && \
    /opt/conda/bin/conda clean -y --force-pkgs-dirs

ENV PATH /opt/conda/bin:$PATH
RUN conda config --add channels pytorch
RUN ln -sf /opt/conda/bin/python3 /opt/conda/bin/python

#basic python package
RUN /opt/conda/bin/pip3 install --no-cache-dir Pillow opencv-python easydict sklearn matplotlib tensorboard fonttools \
        onnx==1.8.1 onnxruntime onnx-coreml coremltools onnx-simplifier \
        requests protobuf && \
    conda clean -ya && \
    conda clean -y --force-pkgs-dirs

#torchvision
RUN /opt/conda/bin/pip3 install --no-cache-dir --no-deps torchvision && \
    conda clean -ya && \
    conda clean -y --force-pkgs-dirs

#user customize
#vnc env
ENV PATH_PREFIX=/ \
    VNC_RESIZE=scale \
    RECON_DELAY=250 \
    PAGE_TITLE="MLab HomePod"

ENV SCR_WIDTH=1920 \
    SCR_HEIGHT=1080

#kde env
ENV GEMFIELD_MODE=RDP
ENV GEMFIELD_VER=2.0
ENV DISPLAY=:0
ENV KDE_FULL_SESSION=true
ENV SHELL=/bin/bash
ENV XDG_RUNTIME_DIR=/run/gemfield
ENV MLAB_DNS="192.168.0.114   ai1.gemfield.org"
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
