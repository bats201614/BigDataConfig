# ZooKeeper 部署与配置
## 1. 下载 ZooKeeper
- 从 Apache 官方网站下载稳定版本的 ZooKeeper 二进制包:{https://zookeeper.apache.org/releases.html}
  - Windows下载：下载 tgz 文件并上传至Linux中解压
  - Linux下载：在命令行中使用`wget`命令下载：
    ```bash
    wget https://dlcdn.apache.org/zookeeper/zookeeper-3.9.3/apache-zookeeper-3.9.3-bin.tar.gz # 示例URL，请替换为最新稳定版，速度较慢
    ```

## 2. 解压到指定目录
- 通常解压到`/opt`或`/usr/local`目录下，也可以创建指定目录。
```bash
sudo su - zookeeper #切换至专门用户，后续操作同理
tar -zxvf apache-zookeeper-3.9.3-bin.tar.gz -C /opt/
mv /opt/apache-zookeeper-3.9.3-bin /opt/zookeeper # 重命名为spark，方便管理
ln -s /opt/apache-zookeeper-3.9.3-bin /opt/zookeeper # 或创建软链接
```

## 3. 修改权限
- 将 ZooKeeper 目录的所有权赋给运行 ZooKeeper 的用户。
```bash
sudo chown -R zookeeper:zookeeper /opt/zookeeper
```

## 4. 配置 ZooKeeper 环境变量
- 编辑 /etc/profile 或用户 .bashrc：
```bash
# /etc/profile 或 ~/.bashrc，根据权限最小化原则推荐~/.bashrc
export ZOOKEEPER_HOME=/opt/zookeeper
export PATH=$PATH:$ZOOKEEPER_HOME/bin
```

- 激活环境变量：
```bash
source ~/.bashrc  # 或 source /etc/profile
```

- 验证：
```bash
zkServer.sh status # 此时会报错，因为还未配置
echo $ZOOKEEPER_HOME
```

## 5. 配置 ZooKeeper 核心文件
- **修改 $ZOOKEEPER_HOME/conf/ 下的配置文件，主要包括**`zoo.cfg`和`myid`，具体修改内容查看[配置文档](../config_files/)下的文件
> 注意需要复制或创建 zoo.cfg 和 myid 文件。
- 修改完成后通过`scp`命令分发到所有从节点上：
```bash
# 假设用户为zookeeper，节点为node2，zookeeper目录为/opt/zookeeper
# 假设用户为zookeeper，节点为node2
scp /opt/zookeeper/conf/zoo.cfg zookeeper@node2:/opt/zookeeper/conf/ # 修改主机以分发到后续节点，myid 文件不要同步，因为每个节点的 myid 是唯一的。

# 下述命令用于后续修改文件后同步，只会同步修改的文件，更轻量化
rsync -avz /opt/zookeeper/conf/zoo.cfg zookeeper@node2:/opt/zookeeper/conf/
```

## 6. 启动 ZooKeeper
- 启动 ZooKeeper 服务：
```bash
/opt/zookeeper/bin/zkServer.sh start
```

- 检查 ZooKeeper 状态：
```bash
/opt/zookeeper/bin/zkServer.sh status # 在每个节点上执行 status 命令，检查其角色（Leader 或 Follower），确保集群中有一个 Leader 和其他 Follower
```

- 设置为开机自启 (可选)：创建一个 Systemd 服务文件 (例如 /etc/systemd/system/zookeeper.service)：
```Ini, TOML
[Unit]
Description=Zookeeper Daemon
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=forking
User=zookeeper
Group=zookeeper
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
ExecReload=/opt/zookeeper/bin/zkServer.sh restart
WorkingDirectory=/opt/zookeeper
Restart=always
LimitNOFILE=65535 # 提高文件句柄限制，避免 Too many open files 错误

[Install]
WantedBy=multi-user.target
```

- 重新加载 Systemd 配置并启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable zookeeper.service
sudo systemctl start zookeeper.service # 启动服务
sudo systemctl status zookeeper.service # 检查服务状态
```

## 7. 验证
- 检查 ZooKeeper 服务状态，在所有 ZooKeeper 节点上运行 zkServer.sh status，确保每个节点都显示为 Mode: leader 或 Mode: follower，确保整个集群中只有一个 Leader。
- 在任意节点上，使用 ZooKeeper 客户端工具连接到集群。
```bash
/opt/zookeeper/bin/zkCli.sh -server node1:2181,node2:2181,node3:2181
```

- 成功连接后，你将看到客户端提示符。可以尝试执行一些命令，如：`ls /`：列出根目录下的节点；`get /test`：获取 ZNode 的数据；`quit`：退出客户端等。如果这些操作成功，则表明 ZooKeeper 集群已正常工作。