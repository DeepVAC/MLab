# MLab
“云上炼丹师”中的云

# MLab构成
MLab是为云上炼丹师服务的云基础设施。由以下部分组成：
- 最小CPU硬件：x86-64 CPU / 128G RAM / 512G SSD * 2 / 10GbE NIC / 8T HDD * 8
- 最小CUDA硬件：x86-64 CPU / 128G RAM / 512G SSD / 10GbE NIC /CUDA * 1
- 操作系统：Ubuntu 20.04 Server发行版（安装Nvidia最新驱动）
- K8s集群
- Ceph存储
- MLab HomePod

# MLab HomePod
MLab HomePod是我们的深度学习训练环境，以Docker image形式封装。目前我们开源了HomePod for PyTorch。

## 1. 部署
```bash
#docker方式
docker run -it -p 7030:7030 -p 5900:5900 gemfield/deepvac:vision-11.0.3-cudnn8-devel-ubuntu20.04-vnc
```
当然更适合在K8s中部署HomePod:
```bash
#在你修改HomePod/homepod.yaml后
kubectl apply -f HomePod/homepod.yaml
```

## 2. 登录
支持两种方式访问：
- 1，浏览器(http://your_host:7030);
- 2，VNC客户端(KDE Linux用户直接使用自带的KRDC客户端，其它系统自行下载vnc客户端)。

其中，浏览器方式的优点是方便；VNC客户端方式的优点是流畅，且功能更多。

## 3. 权限问题解决
在HomePod中工作的时候，默认都在自己的用户下工作。如果遇到历史遗留文件的权限问题，那么切换为root用户：
- 如果该文件是自己所有，则使用chown命令将文件的owner更改为自己；
- 如果该文件是公共所有，则使用chmod命令将文件的read权限为所有人打开。

完成权限的更改后，再通过exit命令从root用户退回到自己的用户。注意：**不能在root会话中新建会话！！！**。