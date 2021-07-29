FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04
maintainer "Gemfield <gemfield@civilnet.cn>"

#uncomment it in mainland china 
#RUN rm -f /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/nvidia-ml.list
ENV DEBIAN_FRONTEND=noninteractive

#forward compat feature not supported by non-tesla devices.
RUN apt purge -y cuda-compat-11-2

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

#args
EXPOSE 5900
EXPOSE 7030
EXPOSE 3389
ARG MKL_VER="2020.4-912"

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
ARG PYTHON_VERSION="3.8"
RUN curl -o /.gemfield_install/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /.gemfield_install/miniconda.sh && \
    /.gemfield_install/miniconda.sh -b -p /opt/conda && \
    rm /.gemfield_install/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} conda-build anaconda-client astunparse numpy pyyaml scipy ipython mkl mkl-include \
        cffi ninja setuptools typing_extensions future six requests dataclasses cython typing && \
    /opt/conda/bin/conda clean -ya && \
    /opt/conda/bin/conda clean -y --force-pkgs-dirs

ENV PATH /opt/conda/bin:$PATH
RUN conda config --add channels pytorch && \
    conda config --add channels nvidia && \
    ln -sf /opt/conda/bin/python3 /opt/conda/bin/python

#basic python package
RUN /opt/conda/bin/pip3 install --no-cache-dir Pillow opencv-python easydict sklearn matplotlib tensorboard fonttools \
        onnx==1.8.1 onnxruntime onnx-coreml coremltools onnx-simplifier pycocotools requests protobuf && \
    conda clean -ya && \
    conda clean -y --force-pkgs-dirs

#pytorch
#note: homepod pro version will install pytorch from gemfield channel
RUN conda install -y magma-cuda111 pytorch torchvision torchaudio torchtext cudatoolkit=11.1 -c pytorch -c nvidia && \
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

#forward framework
WORKDIR /.gemfield_install
ARG TNN_VER="0.3.0"
ARG MNN_VER="1.2.0"
ARG NCNN_VER="20210525"
ARG PYTHON_SO_VER="38"

#tnn
RUN git clone https://github.com/Tencent/TNN.git && cd TNN && \
    git checkout --recurse-submodules tags/v${TNN_VER} -b v${TNN_VER}-branch && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DTNN_CONVERTER_ENABLE=ON -DTNN_ONNX2TNN_ENABLE=ON .. && make VERBOSE=1 && \
    cp /.gemfield_install/TNN/build/tools/onnx2tnn/onnx-converter/onnx2tnn.cpython-${PYTHON_SO_VER}-x86_64-linux-gnu.so /opt/conda/lib/python${PYTHON_VERSION}/site-packages/ && \
    cp /.gemfield_install/TNN/build/libTNN.so /lib/ && ln -s /lib/libTNN.so /lib/libTNN.so.0 && \
    cd ../.. && rm -rf TNN
#ncnn
RUN git clone https://github.com/Tencent/ncnn.git && cd ncnn && \
    git checkout --recurse-submodules tags/${NCNN_VER} -b v${NCNN_VER}-branch && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DNCNN_BUILD_EXAMPLES=OFF -DNCNN_BUILD_BENCHMARK=OFF -DNCNN_BUILD_TOOLS=ON .. && make VERBOSE=1 && \
    cp /.gemfield_install/ncnn/build/tools/onnx/onnx2ncnn /bin/ && \
    cd ../.. && rm -rf ncnn
#mnn
RUN git clone https://github.com/alibaba/MNN.git && cd MNN && \
    git checkout --recurse-submodules tags/${MNN_VER} -b v${MNN_VER}-branch && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DMNN_BUILD_CONVERTER=ON .. && make VERBOSE=1 && \
    cp /.gemfield_install/MNN/build/MNNConvert /bin/ && \
    cp /.gemfield_install/MNN/build/libMNN.so /lib/ && \
    cp /.gemfield_install/MNN/build/tools/converter/libMNNConvertDeps.so /lib/ && \
    cp /.gemfield_install/MNN/build/express/libMNN_Express.so /lib/ && \
    cd ../.. && rm -rf MNN

#tensorrt
RUN curl -L https://github.com/DeepVAC/libdeepvac/releases/download/1.9.0/tensorrt.tar.gz -o tensorrt.tar.gz && \
    tar -zxf tensorrt.tar.gz && /opt/conda/bin/pip3 install tensorrt/python/tensorrt-8.0.0.3-cp38-none-linux_x86_64.whl && \
    cp tensorrt/lib/* /lib/ && cp tensorrt/include/* /usr/include/ && rm -rf tensorrt && rm tensorrt.tar.gz && \
    /opt/conda/bin/pip3 install --no-cache-dir 'pycuda<2021.1' && \
    conda clean -ya && \
    conda clean -y --force-pkgs-dirs

#gemfield channel
RUN mkdir -p /opt/gemfield && \ 
    conda install -y --no-deps -p /.gemfield_install/ pytorch -c gemfield && \
    mv /.gemfield_install/lib/python3.8/site-packages/torch /opt/gemfield/ && \
    mv /.gemfield_install/lib/python3.8/site-packages/caffe2/ /opt/gemfield/ && \
    conda clean -ya && \
    conda clean -y --force-pkgs-dirs && \
    rm -rf /.gemfield_install/* 
    
RUN cd /opt/gemfield && \
    curl -L https://github.com/DeepVAC/libdeepvac/releases/download/1.9.0/opencv4deepvac.tar.gz -o opencv4deepvac.tar.gz && \
    curl -L https://github.com/DeepVAC/libdeepvac/releases/download/1.9.0/libtorch.tar.gz -o libtorch.tar.gz && \
    tar zxvf opencv4deepvac.tar.gz && tar zxvf libtorch.tar.gz && \
    rm -f opencv4deepvac.tar.gz libtorch.tar.gz
RUN cd /opt/gemfield && \
    git clone https://github.com/deepVAC/deepvac && \
    git clone https://github.com/DeepVAC/libdeepvac

