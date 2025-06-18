# 前置全局配置
## **1**. **前置条件**
- ### **网络要求**
  - 同一网段静态 ip 配置
  - 配置 ssh 免密登录使得所有节点可以互相连接
- ### **操作系统**
  - 关闭防火墙或配置必要端口开放
  - 禁用 SELinux
  - 所有节点的`/etc/host`文件配置好所有集群节点的主机名和 IP 地址映射
  - 创建一个专门的用户（如`hadoop`用户）来运行 Hadoop 服务，并赋予必要的权限。如：
  ```bash
  sudo adduser hadoop
  # 赋予sudo权限（可选,在生产环境中，建议根据最小权限原则细化权限）

  # 将 hadoop 用户添加到 sudo 组 (Ubuntu/Debian)
  sudo usermod -aG sudo hadoop
  # 或者编辑 /etc/sudoers 文件 (推荐使用 visudo 命令)
  sudo visudo
  # 找到 %wheel ALL=(ALL) ALL (或 root ALL=(ALL) ALL)
  # 在其下方添加一行：
  hadoop  ALL=(ALL)       ALL
  hadoop  ALL=(ALL:ALL) NOPASSWD: ALL #无需密码切换登录，不建议配置
  ```
- ### **环境依赖**
    - 安装Java Development Kit（JDK）并配置JAVA_HOME和PATH环境变量（注意Hadoop与JDK的版本要求一致）

## **2. 具体步骤**

### **2.1. 更新系统并安装常用工具：**
```bash
sudo apt update
sudo apt install -y wget vim net-tools
```

### **2.2 禁用防火墙（或开放端口）：**
```bash
# CentOS/RHEL
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Ubuntu/Debian
sudo ufw disable
```

### **2.3. 禁用 SELinux (CentOS/RHEL)：**
```bash
# 临时禁用
sudo setenforce 0
# 永久禁用
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

### **2.4. 配置主机名与ip地址：**

#### 2.4.1. 配置主机名
```bash
# 每个节点设置其唯一的主机名（例如 hadoop-master, hadoop-slave1, hadoop-slave2）
sudo hostname # 查看当前主机名
sudo hostnamectl set-hostname hadoop-master # 配置主机名
```

#### 2.4.2. 配置静态 IP 地址
- （所有节点，以 VirtualBox NAT + Host-Only 模式为例）（*此步骤旨在为虚拟机配置稳定的网络环境，使其既能访问外网（NAT），又能与宿主机及其他虚拟机在私有网络中通信（Host-Only）。*）

- **虚拟机设置**
  - **网卡 1 (NAT)**: 连接方式选择 NAT。此网卡用于虚拟机访问外部网络（如下载软件包）
  - **网卡 2 (Host-Only Adapter)**: 连接方式选择`Host-Only Adapter`，选择一个已创建或新建的`VirtualBox Host-Only Ethernet Adapter`。这个网卡用于虚拟机之间的内部通信以及宿主机访问虚拟机。

- **查看网卡信息**
  - 登录虚拟机，使用`ifconfig`命令查看网络接口名称。通常 NAT 网卡可能是 enp0s3，Host-Only 网卡可能是 enp0s8，并记录下你的 Host-Only 网卡名称（例如`enp0s8`）。

- **配置 Host-Only 网卡静态 IP：**
  - **CentOS/RHEL ：** 找到 Host-Only 网卡的配置文件，通常在`/etc/sysconfig/network-scripts/ifcfg-enp0s8` (以 `enp0s8` 为例)。
  ```bash
    sudo vim /etc/sysconfig/network-scripts/ifcfg-enp0s8
    
    # 修改或创建以下内容
    TYPE=Ethernet
    PROXY_METHOD=none
    BROWSER_ONLY=no
    BOOTPROTO=static        # 设置为静态IP
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=yes
    IPV6_AUTOCONF=yes
    IPV6_DEFROUTE=yes
    IPV6_FAILURE_FATAL=no
    IPV6_ADDR_GEN_MODE=stable-privacy
    NAME=enp0s8             # 你的Host-Only网卡名称
    UUID=<Your_UUID>        # 保持原有的UUID不变
    DEVICE=enp0s8           # 你的Host-Only网卡名称
    ONBOOT=yes              # 开机启动

    IPADDR=192.168.56.100   # 为Master节点分配的静态IP
    NETMASK=255.255.255.0
    # GATEWAY一般设置为Host-Only网段的宿主机IP（通常是192.168.56.1）
    GATEWAY=192.168.56.1
    DNS1=8.8.8.8            # DNS 服务器，用于解析域名
  ```

  - 按照同样的步骤为slave节点配置静态ip（要与master节点在同一网段下）如:`hadoop-slave1: IPADDR=192.168.56.101`

  - **Ubuntu/Debian (使用 netplan):** 编辑`/etc/netplan/01-netcfg.yaml`(或类似名称的文件)。
  ```bash
  sudo vim /etc/netplan/01-netcfg.yam

  # 修改内容
  network:
  version: 2
  renderer: networkd
  ethernets:
      enp0s3: # NAT 网卡，通常保留 DHCP
      dhcp4: true
      enp0s8: # Host-Only 网卡
      dhcp4: no
      addresses: [192.168.56.100/24] # Master 节点的 IP 地址和子网掩码
      nameservers:
          addresses: [8.8.8.8, 8.8.4.4] # DNS 服务器
      # routes: # 如果需要设置路由
      #   - to: default
      via: 192.168.56.1 # 网关通常是Host-Only网段的宿主机IP
  ```
  - 按照同样的步骤为slave节点配置静态ip（要与master节点在同一网段下）
  - 应用Netplan配置：`sudo netplan apply`

- **重启网络服务或虚拟机：**
  - **CentOS/RHEL：**
`sudo systemctl restart network`
  - **Ubuntu/Debian：**
`sudo systemctl restart systemd-networkd`

- **验证静态 IP：**
`ifconfig`

- 确保所有虚拟机之间可以相互 ping 通，并且宿主机也可以 ping 通虚拟机：在`hadoop-master`上`ping hadoop-slave1`(`ping 192.168.56.101`)。在宿主机上`ping hadoop-master`(`ping 192.168.56.100`)。

### **2.5. 配置`/etc/hosts`文件：**

- 在所有节点上，编辑`/etc/hosts`文件，添加所有集群节点的 IP 地址和主机名映射。
```bash
# /etc/hosts 示例
192.168.56.100 hadoop-master
192.168.56.101 hadoop-slave1
192.168.56.102 hadoop-slave2
```
- 验证：`ping hadoop-slave1`

### **2.6. 配置 SSH 免密登录：**
- 在主节点生成 SSH 密钥对（如果已有，跳过此步）:
```bash
ssh-keygen -t ed25519 # 推荐
ssh-keygen -t rsa -P 4096 -f ~/.ssh/id_rsa
```

- 将公钥分发到主节点自身和其他节点：
```bash
ssh-copy-id hadoop-master # 主节点到自身
ssh-copy-id hadoop-slave1
ssh-copy-id hadoop-slave2
```
- 验证：`ssh hadoop-master`、`ssh hadoop-slave1`等，无需密码即可登录。

### **2.7. 安装 JDK：**
```bash
# CentOS/RHEL (OpenJDK 8)
sudo yum install -y java-1.8.0-openjdk-devel
# Ubuntu/Debian (OpenJDK 11)
sudo apt install -y openjdk-11-jdk #版本自行选择
```

- 查看JDK版本：{https://www.java.com/}
- 配置 JAVA_HOME 环境变量：通常在`/etc/profile`或用户的主目录下的`.bashrc`文件中配置。
```bash
# /etc/profile 或 ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/jdk_21 # 实际路径可能不同，请根据你的安装路径修改
export PATH=$PATH:$JAVA_HOME/bin
```
- 激活环境变量：`source /etc/profile`或 `source ~/.bashrc`
- 验证：`java -version`、`javac -version`和`echo $JAVA_HOME`