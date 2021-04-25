# MLab
“云上炼丹师”中的云。

# MLab构成
MLab是为云上炼丹师服务的云基础设施。由以下部分组成：
- 最小CPU硬件：x86-64 CPU / 128G RAM / 512G SSD * 2 / 10GbE NIC / 8T HDD * 8
- 最小CUDA硬件：x86-64 CPU / 128G RAM / 512G SSD / 10GbE NIC /CUDA * 1
- 操作系统：Ubuntu 20.04 Server发行版（安装Nvidia最新驱动）
- K8s集群
- Ceph存储
- MLab HomePod

# MLab HomePod
迄今为止最先进的容器化PyTorch训练环境。  
MLab HomePod以Docker image形式封装，是我们的深度学习训练环境。  HomePod有着鲜明的特点：
- 基于最新的Ubuntu LTS(20.04)；
- 基于最新的KDE Plasma(5.21.4);
- 基于最新的KDE Framework(5.82.0);
- 使用中国时区；
- 使用最新版本的PyTorch(1.8.1+)；
- 使用最新版本的Conda(4.9.2)；
- 使用比较新版本的CUDA(11.0.3)；
- 使用比较新版本的MKL(2020.4.304)；
- 使用最新版本的VS Code IDE(1.55)；
- 使用最新版本的Firefox浏览器(87.0)；
- 使用IBus sunpinyin中文输入法(1.5.22);
- 无缝使用Deepvac规范；
- 无缝构建和测试libdeepvac；
- 包含有kdiff3、kompare、kdenlive、Dolphin、Kate、Gwenview、Konsole等诸多工具。

## 1. 部署
MLab HomePod有三种部署方式：
- 纯粹的Docker命令行方式，部署且运行后只能在命令行里工作。
```bash
docker run --gpus all -it --entrypoint=/bin/bash gemfield/homepod:1.1
```

- 图形化的Docker部署方式，部署后可以在vnc客户端和浏览器中访问图形界面。
```bash
docker run --gpus all -it -p 7030:7030 -p 5900:5900 gemfield/homepod:1.1
```

- k8s集群部署方式（需要k8s集群运维经验，适合小团队的协作管理）。  
请访问[基于k8s部署HomePod](./docs/k8s_usage.md)以获得更多注意事项。

## 2. 登录
三种部署方式中的第一种无需赘述，后两种部署成功后使用图形界面进行登录和使用。支持两种使用方式：
- 1，浏览器(http://your_host:7030);
- 2，realvnc客户端：https://www.realvnc.com/en/connect/download/viewer/ 。realvnc公司承诺viewer永远免费使用。

其中，浏览器方式的优点是方便；VNC客户端方式的优点是流畅，且功能更多。

## 3. 密码与登出
HomePod默认提供了用户:gemfield，初始密码:gemfield。  

如果要改变该默认行为，请在docker命令行上（或者k8s yaml中）注入以下环境变量：
- DEEPVAC_USER=your_name
- DEEPVAC_PASSWORD=your_password
- HOME=/home/your_name

为了安全，用户在初始登录HomePod后，需要：
- 修改自己的用户密码；
- 使用sudo命令修改root用户的密码；
- 公司和家庭以外环境使用HomePod需要提前报备；
- 离开电脑5分钟以上，需要手工锁定屏幕（KDE -> Leave -> Lock(Lock screen)）。

## 4. 文件权限问题解决
在HomePod中工作的时候，默认都在自己的用户下工作。如果遇到历史遗留文件的权限问题，那么可以使用sudo命令(1.1版本及以后)：
- 如果该文件是自己所有，则使用chown命令将文件的owner更改为自己；
- 如果该文件是公共所有，则使用chmod命令将文件的read权限为所有人打开。

