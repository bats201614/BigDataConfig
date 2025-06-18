# Hive 部署与配置
## 1. 在 Metastore 数据库服务器上创建数据库和用户 (以 MySQL 为例)：
- 登录 MySQL 命令行或使用数据库管理工具。
```sql
CREATE DATABASE hive_metastore CHARACTER SET latin1; -- Hive 3.x 推荐使用 latin1 编码，也可用UTF8
CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'your_password'; -- '%',表示允许从任何主机连接，生产环境建议指定具体IP
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hiveuser'@'%';
FLUSH PRIVILEGES;
```

## 2. 下载Hive
- 从 Apache Hive 官方网站下载稳定版本的 Hive 二进制包:{https://www.apache.org/dyn/closer.cgi/hive/}
  - Windows下载：点击链接下载并上传至Linux中解压
  - Linux下载：在命令行中使用`wget`命令下载：
    ```bash
    wget https://dlcdn.apache.org/hive/ # 速度较慢
    ```

## 3. 解压到指定目录
- 通常解压到`/opt`或`/usr/local`目录下，也可以创建指定目录。
```bash
sudo su - hive #切换至专门用户，后续操作同理
tar -zxvf apache-hive-4.0.1-bin.tar.gz -C /opt/
mv /opt/apache-hive-4.0.1-bin /opt/hive # 重命名为hive，方便管理
ln -s /opt/apache-hive-4.0.1-bin /opt/hive # 或创建软链接
```

## 4. 修改权限
- 将 Hive 目录的所有权赋给运行 Hive 的用户。
```bash
sudo chown -R hive:hive /opt/hive
```

## 5. 配置Hive环境变量
- 编辑 /etc/profile 或用户 .bashrc：
```bash
# /etc/profile 或 ~/.bashrc，根据权限最小化原则推荐~/.bashrc
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
```

- 激活环境变量：
```bash
source ~/.bashrc  # 或 source /etc/profile
```

- 验证：
```bash
hive --version
echo $HIVE_HOME
```

## 6. 下载 MySQL JDBC 驱动
- Hive 需要 JDBC 驱动才能连接到外部 MySQL 数据库，下载与你 MySQL 版本兼容的 Connector/J JAR 包（例如 mysql-connector-java-8.0.28.jar）：{https://dev.mysql.com/downloads/connector/j/}
  - Windows下载：选择Platform Independent，下载tar.gz文件
  - Linux下载：在命令行中使用`wget`命令下载：
    ```bash
    wget https://dev.mysql.com/downloads/connector/j/ # 速度较慢
    ```
- 将下载好的jar包复制到 $HIVE_HOME/lib/ 目录下。不兼容的驱动会导致 Metastore 连接失败。

## 7. 配置 Hive 核心文件
- **修改$HIVE_HOME/conf/下的配置文件，主要包括**`hive-env.sh`、`hive-site.xml`，具体修改内容查看[配置文档](../config_files/)下的文件
> 注意需要更改或复制 hive-env.sh.template和hive-site.xml.template 为 hive-env.sh 和 hive-site.xml。

## 8. 初始化 Metastore 元数据库
- 在第一次启动 Hive 之前，必须对 Metastore 数据库进行初始化，以创建 Hive 所需的元数据表结构。
```bash
schematool -dbType mysql -initSchema
```

- 验证：检查命令输出是否显示`Schema initialization complete`，并登录 MySQL 数据库，查看`hive_metastore` 数据库中是否已创建了`TBLS`,`DBS`,`COLUMNS_V2`等 Hive 元数据表。

## 9. 启动 Metastore 与 HiveServer2（推荐）
- 启动 Metastore 服务
```bash
hive --service metastore & # 后台运行
```

- 启动 HiveServer2 服务
```bash
hive --service hiveserver2 & # 后台运行
```

- 验证：
  - 使用`jps`命令验证`RunJar`（Metastore 服务的 Java 进程）、`HiveServer2`进程是否存在。

## 10. 使用 Beeline 连接 HiveServer2
- 在任意客户端节点（或 HiveServer2 所在节点）使用 Beeline 命令行工具连接 HiveServer2：
```bash
beeline -u "jdbc:hive2://your_ip:10000" -n hiveuser -p your_password # 替换为你的 HiveServer2 地址和用户名密码
```

- 如果连接成功，你将看到 Beeline 提示符，表示 HiveServer2 正常工作。

## 11. 执行 HQL 命令
- 在 Beeline 提示符下，尝试执行一些 HQL 命令来验证 Metastore 和 HDFS 集成
```sql
SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (id INT, name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
SHOW TABLES;
DESCRIBE test_table;
```

- 如果以上命令都能成功执行，并且没有报错，说明 Hive 能够正确与 Metastore 和 HDFS 交互。
- 创建一个本地测试文件，例如 test.csv：
> 1,Alice
2,Bob
3,Charlie

- 将文件加载到 Hive 表中：
```sql
LOAD DATA LOCAL INPATH '/path/to/your/local/test.csv' INTO TABLE test_table;
```

- 查询数据：
```sql
SELECT * FROM test_table;
```

- 如果查询成功并返回数据，且没有 MapReduce/Tez 任务失败，则表示 Hive 与 YARN 的集成也正常。
- 同时，你可以访问 YARN ResourceManager Web UI (`http://hadoop-master:8088`)，查看是否有相关的 MapReduce 或 Tez 应用程序正在运行或已完成。也可以访问 JobHistoryServer Web UI (`http://hadoop-master:19888`) 查看作业历史。
> 后续可在 DataGrip 、 Dbeaver 等 GUI 工具中进行代码撰写，更方便、美观。