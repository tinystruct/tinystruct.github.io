# tinystruct 1.7.23 新特性

本文档介绍了 tinystruct 1.7.23 版本中引入的新功能、改进和变更。

> 另请参阅：[1.7.19 新特性](whats-new-1.7.18.md)，了解 HTTP 方法特定动作、AI/MCP 集成和 SSE 支持等早期功能。

## 主要新功能

### 1. 内置 POJO 生成器与自动导入

框架现在包含一个全自动的 POJO 生成器，可以直接从数据库模式创建 Java 类和 XML 映射文件。生成器智能检测列类型并自动添加必要的 Java 导入 — 无需手动指定包。

**支持的数据库：**
- MySQL
- Microsoft SQL Server (MSSQL)
- SQLite
- H2

**使用方法：**

```bash
# 交互模式 — 提示输入表名和输出路径
bin/dispatcher generate

# 非交互模式 — 直接指定表名
bin/dispatcher generate --tables users

# 多个表（分号分隔）
bin/dispatcher generate --tables "users;orders;products"
```

**生成内容：**

对于每个表，生成器生成两个文件：

1. **Java POJO** — 例如 `src/main/java/com/example/objects/User.java`
2. **XML 映射** — 例如 `src/main/resources/com/example/objects/User.map.xml`

生成的类继承自 `AbstractData`，直接与 tinystruct 的 ORM 集成，支持即时的 CRUD 操作（`append()`、`findOneById()`、`update()`、`delete()`）。

### 2. 原生 `LocalDateTime` 支持

Java 8+ `java.time.LocalDateTime` 的完整支持已集成到数据水合层。

**字段映射：**

| SQL 列类型 | Java 类型 | 自动导入 |
|---|---|---|
| `DATETIME`、`TIMESTAMP`、`DATETIME2` | `LocalDateTime` | `java.time.LocalDateTime` |
| `DATE` | `Date` | `java.util.Date` |
| `TIMESTAMP`（显式） | `Timestamp` | `java.sql.Timestamp` |
| `TIME` | `Time` | `java.sql.Time` |

**健壮的水合：**

`FieldInfo` 工具类现在可以处理 `java.sql.Timestamp` 对象和 ISO 兼容字符串的转换，确保在不同 JDBC 驱动和数据库供应商之间的兼容性：

```java
// 在生成的 POJO setData() 方法中
if(row.getFieldInfo("created_at") != null)
    this.setCreatedAt(row.getFieldInfo("created_at").localDateTimeValue());
```

### 3. 简化的 CLI 生成器工作流

`generate` 命令通过删除手动包导入的交互提示进行了简化。生成器现在：

- 从源代码树**自动检测**项目的基础包
- 根据数据库列类型**自动导入**所有必需的类型
- 只提示**表名**和**基础路径** — 两个简单步骤

**之前（1.7.19）：**
```
请指定表名：
请指定基础路径：
请指定要导入的包：   ← 已删除
```

**之后（1.7.23）：**
```
请指定表名：
请指定基础路径：
```

## 架构改进

### 简化的 Generator 接口

`Generator` 接口通过删除 `importPackages()` 方法进行了精简。导入管理现在完全由每个生成器实现内部处理。

**之前：**
```java
public interface Generator {
    void setPath(String path);
    void setPackageName(String packageName);
    void importPackages(String packageNameList);  // 已删除
    void create(String className, String table) throws ApplicationException;
}
```

**之后：**
```java
public interface Generator {
    void setPath(String path);
    void setPackageName(String packageName);
    void create(String className, String table) throws ApplicationException;
}
```

### 现代 Java Switch 表达式

所有生成器现在使用现代 Java switch 表达式进行类型到导入的解析，替换了冗长的 if-else 链：

```java
// 基于 propertyType 自动导入
switch (propertyType) {
    case "LocalDateTime" -> imports.add("java.time.LocalDateTime");
    case "Date" -> imports.add("java.util.Date");
    case "Timestamp" -> imports.add("java.sql.Timestamp");
    case "Time" -> imports.add("java.sql.Time");
}
```

### 唯一且排序的导入

导入使用 `TreeSet` 收集，确保在生成的输出中始终唯一且按字母顺序排序：

```java
import java.io.Serializable;
import java.time.LocalDateTime;
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;
```

## 破坏性变更

### `Generator.importPackages()` 已删除

`importPackages(String packageNameList)` 方法已从 `Generator` 接口及所有实现中删除。如果您的代码直接调用此方法，请删除这些调用 — 导入现在由框架自动处理。

## 迁移指南

### 从 1.7.19 升级到 1.7.23

1. **更新 Maven 依赖**
   ```xml
   <dependency>
       <groupId>org.tinystruct</groupId>
       <artifactId>tinystruct</artifactId>
       <version>1.7.23</version>
   </dependency>
   ```

2. **删除手动导入调用**（如果适用）
   ```java
   // 旧方式 — 不再需要
   generator.importPackages("java.time.LocalDateTime;java.util.Date");

   // 新方式 — 导入自动处理，直接调用 create()
   generator.create(className, tableName);
   ```

3. **享受简化的 CLI**
   `generate` 命令不再提示输入包。只需提供表名和输出路径即可。

## 社区和资源

- **GitHub**：<https://github.com/tinystruct/tinystruct>
- **文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **原型**：<https://github.com/tinystruct/tinystruct-archetype>
- **Smalltalk（AI 聊天）**：<https://github.com/tinystruct/smalltalk>

## 未来计划

### 后续版本计划

- 增强响应式编程支持
- GraphQL 集成
- gRPC 支持
- Kubernetes 原生功能
- 增强监控和指标

## 总结

1.7.23 版本专注于开发者体验，通过自动化 POJO 生成管道提升效率。原生 `LocalDateTime` 支持和自动导入检测的加入意味着更少的手动配置和代码生成过程中更少的错误。简化的 CLI 工作流将生成过程减少到只有两个提示，使从数据库模式到可用 Java 代码的速度更快。
