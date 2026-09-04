# tinystruct 1.7.30 新特性

本文档介绍了 tinystruct 1.7.30 版本中引入的新功能和变更。

> 另请参阅：[1.7.29 新特性](whats-new-1.7.29.md)，了解非对称 RSA 与可配置 JWT 安全等早期功能。

---

## 1.7.30 核心亮点

- **PostgreSQL 数据库支持**：在 `Type` 枚举和数据库操作符中增加了对 PostgreSQL 的原生支持，同时附带专用的 `PostgreSQLGenerator` POJO 代码生成器。

---

## 主要新功能与改进

### 1. PostgreSQL 集成

Tinystruct 现已在 MySQL、SQLite、H2、MS SQL Server 和 Oracle 的基础上，原生支持 PostgreSQL。新增内容包括：

- **`Type.PostgreSQL`** — `Type` 枚举新增枚举值，对应 `PostgreSQLServer` 仓储实现。
- **`PostgreSQLServer`** — 完整的 `AbstractDataRepository` 实现，支持 `append`、`appendAndGetId`、`update` 和 `find` 操作。
- **`PostgreSQLGenerator`** — 新增 POJO 代码生成器，可自动内省 PostgreSQL 数据库模式并生成可直接使用的 `AbstractData` 子类。
- **自动驱动检测** — 当配置的 JDBC URL 包含 `"postgresql"` 时，`ConnectionManager` 会自动选择 `Type.PostgreSQL`。

#### 配置（`application.properties`）

```properties
# PostgreSQL 配置
driver=org.postgresql.Driver
database.url=jdbc:postgresql://localhost:5432/mydb
database.user=postgres
database.password=your_password
database.connections.max=10
```

> **提示：** 需要在项目的 `pom.xml` 中添加 PostgreSQL JDBC 驱动：
> ```xml
> <dependency>
>     <groupId>org.postgresql</groupId>
>     <artifactId>postgresql</artifactId>
>     <version>42.7.3</version>
> </dependency>
> ```

#### 直接使用 `Type.PostgreSQL`

```java
// 显式选择 PostgreSQL 仓储
Repository repo = Type.PostgreSQL.createRepository();
```

#### PostgreSQL 类型映射

`PostgreSQLServer.find()` 方法可正确处理 PostgreSQL 原生类型：

| PostgreSQL 类型 | Java 类型 |
|---|---|
| `INT`, `SERIAL`, `INTEGER` | `int` / `long` |
| `BIGINT`, `INT8`, `BIGSERIAL` | `long` |
| `REAL`, `FLOAT`, `DOUBLE`, `NUMERIC`, `DECIMAL` | `double` |
| `BOOL`, `BOOLEAN`, `BIT` | `boolean` |
| `DATE`, `TIME`, `TIMESTAMP` | `java.sql.Timestamp` |
| `BYTEA`, `BINARY`, `BLOB` | `byte[]` |
| 其他（`VARCHAR`、`TEXT` 等）| `String` |

#### 为 PostgreSQL 生成 POJO

可使用内置 `PostgreSQLGenerator` 直接从 PostgreSQL 数据库模式生成 `AbstractData` 模型类：

```bash
bin/dispatcher generate --import org.tinystruct.data.tools.PostgreSQLGenerator --table my_table
```

该命令将生成一个包含所有列到字段映射的 `AbstractData` 子类，可直接用于 tinystruct ORM 层。

---

## 升级指南

### 升级至 1.7.30

在 `pom.xml` 中将 tinystruct 依赖版本更新为 `1.7.30`：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.30</version>
</dependency>
```

本版本不引入任何破坏性变更，PostgreSQL 支持属于纯增量更新。

---

## 社区与相关资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例项目**：<https://github.com/tinystruct/tinystruct-examples>
- **项目骨架**：<https://github.com/tinystruct/tinystruct-archetype>
