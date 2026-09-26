# tinystruct 1.7.31 新特性

本文档重点介绍了 tinystruct 1.7.31 版本中引入的新特性、性能改进和增强。

> 另请参阅：[1.7.30 新特性](whats-new-1.7.30.md)，了解最初的 PostgreSQL 数据库支持。

---

## 1.7.31 亮点

- **PostgreSQL SSL 与 Schema 支持**：JDBC SSL 证书/密钥文件现在可以从类路径解析，并且所有数据库类型均支持带有 Schema 限定的表映射。
- **性能与稳定性全面优化**：对 XML 映射模板、SQL 注入检测结果以及类路径查找增加缓存；优化了所有存储库的批量行填充操作。
- **改进锁定与分布式协调**：在 `Watcher` 中为文件锁获取添加了轮询超时机制；修正了 `DistributedMessageQueue` 中的状态验证与轮询休眠逻辑。
- **PostgreSQL 美元引号代码块支持**：`Dispatcher` 现已正确解析包含 PostgreSQL 美元引号块的 SQL 脚本。
- **MCP 工具 Schema 与请求分发改进**：在模型上下文协议（MCP）层提供了更好的 Schema 生成及请求分发。

---

## 主要新特性与增强

### 1. PostgreSQL SSL 证书类路径解析

`ConnectionManager` 现可从应用程序类路径解析 JDBC SSL 证书和密钥文件。这使得将 SSL 资源打包到 JAR 或部署包中变得极为简单，而无需依赖绝对的文件系统路径。

#### 配置（`application.properties`）

```properties
# SSL 密钥/证书路径自动从类路径解析
database.url=jdbc:postgresql://localhost:5432/mydb?ssl=true&sslcert=classpath:ssl/client.crt&sslkey=classpath:ssl/client.key
database.user=postgres
database.password=your_password
```

---

### 2. Schema 限定的表映射

所有数据库类型（MySQL、PostgreSQL、SQLite、MS SQL Server）现在都在 XML 映射中支持带有 Schema 限定的表名（`schema.table` 表示法）。这在单个数据库中共存多个 Schema 的 PostgreSQL 中尤为重要。

```xml
<!-- 示例：将实体映射到带有 Schema 限定的表 -->
<mapping table="public.users">
    <field name="id"   column="id"   type="INTEGER" />
    <field name="name" column="name" type="VARCHAR" />
</mapping>
```

`PostgreSQLGenerator` 现可跨 Schema 进行表内省并生成正确限定的映射。

---

### 3. 性能与稳定性改进

#### 针对热路径的缓存层

添加了多个缓存，以消除在热路径上的重复 I/O 和计算：

| 缓存 | 避免的内容 |
|---|---|
| XML 映射模板缓存 (`Mapping`) | 每次实例化实体时重新解析 XML 文件 |
| 类路径查找缓存 (`ApplicationManager`) | 针对同一类名重复扫描类路径 |
| SQL 注入结果缓存 (`SQLInjectionDetector`) | 重新评估相同的 SQL 字符串 |

#### 优化的批量行填充

`MySQLServer`、`PostgreSQLServer`、`SQLiteServer` 和 `SQLServer` 现在使用一个共享的、优化的行填充循环，消除了在处理大型结果集时对每一行进行冗余 `ResultSetMetaData` 调用的情况。

---

### 4. 改进锁定与分布式协调

#### `Watcher` — 文件锁的轮询超时

`Watcher.lock()` 现在使用带有可配置超时的受限轮询代替无限期阻塞，防止在使用文件监视的部署中出现死锁。

#### `DistributedMessageQueue` — 稳定性修复

- 修复了锁获取状态验证中的竞态条件。
- 修正了轮询休眠间隔，以降低高并发争用下的 CPU 空转。

#### `DistributedLock` — 正确性改进

内部状态转换现已正确设置屏障（fenced），确保在释放之前始终能够正确识别锁的持有者。

---

### 5. PostgreSQL 美元引号代码块解析

`Dispatcher` 的 SQL 脚本解析器现已正确处理使用美元引号字符串字面量（`$$`...`$$` 或 `$tag$`...`$tag$`）的 PostgreSQL 函数和过程定义。这允许在不需要人工绕过的情况下执行多语句 DDL 脚本。

```sql
-- 这现在可以正确地通过 Dispatcher 执行
CREATE OR REPLACE FUNCTION greet(name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN 'Hello, ' || name || '!';
END;
$$ LANGUAGE plpgsql;
```

---

### 6. MCP 工具 Schema 生成与请求分发

模型上下文协议层获得了一些有针对性的改进：

- **Schema 生成**：`MCPApplication` 现可为工具生成更准确的输入 Schema，包括正确处理可选参数与必填参数。
- **请求分发**：当多个工具具有重叠的操作路径时，`MCPServer` 会更可靠地分发工具调用请求。

---

## 迁移指南

### 更新到 1.7.31

将您的 `pom.xml` 依赖更新至 `1.7.31` 版本：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.31</version>
</dependency>
```

本版本未引入破坏性更改，所有改进均向后兼容。

---

## 社区与资源

- **GitHub 仓库**: <https://github.com/tinystruct/tinystruct>
- **官方文档**: <https://tinystruct.org>
- **示例项目**: <https://github.com/tinystruct/tinystruct-examples>
- **项目骨架**: <https://github.com/tinystruct/tinystruct-archetype>
