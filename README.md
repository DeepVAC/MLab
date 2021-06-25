# MLab
“云上炼丹师”中的云。

# MLab构成
MLab是为云上炼丹师服务的云基础设施。由两个部分组成：
- MLab HomePod，迄今为止最先进的容器化PyTorch训练环境。
- MLab RookPod，迄今为止最先进的成本10万人民币以下存储解决方案。

以上两个MLab组件均为独立的产品，可以单独使用docker进行部署，也可以使用k8s进行部署。其宿主机OS基于Ubuntu Server LTS发行版（20.04）。

# MLab HomePod
**迄今为止最先进的容器化PyTorch训练环境。**

目前只支持X86 + Linux。具体来说，支持如下的软硬件平台：
- X86 + Linux
- X86 + CUDA + Linux

因为MLab HomePod的首要目标是提供PyTorch模型训练环境，而MLab HomePod基于docker，因此，对于不支持PyTorch训练或者docker的软硬件平台，MLab HomePod不会去进行适配。

MLab HomePod以Docker image形式封装，是我们的深度学习训练环境。目前最新版本为2.0，分为标准版和pro版本。规格如下：

|参数项             |MLab HomePod 2.0      |MLab HomePod 2.0 pro      |
|-------------------|----------------------|--------------------------|
|镜像               |gemfield/homepod:2.0  |gemfield/homepod:2.0-pro  |
|OS                 |Ubuntu 20.04          |Ubuntu 20.04              |
|PyTorch            |1.9.0                 |1.9.0                     |
|PyTorch CUDA运行时 |11.1                  |11.1                      |
|PyTorch CUDNN运行时|8.0.5                 |8.0.5                     |
|torchvision        |0.10.0                |0.10.0                    |
|torchaudio         |0.9.0a0+33b2469       |0.9.0a0+33b2469           |
|torchtext          |0.10.0                |0.10.0                    |
|Conda              |4.10.1                |4.10.1                    |
|Python             |3.8.8                 |3.8.8                     |
|numpy              |1.20.2                |1.20.2                    |
|cv2                |4.5.2                 |4.5.2                     |
|onnx               |1.8.1                 |1.8.1                     |
|g++                |9.3.0                 |9.3.0                     |
|cmake              |3.16.3                |3.16.3                    |
|KDE Plasma         |5.22.1                |5.22.1                    |
|KDE Framework      |5.83.0                |5.83.0                    |
|时区               |中国                  |中国                      |
|protobuf-dev       |3.6.1.3               |3.6.1.3                   |
|protobuf python包  |3.17.3                |3.17.3                    |
|pybind11-dev       |2.4.3                 |2.4.3                     |
|xrdp               |0.9.12                |0.9.12                    |
|tigervnc           |1.10.1                |1.10.1                    |
|VS CODE IDE        |1.57.1                |1.57.1                    |
|Firefox            |89.0.1                |89.0.1                    |
|中文输入法         |IBus sunpinyin 2.0.3  |IBus sunpinyin 2.0.3      |
|coremltools        |4.1                   |4.1                       |
|NCNN转换工具       |20210525              |20210525                  |
|TNN转换工具        |0.3.0                 |0.3.0                     |
|MNN转换工具        |1.2.0                 |1.2.0                     |
|tensorrt(转换工具) |无                    |8.0.0.3                   |
|libboost-dev       |无                    |1.71.0                    |
|CUDA开发库         |无                    |11.3.1                    |
|MKL静态库          |无                    |2020.4-912                |
|pycuda包           |无                    |2020.1                    |

除了这些核心软件，MLab HomePod还有如下鲜明特色：
- 无缝使用DeepVAC规范；
- 无缝构建和测试libdeepvac；
- 包含有kdiff3、kompare、kdenlive、Dolphin、Kate、Gwenview、Konsole等诸多工具。

另外，标准版和pro版内容完全一致，除了pro版本增加了如下内容：
- tensorrt python包，可以用来将PyTorch模型转换为TensorRT模型；
- libboost-dev，用于C++开发者；
- CUDA开发库，用于基于cuda的开发，或者pytorch的源码编译；
- MKL静态库，用于基于mkl的开发，或者libtorch的静态编译；
- pycuda python包，用于运行TensorRT模型。

为了支持上述功能，pro版本的镜像足足增加了10个GB。也正是因为此，homepod从2.0版本开始拆分成了标准版和pro版。

## 1. 部署
MLab HomePod有三种部署方式：
1. 纯粹的Docker命令行方式，部署且运行后只能在命令行里工作。
```bash
#有cuda设备
docker run --gpus all -it --entrypoint=/bin/bash gemfield/homepod:2.0
#没有cuda设备
docker run -it --entrypoint=/bin/bash gemfield/homepod:2.0
```

2. 图形化的Docker部署方式，部署后可以在vnc客户端、rdp客户端、浏览器中访问图形界面。
```bash
#有cuda设备
docker run --gpus all -it -eGEMFIELD_MODE=VNCRDP -p 3389:3389 -p 7030:7030 -p 5900:5900 -p 20022:22 gemfield/homepod:2.0
#没有cuda设备
docker run -it -eGEMFIELD_MODE=VNCRDP -p 3389:3389 -p 7030:7030 -p 5900:5900 -p 20022:22 gemfield/homepod:2.0
```
参数中的端口号用途：
|端口号 | 协议 | 用途 |
|-------|------|------|
|3389   |rdp   |用于rdp客户端，Windows远程桌面连接客户端|
|5900   |vnc   |用于vnc客户端|
|7030   |http  |用于浏览器|
|20022  |ssh   |用于ssh客户端、sftp客户端、KDE Dolphin等|


3. k8s集群部署方式（需要k8s集群运维经验，适合团队的协作管理）。请访问[基于k8s部署HomePod](./docs/k8s_usage.md)以获得更多部署信息。

## 2. 登录
三种部署方式中的第一种无需赘述，使用```docker exec -it```登录即可。后两种部署成功后使用图形界面进行登录和使用。支持如下使用方式：
- 1，浏览器(http://your_host:7030);
- 2，vnc客户端，比如realvnc客户端：https://www.realvnc.com/en/connect/download/viewer/ 。realvnc公司承诺viewer永远免费使用。
- 3，rdp客户端，比如KRDC、remmina、Windows远程桌面等。

## 3. 账户信息
MLab HomePod默认提供了如下账户：
- 用户:gemfield
- 密码:deepvac
- HOME:/home/gemfield

如果要改变该默认行为，可以在docker命令行上（或者k8s yaml中）注入以下环境变量：
- DEEPVAC_USER=<my_name>
- DEEPVAC_PASSWORD=<my_password>
- HOME=<my_home_path>

## 4. 账户安全
为了安全，用户在初始登录MLab HomePod后，最好使用```passwd```命令来修改账户密码。并在日常使用中，做到离开电脑5分钟以上手工锁定屏幕（KDE -> Leave -> Lock(Lock screen)）。


# MLab RookPod
迄今为止最先进的成本10万人民币以下存储解决方案。
（待补充）
