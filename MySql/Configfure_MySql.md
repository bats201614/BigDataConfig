# MySQL 数据库部署与配置
## 1. 下载与安装 MySQL 数据库
- 从 MySQL 官方网站下载适合的版本:{https://dev.mysql.com/downloads/}
  - Windows下载：点击`MySQL Installer for Windows`，选择合适的版本下载`.msi`文件，下载完成后运行安装向导。
    >  推荐选择 "Server Only"。如果后续需要图形化管理工具，可以选择 "Full"，确保 MySQL Server 已被选中；类型和网络选择 "Development Computer" (开发机) 或 "Server Computer" (服务器)，默认端口 3306，通常不需要修改，并勾选 "Open Firewall port for network access" (在防火墙中打开端口，允许外部连接)；设置 MySQL root 用户的密码，并记牢，后续点击next即可。
  - Linux下载： 
  - CentOS/RHEL 通过官方网站找到适合你 CentOS/RHEL 版本的 mysql80-community-release-elX.rpm (X 为你的系统版本，如 el7, el8)，在命令行中使用`wget`命令下载：
    ```bash
    wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm # 速度较慢
    rpm -ivh mysql80-community-release-el7-3.noarch.rpm

    # 安装MySQL Server：
    sudo yum install -y mysql-community-server 
    # 启动 MySQL 服务：
    sudo systemctl start mysqld
    sudo systemctl enable mysqld
    # 查找初始密码：
    sudo grep 'temporary password' /var/log/mysqld.log # 请记录 root@localhost: 后面的一串字符作为临时密码”，例如： your_temporary_password
    # 运行安全脚本：
    sudo mysql_secure_installation # 按照提示输入临时密码后，设置新的 root 密码（建议使用强密码），据提示选择是否删除匿名用户、禁止 root 远程登录、删除测试数据库等。在生产环境中，建议删除匿名用户、禁止 root 远程登录、删除测试数据库。
    ```
  - Ubuntu/Debian 直接通过`apt`安装 MySQL Server：
    ```bash
    sudo apt install -y mysql-server
    # 运行安全脚本
    sudo mysql_secure_installation # 与 CentOS/RHEL 类似，第一步中输入当前的 root 密码，如果没有设置过，可能为空或系统自动生成。
    ```

## 2. 配置 MySQL
- 对于 Windows：
  1 查找 my.ini 配置文件：通常位于 MySQL 安装目录下的`C:\Program Files\MySQL\MySQL Server X.X\`或`C:\ProgramData\MySQL\MySQL Server X.X\`（默认是隐藏的）中（具体安装目录参考你的实际安装目录）。
  2. 在`[mysqld]`段落下添加或修改以下配置项（推荐）：
    ```bash
    [mysqld]
    # 允许远程连接 (通常在安装时已配置防火墙，但在此确认)
    bind-address = 0.0.0.0 # 或指定你允许连接的主机IP

    # 字符集设置
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci

    # 事务日志配置
    innodb_flush_log_at_trx_commit = 1 # 控制事务日志的刷新行为，1为每次事务提交都将日志刷新到磁盘（最安全，但性能略低），推荐用于绝大多数生产环境；0为每秒将日志刷新到磁盘（可能丢失一秒的数据）；2为每次提交写入日志，每秒刷新到磁盘（介于 0 和 1 之间）。
    innodb_buffer_pool_size = 2G # InnoDB 缓冲池大小，根据服务器内存大小调整，建议设置为可用物理内存的 50% 到 80%
    innodb_log_file_size = 256M # InnoDB 事务日志文件大小，较大的日志文件可以减少磁盘 I/O，提高写入性能，但恢复时间会稍长。

    # 其他推荐设置
    max_connections = 500 # 最大用户连接数，据你的应用并发需求进行调整
    default_time_zone='+8:00' # 设置服务器时区。根据你的地理位置设置，例如 '+8:00' 代表东八区，这有助于避免数据插入和查询时的时区混淆。

    # 重启 MySQL 服务以应用更改：找到名为 MySQL80 (或你安装时设置的名称) 的服务，右键点击该服务，选择 "Restart" (重启)。
    ```

- 对于Linux
  1. 编辑 MySQL 配置文件：通常位于`/etc/my.cnf`(CentOS/RHEL) 或`/etc/mysql/mysql.conf.d/mysqld.cnf`(Ubuntu)，通过`sudo vim /etc/mysqld.cnf`编辑
  2. 根据上述配置在`[mysqld]`段落下添加或修改配置项
  3. 重启 MySQL 服务以应用更改：
    ```bash
    sudo systemctl restart mysqld
    ```

## 3. 创建数据库和用户
- Linux：
```bash
mysql -u root -p # 输入root密码

CREATE DATABASE my_app_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; # 创建数据库(以 my_app_db 为例)，这里的字符集和排序规则应与你在 my.cnf/my.ini 中设置的保持一致。

CREATE USER 'app_user'@'%' IDENTIFIED BY 'your_secure_password'; # 创建用户 'app_user'，密码 'your_secure_password'

GRANT ALL PRIVILEGES ON my_app_db.* TO 'app_user'@'%'; # 授予权限：允许 'app_user' 用户从任何主机 (%) 连接到 'my_app_db' 数据库，并拥有所有权限，生产环境中建议指定主机 IP 地址

FLUSH PRIVILEGES; # 刷新权限，使更改生效
```

- Windows：
  - 与上述一致，打开方式切换为打开命令提示符 (CMD) 或 PowerShell，切换到 MySQL 安装目录的 bin 文件夹：
    ```bash
    cd "C:\Program Files\MySQL\MySQL Server X.X\bin" # 如已将bin文件夹添加到环境变量可直接在命令行登录

    mysql -u root -p # 输入root密码，后续步骤一致
    ```

## 4. 验证
- 检查 MySQL 服务状态：
```bash
sudo systemctl status mysqld # Linux：应该显示 'active (running)'

# Windows：打开 "服务" 管理器，确认 MySQL80 (或对应服务名) 服务状态为 "正在运行"。
```

- 尝试使用`root`用户和新创建的用户在本地登录 MySQL 命令行：
```bash
mysql -u root -p
# 输入root密码

mysql -u app_user -p
# 输入app_user密码
```

- 登录后，可以执行以下 SQL 命令检查数据库和用户进行验证：：
```sql
SHOW DATABASES;
-- 应该能看到你创建的 'my_app_db'

USE mysql;
SELECT user, host FROM user;
-- 应该能看到 'app_user' 和它允许连接的 'host' (例如 '%')
```

- 远程连接测试(如果允许远程访问)：
```bash
mysql -h <MySQL服务器IP> -u app_user -p
# 输入app_user密码
```
