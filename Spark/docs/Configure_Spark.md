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
export SPARK_HOME=/opt/spark/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# PySpark相关配置
export PYSPARK_PYTHON=/home/hadoop/venvs/pyspark_venv/bin/python3.9 # 指向 Python 解释器的路径，确保这是 Spark 执行环境将使用的 Python 版本，根据下载的 python 版本确定，务必确保安装的 PySpark 版本需要的 Python 版本一致如：Requires: Python >=3.9
export PYSPARK_DRIVER_PYTHON=/home/hadoop/venvs/pyspark_venv/bin/python3.9 # 指向 PySpark Driver 将使用的 Python 解释器（通常与 PYSPARK_PYTHON 相同）

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
> 注意需要更改或复制 spark-env.sh.template 和 spark-defaults.conf.template 为 spark-env.sh 和 spark-defaults.conf。StandAlone模式下需配置 workers 文件。
- 修改完成后通过`scp`命令分发到所有从节点上：
```bash
# 假设用户为spark，节点为node2，是spark目录为/opt/spark
scp -r /opt/spark/conf/ spark@node2:/opt/spark/conf/ # 修改主机以分发到后续节点

# 下述命令用于后续修改文件后同步，只会同步修改的文件，更轻量化
rsync -avz /opt/spark/conf/ spark@node2:/opt/spark/  
```

## 6. 启动 Spark
- 