#  Apache Spark 的环境变量配置文件，主要用于设置 Spark 运行时的环境参数，特别是与 Java、Hadoop 和 YARN 集成相关的环境变量。这个文件在 Spark 服务启动和应用程序提交时会被加载。
# 必要配置：JAVA_HOME（指定 Spark 运行所使用的 Java Development Kit (JDK) 的安装路径。Spark 是一个基于 JVM 的应用程序，所以它需要知道 Java 的位置。）、HADOOP_HOME（指定 Hadoop 的安装路径。Spark 在 YARN 模式下运行时，需要通过 HADOOP_HOME 来找到 Hadoop 相关的库和二进制文件，以便与 HDFS（文件存储）和 YARN（资源管理）进行交互。）、YARN_CONF_DIR（指定 YARN 配置文件的位置。当 Spark 应用程序以 YARN 模式（spark.master yarn）运行时，它需要读取 YARN 的配置文件（如 yarn-site.xml、core-site.xml）来了解 ResourceManager 的地址、容器内存限制等信息。）
# 推荐配置：PYSPARK_PYTHON 和 PYSPARK_DRIVER_PYTHON（必需，如果使用 PySpark，指定 PySpark 使用的 Python 解释器路径）、SPARK_DRIVER_MEMORY 和 SPARK_EXECUTOR_MEMORY（设置 Spark Driver 和 Executor 的默认 JVM 堆内存）
# StandAlone模式下：需配置 SPARK_MASTER_HOST（指定 Spark Master 节点的主机名或 IP 地址）、SPARK_MASTER_PORT（指定 Spark Master 进程监听的端口号）、SPARK_MASTER_WEBUI_PORT（指定 Spark Master Web UI 监听的端口号）、SPARK_WORKER_CORES（指定 每个 Spark Worker 节点分配给 Spark 应用程序使用的 CPU 核数总和）、SPARK_WORKER_MEMORY（每个 Spark Worker 节点分配给 Spark 应用程序使用的总内存量）、SPARK_WORKER_PORT（Spark Worker 进程监听的端口号）、SPARK_WORKER_WEBUI_PORT（Spark Worker Web UI 监听的端口号）

#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit that to configure Spark for your site.

# Options read when launching programs locally with
# ./bin/run-example or ./bin/spark-submit
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public dns name of the driver program

# Options read by executors and drivers running inside the cluster
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public DNS name of the driver program
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data

# Options read in any mode
# - SPARK_CONF_DIR, Alternate conf dir. (Default: ${SPARK_HOME}/conf)
# - SPARK_EXECUTOR_CORES, Number of cores for the executors (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Executor (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Driver (e.g. 1000M, 2G) (Default: 1G)

# Options read in any cluster manager using HDFS
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files

# Options read in YARN client/cluster mode
# - YARN_CONF_DIR, to point Spark towards YARN configuration files when you use YARN

# Options for the daemons used in the standalone deploy mode
# - SPARK_MASTER_HOST, to bind the master to a different IP address or hostname
# - SPARK_MASTER_PORT / SPARK_MASTER_WEBUI_PORT, to use non-default ports for the master
# - SPARK_MASTER_OPTS, to set config properties only for the master (e.g. "-Dx=y")
# - SPARK_WORKER_CORES, to set the number of cores to use on this machine
# - SPARK_WORKER_MEMORY, to set how much total memory workers have to give executors (e.g. 1000m, 2g)
# - SPARK_WORKER_PORT / SPARK_WORKER_WEBUI_PORT, to use non-default ports for the worker
# - SPARK_WORKER_DIR, to set the working directory of worker processes
# - SPARK_WORKER_OPTS, to set config properties only for the worker (e.g. "-Dx=y")
# - SPARK_DAEMON_MEMORY, to allocate to the master, worker and history server themselves (default: 1g).
# - SPARK_HISTORY_OPTS, to set config properties only for the history server (e.g. "-Dx=y")
# - SPARK_SHUFFLE_OPTS, to set config properties only for the external shuffle service (e.g. "-Dx=y")
# - SPARK_DAEMON_JAVA_OPTS, to set config properties for all daemons (e.g. "-Dx=y")
# - SPARK_DAEMON_CLASSPATH, to set the classpath for all daemons
# - SPARK_PUBLIC_DNS, to set the public dns name of the master or workers

# Options for launcher
# - SPARK_LAUNCHER_OPTS, to set config properties and Java options for the launcher (e.g. "-Dx=y")

# Generic options for the daemons used in the standalone deploy mode
# - SPARK_CONF_DIR      Alternate conf dir. (Default: ${SPARK_HOME}/conf)
# - SPARK_LOG_DIR       Where log files are stored.  (Default: ${SPARK_HOME}/logs)
# - SPARK_LOG_MAX_FILES Max log files of Spark daemons can rotate to. Default is 5.
# - SPARK_PID_DIR       Where the pid file is stored. (Default: /tmp)
# - SPARK_IDENT_STRING  A string representing this instance of spark. (Default: $USER)
# - SPARK_NICENESS      The scheduling priority for daemons. (Default: 0)
# - SPARK_NO_DAEMONIZE  Run the proposed command in the foreground. It will not output a PID file.
# Options for native BLAS, like Intel MKL, OpenBLAS, and so on.
# You might get better performance to enable these options if using native BLAS (see SPARK-21305).
# - MKL_NUM_THREADS=1        Disable multi-threading of Intel MKL
# - OPENBLAS_NUM_THREADS=1   Disable multi-threading of OpenBLAS

# Options for beeline
# - SPARK_BEELINE_OPTS, to set config properties only for the beeline cli (e.g. "-Dx=y")
# - SPARK_BEELINE_MEMORY, Memory for beeline (e.g. 1000M, 2G) (Default: 1G)

export JAVA_HOME=/usr/lib/jvm/jdk_21
export HADOOP_HOME=/opt/hadoop/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PYSPARK_PYTHON=/home/hadoop/venvs/pyspark_venv/bin/python3.9
export PYSPARK_DRIVER_PYTHON=/home/hadoop/venvs/pyspark_venv/bin/python3.9

