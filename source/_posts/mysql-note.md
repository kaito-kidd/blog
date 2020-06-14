title: "《深入浅出MySQL》笔记"
date: 2015-03-10 11:56:26
categories: MySQL
tags: [图书, MySQL]
---

### MySQL元数据：


	-- 查看可用的字符编码
	SHOW character set;	|	DESC infomation_schema.character_sets;
	
	-- 查看字符集校对规则
	SHOW COLLATION LIKE 'gbk';	|	DESC infomation_schema.COLLATIONS;
	
	-- 查看当前服务器|数据库的字符集和校对规则
	SHOW variables LIKE 'character_set_server';	character_set_database
	SHOW variables LIKE 'collation_server';		collation_database
	
	-- 查看表的字符集和校对规则
	SHOW CREATE TABLE test_tab;
	
	-- 查看数据库模式
	SELECT @@sql_mode;
	
	-- 修改数据库模式
	SET SESSION | GLOBAL sql_mode='STRICT_TRANS_TABLES';
	
	-- 查看是否支持分区
	SHOW VARIABLES LIKE 'partition';


### 分区4种类型：

	- RANGE：适用于 1.需删除过期数据 2.经常查询包含分区键
	- LIST：类似RANGE，枚举值列表分区
	- HASH：平均分布 1.常规HASH(取模) 2.线性HASH(线性2的幂运算),只支持整型
	- KEY：类似HASH,但不允许使用表达式,除整形外,支持其他类型
	- COLUMNS：1. RANGE COLUMNS, 2. LIST COLUMNS

<!-- more -->	

### SQL优化

	-- 查看当前session所有统计参数
	SHOW status LIKE 'com_%' | Connections Uptime Slow_queries

	观察以下参数：
	- Com_select	- Com_insert	- Com_update	- Com_delete
	- Innodb_rows_read	- Innodb_rows_inserted	- Innodb_rows_updated	- Innodb_rows_deleted
	- Com_commit	- Com_rollback
	- Connnections:链接服务器次数	- Uptime:服务器工作时间		- Slow_queries:慢查询次数

	1、分析SQL语句

	EXPLAN [extended] sql....

	ALL	>	index	>	range	>	ref	>	eq_ref	>	const,system	>	NULL

	全表		索引全表	范围	     唯一/非唯一索引	唯一索引	主键 / 唯一索引		常量


	2、SHOW PROFILE 分析 SQL

	-- 查看是否支持profile
	SELECT @@have_profiling;

	-- 开启session级别的profiling
	SELECT @@profiling;

	SET profilling=1;

	-- 执行SQL
	SELECT COUNT(*) FROM test;

	SHOW profiles;

	SHOW profile FOR query id;


	关注executing, sending data, end 三项

	SHOW profile cpu FOR query id;	-- 查看CPU耗费时间


	3、索引优化

		B-Tree不是二叉树(binary),而平衡树(balanced)

		能用到索引场景：
			1.所有字段都匹配全值(=)
			2.范围匹配
			3.最左前缀匹配
			4.仅对索引列查询
			5.匹配列前缀,使用第一列索引
			6.部分精确,部分范围
			7.IS NULL会用到索引
			8.ICP特性,条件过滤下放到存储引擎
			 
		不能使用索引的场景：
			1.%开头LIKE查询,一般先条件缩小范围,再回表LIKE
			2.数据类型出现隐式转换,例如字段是字符串,where=整数
			3.复合索引不遵循最左前缀
			4.Mysql认为扫索引比扫全表慢
			5.多个OR,其中字段有的有索引,有的没有


	4、查看索引使用情况
 
	SHOW status LIKE 'Handler_read%';

	Handler_read_key越高证明使用索引越多；

	Handler_read_rnd_next越高，证明全表扫描的多；

	

### 表优化

	- 1.定期分析和检查表
	ANALYZE TABLE test;

	CHECK TABLE test;

	- 2.定期优化表
	OPTIMIZE TABLE test;


### 常用优化

	1. 大批量插入数据
		
		- MyISAM：
			ALTER TABLE test DISABLE KEYS;
			LOAD DATA INFILE 'data.txt' INTO TABLE test;
			ALTER TABLE test ENABLE KEYS;

		- InnoDB:
			1.按主键顺序保存后导入
			2.SET UNIQUE_CHECKS=0关闭唯一检查
			3.SET AUTOCOMMIT=0

	2. 优化INSERT
	
		1.使用INSERT INTO test VALUES(1,2),(1,3) ...
		2.使用INSERT DELAYED,马上直接,不保留在内存队列
		3.建表时索引文件和数据文件分开存放
		4.批量插入,增大bulk_insert_buffer_size(只对MyISAM有效)
		5.使用LOAD DATA INFILE

	3. 优化ORDER BY 

		1.适当增大sort_buffer_size和max_length_for_sort_data值
		2.SELECT需要的字段,尽量不要SELECT *

	4. 优化GROUP BY

		1.强制不排序 ORDER BY NULL
		2.JOIN取代嵌套子查询

	5. 优化OR

		OR的各个字段都要有索引

	6. 优化分页查询

		1.使用关联查询,先ORDER BY且LIMIT后的分页数据,主键JOIN回表
		2.记录last_page_record,利用LIMIT n查询(只用于排序字段不会重复场景)

	7. 人为优化

		1.SELECT COUNT(*) FROM test USER INDEX(idx_test_id);(希望参考使用索引)
		2.SELECT COUNT(1) FROM test IGNORE INDEX(idx_test_id);(忽略索引)
		3.SELECT COUNT(1) FROM test FORCE INDEX(idx_test_id);(强制使用索引)

	8. 表分析
		SELECT * FROM tab PROCEDURE ANALYSE();
		SELECT * FROM tab PROCEDURE ANALYSE(16, 256);



### 锁



	MyISAM:

		-- 查看表锁争夺情况
		SHOW status LIKE 'table%';

		concurrent_insert: 
			0:不允许并发插入
			1:如果没有空洞,可以在表尾插入
			2:无论是否有空,都允许插入

		锁调度:
			low-priority-updates:默认以读优先
			SET LOW_PRIORITY_UPDATES=1:使当前连接更新请求优先级降低
			指定INSERT,UPDATE,DELETE语句的LOW_PRIORITY属性,降低优先级
			max_write_lock_count设置值,读大于此值,降低写优先级

	InnoDB:
		
		事物ACID属性

		事物带来的问题:
			更新丢失、脏读、不可重复读、幻读

		隔离级别:
			未提交读、已提交读、可重复读、可序列化

		-- 查看行锁争夺情况
		SHOW status LIKE 'innodb_row_lock';

		行锁实现方式:
			Record lock:对索引项加锁
			Gap lock:对索引项之间的间隙枷锁
			Next-key lock:前两种组合
		
		1.如果检索记录没有索引,相当于表锁
		2.不是同一行记录,但是相同索引键,也会出现行锁
		3.有多个索引,不同事物使用不同索引锁定不同行
		4.检索数据MySQL通过执行计划代价决定

		死锁：

			1.多个session并发存取多个表,约定相同顺序访问,否则有可能产生死锁
			2.批量处理数据,事先对数据排序,每个线程按固定顺序处理,可降低死锁几率
			3.如果更新数据,应直接申请足够级别锁,不应先申请共享锁,再申请排它锁
			4.在可重复读隔离级别下,如果2个线程对相同记录加排他锁,此记录不存在,
				2线程都会加锁成功,如2个线程程序都试图插入新纪录,会出现死锁,
				将隔离级别改为读已提交级别可以避免
			5.隔离级别为读已提交,如果2个线程对相同记录加排他锁,此记录不存在,
				2线程都会加锁成功,如2个线程程序都试图插入新纪录,此时只有1个线程
				能插入成功,另一个线程出现锁等待,第1线程提交后,第2线程因主键重复出错,
				虽然出错,但已获得排他锁,此时有第3个线程来申请排他锁,也会出现死锁

### MySQL Server优化

	组成：1个主线程，4组IO线程，1个锁线程，1个错误监控线程，purge线程

	内存优化原则：
		适当增大内存给MySQL
		如果是MyISAM表，预留适当内存给操作系统
		排序区、链接区是会话级别的，根据最大连接数合理分配

	MyISAM优化：
		1.增大key_buffer_size，建议为内存的1/4

		2.使用多个索引缓存
			key_buffer_size=4G
			hot_cache.key_buffer_size=2G
			cold_cache.key_buffer_size=1G
			init_file=/path/to/data-directory/mysql_init.sql

			cache index sales in hot_cache;
			cache index sales2 in cold_cache;
			load index into cache sales, sales2;

		3.调整中点插入策略
			set global key_cache_divson_limit=70
			set global hot_cache.key_cache_divsion_limit=70

		4.调整read_buffer_size和read_rnd_buffer_size
			以上2个参数是每个session独占

	InnoDB优化：
		1.增大innodb_buffer_pool_size
		2.调整old sublist大小，SHOW GLOBAL VARIABLES LIKE '%innodb_old_blocks_pct%'
		3.调整innodb_old_blocks_time
		4.减少缓存池数量，减少内部争用，调整innodb_buffer_pool_instances
		5.控制innodb buffer刷新，innodb_max_dirty_pages_pct,innodb_io_capacity
		6.打开doublewrite，SHOW GLOBAL VARIABLES LIKE '%doublewrite%'

	并发优化：
		1.调整max_connections
		2.调整back_log
		3.调整table_open_cache
		4.调整thread_cache_size
		5.调整innodb_lock_wait_timeout


### 备份与恢复

	备份：
		mysqldump [options] db_name [tables] > out.sql
		常用参数：
			--add-drop-database：加上drop database语句
			--add-drop-table：加上drop table语句
			--no-create-db：不要create database语句
			--no-create-info：不要create table语句
			--no-data：不要数据，只要表结构
	
	恢复：
		mysql -uroot -p db_name < out.sql
		mysqlbinlog binlog-file | mysql -u root -p

	表的导出：

		SELECT * FROM table INTO OUTFILE '/tmp/tmp.txt'

		mysqldump -u username -T target_dir db_name table_name [option]

	表的导入：

		LOAD DATA INFILE  'filename' INTO TABLE table_name [option]

		mysqlimport -u root -p db_name out.sql [option]

### 权限

	授权：
		GRAN SELECT ON *.* TO t1@localhost IDENTIFIED BY '123'

	查看权限：

		SHOW GRANTS FOR t1@localhost;

	回收/更改权限：
		
		REVOKE SELECT ON *.* FROM t1@localhost;
	
	修改密码：

		- mysqladmin -u user_name -h host_name password 'newpwd'
		- SET PASSWORD FOR 't1'%'%' = PASSWORD('123')
		- SET PASSWORD = PASSWORD('123')
		- GRANT USERAGE ON *.* TO 't1'@'%' IDENTIFIED BY '123';
		- UPDATE user SET Password = PASSWORD('123') WHERE Host='%' AND User='t1';
		- GRANT USER ON *.* TO 't1'@'%' IDENTIFIED BY PASSWORD '123AE809808FDSFSFS';

	删除账号：

		SHOW GRANTS FOR t1@localhost;
		DROP user t1@localhost;


