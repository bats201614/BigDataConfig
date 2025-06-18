# Hadoop 集群部署与配置
## 1. 下载Hadoop
- 从 Apache 官方网站下载稳定版本的 Hadoop 二进制包:{https://hadoop.apache.org/releases.html}
  - Windows下载：下载binary格式并上传至Linux中解压
  - Linux下载：在命令行中使用`wget`命令下载：
    ```bash
    wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz # 速度较慢
    ```

## 2. 解压到指定目录
- 通常解压到`/opt`或`/usr/local`目录下，也可以创建指定目录。
```bash
sudo su - hadoop #切换至专门用户，后续操作同理
tar -zxvf hadoop-3.4.1.tar.gz -C /opt/
mv /opt/hadoop-3.4.1 /opt/hadoop # 重命名为hadoop，方便管理
ln -s /opt/hadoop-3.4.1 /opt/hadoop # 或创建软链接
```

## 3. 修改权限
- 将 Hadoop 目录的所有权赋给运行 Hadoop 的用户。
```bash
sudo chown -R hadoop:hadoop /opt/hadoop
```

## 4. 配置Hadoop环境变量
- 编辑 /etc/profile 或用户 .bashrc：
```bash
# /etc/profile 或 ~/.bashrc，根据权限最小化原则推荐~/.bashrc
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

- 激活环境变量：
```bash
source ~/.bashrc  # 或 source /etc/profile
```

- 验证：
```bash
hadoop version
echo $HADOOP_HOME
```

## 5. 配置 Hadoop 核心文件
- **修改$HADOOP_HOME/etc/hadoop下的配置文件，主要包括**`workers`、`hadoop-env.sh`、`yarn-env.sh`、`mapred-env.sh`、`core-site.xml`、`hdfs-site.xml`、`yarn-site.xml`、`mapred-site.xml`，具体修改内容查看[配置文档](../config_files/)下的文件
- 修改完成后通过`scp`命令分发到所有从节点上：
```bash
# 假设用户为hadoop，节点为node2，hadoop目录为/opt/hadoop
scp -r /opt/hadoop/etc/hadoop/ hadoop@node2:/opt/hadoop/etc/hadoop/ # 修改主机以分发到后续节点

# 下述命令用于后续修改文件后同步，只会同步修改的文件，更轻量化
rsync -avz /opt/hadoop/etc/hadoop/ hadoop@node3:/opt/hadoop/etc/hadoop/  
```

## 6. 启动Hadoop
- 格式化 HDFS NameNode（**仅在首次部署或重建集群时执行此操作。此操作会删除 HDFS 中的所有数据！**）：
```bash
hdfs namenode -format # 成功后会看到successfully formatted字样。
```

- 启动 HDFS 服务（主节点）：
```bash
start-dfs.sh # 启动 NameNode 和所有 DataNode。
```

- 验证：
  - 使用`jps`命令在主节点上查看是否有`NameNode`和`SecondaryNameNode`进程。
  - 在从节点上查看是否有`DataNode`进程。
  - 访问 NameNode Web UI：`http://hadoop-master:9870`（或你的 NameNode IP:9870）,检查 DataNodes 列表是否显示所有从节点。
- 启动 YARN 服务（主节点）：
```bash
start-yarn.sh # 启动 ResourceManager 和所有 NodeManager。
```

- 验证：
  - 使用`jps`命令在主节点上查看是否有`ResourceManager`进程。
  - 在从节点上查看是否有`NodeManager`进程。
  - 访问 ResourceManager Web UI：`http://hadoop-master:8088`（或你的 ResourceManager IP:8088）,检查 Clusters 页面是否显示正确的 NodeManager 数量。

> 注意：可使用`start-all.sh`启动HDFS与YARN服务，不推荐使用

- 运行 Hadoop 示例程序（主节点）：
```bash
hdfs dfs -mkdir /input
hdfs dfs -put $HADOOP_HOME/etc/hadoop/*.xml /input/ # 上传一个文本文件到 HDFS
hdfs dfs -ls /input

# 运行 WordCount 示例
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /input /output

# 查看 HDFS 上的输出文件
hdfs dfs -ls /output
hdfs dfs -cat /output/part-r-00000
```
- 可访问 JobHistoryServer Web UI：`http://hadoop-master:19888`，查看 MapReduce 作业的历史记录。
- 停止 Hadoop 服务（主节点）：
```bash
stop-dfs.sh
stop-yarn.sh .

# 使用 jps 命令检查相关进程是否已停止。
jps
```
> 可选：通常在主节点处运行`mapred --daemon start historyserver`以启用JobHistoryServer（MapReduce 的一个重要组件，它负责收集、存储和展示已完成 MapReduce 作业的历史信息）