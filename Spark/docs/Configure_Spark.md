# Spark 部署与配置
## 1. 下载 Spark
- 从 Apache 官方网站下载稳定版本的 Spark 二进制包，类型务必选择`Pre-built for Apache Hadoop 3.x and later`（预编译好支持 Hadoop 3.x 及更高版本的包，根据你安装的 Hadoop 版本选择）:{https://spark.apache.org/downloads.html}
  - Windows下载：下载 tgz 文件并上传至Linux中解压
  - Linux下载：在命令行中使用`wget`命令下载：
    ```bash
    wget https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.2.tgz # 示例URL，请替换为最新稳定版，速度较慢
    ```

## 2. 解压到指定目录
- 通常解压到`/opt`或`/usr/local`目录下，也可以创建指定目录。
```bash
sudo su - spark #切换至专门用户，后续操作同理
tar -zxvf spark-3.5.1-bin-hadoop3.2.tgz -C /opt/
mv /opt/spark-3.5.1-bin-hadoop3.2 /opt/spark # 重命名为spark，方便管理
ln -s /opt/spark-3.5.1-bin-hadoop3.2 /opt/spark # 或创建软链接
```

## 3. 修改权限
- 将 Spark 目录的所有权赋给运行 Spark 的用户。
```bash
sudo chown -R spark:spark /opt/spark
```

## 4. 配置 Spark 环境变量
- 编辑 /etc/profile 或用户 .bashrc：
```bash
# /etc/profile 或 ~/.bashrc，根据权限最小化原则推荐~/.bashrc
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# PySpark相关配置
export PYSPARK_PYTHON=/home/spark/venvs/pyspark_venv/bin/python3.9 # 指向 Python 解释器的路径，确保这是 Spark 执行环境将使用的 Python 版本，根据下载的 python 版本确定，务必确保安装的 PySpark 版本需要的 Python 版本一致如：Requires: Python >=3.9
export PYSPARK_DRIVER_PYTHON=/home/spark/venvs/pyspark_venv/bin/python3.9 # 指向 PySpark Driver 将使用的 Python 解释器（通常与 PYSPARK_PYTHON 相同）

```

- 激活环境变量：
```bash
source ~/.bashrc  # 或 source /etc/profile
```

- 验证：
```bash
spark-shell --version
pyspark --version # 验证 PySpark 是否能识别
echo $SPARK_HOME
echo $PYSPARK_PYTHON
```
> 如使用PySpark，为了更好地管理 Python 依赖，强烈建议为 PySpark 应用使用 Python 虚拟环境，这可以避免不同应用之间的依赖冲突，并使部署更加可靠。通过`venv`或`conda`创建虚拟环境。
```bash
# 安装python
sudo apt install python3.9
# 使用 venv (Python 3 内置)
python3.9 -m venv <你的虚拟环境名称>
# 激活虚拟环境, 推荐创建/venvs 文件夹管理虚拟环境，如/venvs/pyspark_venv
source <你的虚拟环境名称>/bin/activate
# 或者使用 conda
conda create -n <你的虚拟环境名称> python=3.9  # 推荐指定 Python 版本
conda activate <你的虚拟环境名称>

pip install pyspark numpy pandas scikit-learn  # 示例，安装你所需要的包

# 在集群中其他机器上同样创建虚拟环境
```

## 5. 配置 Spark 核心文件
- **修改 $SPARK_HOME/conf 下的配置文件，主要包括**`spark-env.sh`和`spark-defaults.conf`，具体修改内容查看[配置文档](../config_files/)下的文件
> 注意需要更改或复制 spark-env.sh.template 和 spark-defaults.conf.template 为 spark-env.sh 和 spark-defaults.conf。StandAlone 或 HA 模式下需配置 workers 文件。
- 修改完成后通过`scp`命令分发到所有从节点上：
```bash
# 假设用户为spark，节点为node2，spark目录为/opt/spark
scp -r /opt/spark/conf/ spark@node2:/opt/spark/conf/ # 修改主机以分发到后续节点

# 下述命令用于后续修改文件后同步，只会同步修改的文件，更轻量化
rsync -avz /opt/spark/conf/ spark@node2:/opt/spark/conf
```

## 6. 启动 Spark
- ### StandAlone模式启动：Spark 自带的简单资源管理模式
```bash
# 在 Master 节点启动 Master 进程：
/opt/spark/sbin/start-master.sh
# 启动后，可以通过访问 http://<Master_Host>:8080 (即 SPARK_MASTER_WEBUI_PORT) 查看 Master UI。

# 在所有 Worker 节点启动 Worker 进程：
/opt/spark/sbin/start-worker.sh spark://<Master_Host>:7077

# 也可以在 Master 节点上统一启动所有进程：
/opt/spark/sbin/start-all.sh
```
- 验证
  - 检查 Master UI (`http://<Master_Host>:8080`)，确认所有 Worker 节点已注册并显示其可用资源。
  - 在各个节点上通过 jps 命令查看进程，Master 节点应看到 Master 进程，Worker 节点应看到 Worker 进程。

- ### Standalone HA (高可用性) 模式启动 (基于 ZooKeeper)：利用 ZooKeeper 实现 Master 的高可用
```bash
# 需确保 ZooKeeper 集群已正常运行。
# 在 spark-env.sh 中需配置 ZooKeeper 信息，详情查看saprk-env.sh文档

# 在所有 Master 节点上启动 Master 进程，ZooKeeper 会选举出一个 Active Master，其他为 Standby
/opt/spark/sbin/start-master.sh

#在所有 Worker 节点启动 Worker 进程，Worker 会自动通过 ZooKeeper 发现 Active Master。 
/opt/spark/sbin/start-worker.sh spark://node1:7077,node2:7077,node3:7077 # 列出所有可能的Master节点，Worker会通过Zookeeper找到Active的

# 同样可以使用 start-all.sh统一启动所有进程
```
- 验证
  - 检查 Master UI (`http://<Master_Host>:8080`)，你会看到一个 Active Master 和一个或多个 Standby Master。

- ### YARN 模式启动：Spark 将资源管理完全委托给 Hadoop YARN
```bash
# 确保 Hadoop HDFS 和 YARN 集群已正常运行，spark-defaults.conf 中配置了 spark.master yarn
# 如果启用了 Spark Shuffle Service ，需在 yarn-site.xml 中添加相关配置，并将 spark-*-yarn-shuffle.jar 复制到所有 NodeManager 的 yarn/lib 目录，重启所有 NodeManager 服务 以加载 Shuffle Service，详情查看文档末尾。
# 注意不需要单独启动 Spark Master 或 Worker 进程，Spark 应用程序在提交时会作为 YARN 应用程序运行。

# 提交一个简单的 Spark 应用程序 (例如 SparkPi) 到 YARN：
spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master yarn \
  --deploy-mode cluster \
  --driver-memory 512m \
  --executor-memory 2g \
  --executor-cores 1 \
  $SPARK_HOME/examples/jars/spark-examples_2.12-3.5.1.jar \
  10
```
- 验证
  - 访问 YARN ResourceManager Web UI (http://<ResourceManager_Host>:8088)，在“Applications”列表中查看你的 Spark 应用程序是否成功提交、运行并完成。
  - 如果 spark.eventLog.enabled 为 true，部署 Spark History Server 后，可以访问 History Server UI 查看应用程序的详细运行报告。

> yarn-site.xml相关配置：在 yarn-site.xml 中添加以下属性
> **yarn.nodemanager.aux-services:** 这个属性告诉 YARN NodeManager 需要启动哪些辅助服务。你需要在原有值的基础上添加 ,spark_shuffle。如果原来只有 mapreduce_shuffle，那么就变成 mapreduce_shuffle,spark_shuffle。
> **yarn.nodemanager.aux-services.spark_shuffle.class:** 指定了 Spark Shuffle Service 的实现类，固定为 org.apache.spark.network.yarn.YarnShuffleService。
> **spark.shuffle.service.port:** 定义了 Shuffle Service 监听的端口。默认是 7337。请确保这个端口在你的防火墙中是开放的，并且没有被其他服务占用。
```xml
<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle,spark_shuffle</value>
    <description>
      A comma-separated list of auxiliary services that the NodeManager
      should start. Add 'spark_shuffle' to the existing services.
    </description>
</property>

<property>
    <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
    <value>org.apache.spark.network.yarn.YarnShuffleService</value>
    <description>
      The class name for Spark's external shuffle service.
    </description>
</property>

<property>
    <name>spark.shuffle.service.port</name>
    <value>7337</value>
    <description>
      The port for the external shuffle service. Ensure this port is
      open in your firewall and not in use by other services.
    </description>
</property>
```
> 配置后在所有 YARN NodeManager 节点上执行以下步骤，由于 Spark Shuffle Service 的代码封装在一个 JAR 包中，这个 JAR 包需要放置在所有 YARN NodeManager 的 classpath 中，以便 NodeManager 能够加载并运行 Shuffle Service。
```bash
# 找到 Spark 安装目录下的 Shuffle Service JAR 包。它的命名格式通常是 spark-*-yarn-shuffle.jar。
ls $SPARK_HOME/jars/spark-*-yarn-shuffle.jar
# 示例输出：/opt/spark/jars/spark-core_2.12-3.5.1-yarn-shuffle.jar

# 将这个 JAR 包复制到 Hadoop YARN 的公共库目录。这个目录通常是 $HADOOP_HOME/share/hadoop/yarn/lib/。确保你复制的 JAR 包版本与你安装的 Spark 版本和 Scala 版本相匹配。
sudo cp $SPARK_HOME/jars/spark-*-yarn-shuffle.jar $HADOOP_HOME/share/hadoop/yarn/lib/
```
> 在修改了 yarn-site.xml 并复制了 JAR 包之后，你需要重启所有受影响的 YARN NodeManager 服务，以便它们加载新的配置并启动 Spark Shuffle Service。
```bash
sudo systemctl restart hadoop-nodemanager.service
# 或者如果你的Hadoop是手动启动的，使用：
# $HADOOP_HOME/sbin/yarn-daemon.sh restart nodemanager
```
> 最后，在 Spark 的 spark-defaults.conf 文件中，你需要明确告诉 Spark 应用程序使用外部 Shuffle Service，如配置spark.shuffle.service.enabled为True等等。