# Hive 环境变量的配置文件，主要用于设置 Hive 运行时所需的全局环境变量，尤其是 Java 环境和 JVM 内存参数。
# 必要配置：HADOOP_HOME（指定 Hadoop 的安装路径。Hive 严重依赖 Hadoop 的 HDFS（文件存储）和 YARN（资源管理）服务，所以它需要知道 Hadoop 的位置来加载相关的库。）、JAVA_HOME（指定 Hive 运行所使用的 Java Development Kit (JDK) 的安装路径。Hive 是一个基于 Java 的应用程序。）
# 推荐配置：HIVE_SERVER2_HEAPSIZE（专门用于设置 HiveServer2 进程的 JVM 堆内存大小。HiveServer2 是允许客户端（如 Beeline、JDBC/ODBC 应用程序）连接 Hive 执行查询的服务，其内存配置直接影响查询性能和并发能力。）、HIVE_METASTORE_HEAPSIZE（专门用于设置 Hive Metastore 服务进程的 JVM 堆内存大小。如果你的 Metastore 是独立部署为 Thrift 服务，这个配置就非常重要。）、HIVE_LOG_DIR（指定 Hive 服务的日志文件存放目录，可以设置为一个绝对路径。）

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hive and Hadoop environment variables here. These variables can be used
# to control the execution of Hive. It should be used by admins to configure
# the Hive installation (so that users do not have to set environment variables
# or set command line parameters to get correct behavior).
#
# The hive service being invoked (CLI etc.) is available via the environment
# variable SERVICE


# Hive Client memory usage can be an issue if a large number of clients
# are running at the same time. The flags below have been useful in 
# reducing memory usage:
#
# if [ "$SERVICE" = "cli" ]; then
#   if [ -z "$DEBUG" ]; then
#     export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xms10m -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:+UseParNewGC -XX:-UseGCOverheadLimit"
#   else
#     export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xms10m -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:-UseGCOverheadLimit"
#   fi
# fi

# The heap size of the jvm stared by hive shell script can be controlled via:
#
# export HADOOP_HEAPSIZE=1024
#
# Larger heap size may be required when running queries over large number of files or partitions. 
# By default hive shell scripts use a heap size of 256 (MB).  Larger heap size would also be 
# appropriate for hive server.


# Set HADOOP_HOME to point to a specific hadoop install directory
# HADOOP_HOME=${bin}/../../hadoop
export HADOOP_HOME=/opt/hadoop/hadoop
export JAVA_HOME=/usr/lib/jvm/jdk_21
# Hive Configuration Directory can be controlled by:
# export HIVE_CONF_DIR=

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
# export HIVE_AUX_JARS_PATH=

# Where Hive log files are stored.
export HIVE_LOG_DIR=/opt/hive/logs

# HiveServer2 Heap Size (e.g., 4GB)
export HIVE_SERVER2_HEAPSIZE="4096m"

# Hive Metastore Heap Size (e.g., 2GB)
export HIVE_METASTORE_HEAPSIZE="2048m"