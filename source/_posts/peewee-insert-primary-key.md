title: "peewee插入数据后获取主键值"
date: 2015-10-13 23:20:01
categories: Python
tags: [python, peewee]
---

> 最近使用`python`的ORM框架`peewee`开发项目，遇到一个问题就是：在插入数据后，获取不到数据库生成的自增主键值，然后分析源码后得到解决方案，以此记录。


首先，定义`model`：

	class User(Model):

    	id = IntegerField(primary_key=True)	
    	username = CharField()
   
    	class Meta:
        	database = db
        	db_table = "user"
        	
其中主键`id`是整型自增类型。

根据`peewee`官方文档介绍，插入数据时使用如下：

	user = User(username='admin')
	user.save()
	
	或
	
	user = User.create(username='admin')
	
	或
	
	id = User.insert(username='admin).execute()
	
但是获取`user.id`或`id`结果却为`None`。

于是乎开始看`peewee`的源码，看到底发生了什么？

首先看`Moel`的`create`方法：

	@classmethod
    def create(cls, **query):
        inst = cls(**query)
        inst.save(force_insert=True)	# 还是调用本类的save方法
        inst._prepare_instance()
        return inst

发现`create`方法还是调用本类中得`save`方法，那么好办了，来看`save`方法做了些什么？

<!-- more -->

	def save(self, force_insert=False, only=None):
        field_dict = dict(self._data)	# 所有属性数据
        pk_field = self._meta.primary_key	# 主键列
        pk_value = self._get_pk_value()	# 主键值
        if only:
            field_dict = self._prune_fields(field_dict, only)
        self._populate_unsaved_relations(field_dict)
        # 根据主键值和强制插入标记，判断是更新还是插入
        if pk_value is not None and not force_insert:
            if self._meta.composite_key:
                for pk_part_name in pk_field.field_names:
                    field_dict.pop(pk_part_name, None)
            else:
                field_dict.pop(pk_field.name, None)
            rows = self.update(**field_dict).where(self._pk_expr()).execute()
        else:
        	# 插入操作，最终调用本类的insert方法，得到数据库返回的主键值
            pk_from_cursor = self.insert(**field_dict).execute()
            if pk_from_cursor is not None:
                pk_value = pk_from_cursor
            # 设置model的主键值
            self._set_pk_value(pk_value)
            rows = 1
        self._dirty.clear()
        return rows

通过上面的注释和逻辑，我们终于知道，插入数据最终还是调用本类的`insert`方法，并执行`execute`方法，`insert`方法是这样的：

    @classmethod
    def insert(cls, **insert):
        return InsertQuery(cls, insert)
        
此方法传入`model`数据并返回`InsertQuery`对象，找到此类的`execute`方法：

    def execute(self):
        insert_with_loop = (
            self._is_multi_row_insert and
            self._query is None and
            self._returning is None and
            not self.database.insert_many)
        if insert_with_loop:
            return self._insert_with_loop()

        if self._returning is not None and self._qr is None:
            return self._execute_with_result_wrapper()
        elif self._qr is not None:
            return self._qr
        else:
        	# 执行插入数据库操作
            cursor = self._execute()
            if not self._is_multi_row_insert:
                if self.database.insert_returning:
                    pk_row = cursor.fetchone()
                    meta = self.model_class._meta
                    clean_data = [
                        field.python_value(column)
                        for field, column
                        in zip(meta.get_primary_key_fields(), pk_row)]
                    if self.model_class._meta.composite_key:
                        return clean_data
                    return clean_data[0]
                # 重点 --> 获取插入数据返回的主键值
                return self.database.last_insert_id(cursor, self.model_class)
            elif self._return_id_list:
                return map(operator.itemgetter(0), cursor.fetchall())
            else:
                return True 

从上面可以得知，返回主键值是调用了`self.database.last_insert_id(cursor, self.model_class)`，`self.database`指的是`Database`实例对象，观察`last_insert_id`方法：

    def last_insert_id(self, cursor, model): 
        if model._meta.auto_increment:
            return cursor.lastrowid
            
此方法判断`model._meta`也就是`ModelOptions`的`auto_increment`属性是否为`True`，如果是则返回主键值，否则返回`None`，那么这个`auto_increment`是在什么时候设置的呢？

我们找到在创建每个`Model`时，都会把`ModelOptions`赋值给`_meta`属性，而`Model`的创建，必须经过`BaseModel`元类创建生成，找到`BaseModel`的`__new__`方法，果然，我们看到赋值过程，以及控制`auto_increment`变量的逻辑：

    def __new__(cls, name, bases, attrs):
        ...
        cls = super(BaseModel, cls).__new__(cls, name, bases, attrs)
        # 创建MoelOptions对象
        cls._meta = ModelOptions(cls, **meta_options)
		....
        for name, attr in cls.__dict__.items():
            if isinstance(attr, Field):
                if attr.primary_key and model_pk:
                    raise ValueError('primary key is overdetermined.')
                elif attr.primary_key:
                	# 主键列和名称
                    model_pk, pk_name = attr, name
                else:
                    fields.append((attr, name))
		...
        if model_pk is not False:
            model_pk.add_to_class(cls, pk_name)
            cls._meta.primary_key = model_pk
            # 重点是这里，根据model_pk的类型或者model_pk的属性来标记auto_increment
            cls._meta.auto_increment = (
                isinstance(model_pk, PrimaryKeyField) or
                bool(model_pk.sequence))
            cls._meta.composite_key = composite_key
		....
        return cls

好了，答案找到了：如果主键类型是`PrimaryKeyField`或主键属性`sequence`为`True`，插入数据后就可以得到自增主键值！

那么最终解决方案如下，定义`Model`时：

	class User(Model):

    	id = IntegerField(primary_key=True, sequence=True)
    	或
    	id = PrimaryKeyField()
    		
    	username = CharField()
   
    	class Meta:
        	database = db
        	db_table = "user"

> 其实这个问题解决方案简单到极点，但我们遇到这种问题时，要有这种解决问题的思路：`根据API一步步跟进，深入源码，找到最底层的调用结构，得到解决问题的关键。这样一能提升我们解决问题的能力，二能对框架额源码进行深入学习！`这对自身的成长是非常有必要的！！

