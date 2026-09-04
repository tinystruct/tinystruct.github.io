# tinystruct 1.7.30 新特性

本文档介绍了 tinystruct 1.7.30 版本中引入的新功能和变更。

> 另请参阅：[1.7.29 新特性](whats-new-1.7.29.md)，了解非对称 RSA 与可配置 JWT 安全等早期功能。

---

## 1.7.30 核心亮点

- **PostgreSQL 数据库支持**：在 `Type` 枚举和数据库操作符中增加了对 PostgreSQL 数据库的原生支持。

---

## 主要新功能与改进

### 1. PostgreSQL 集成
除了 MySQL、SQLite、H2、MS SQL Server 和 Oracle 之外，Tinystruct 现在原生支持 PostgreSQL。
您可以通过在 `application.properties` 中指定相应的驱动并使用 `Type.PostgreSQL` 来配置应用程序使用 PostgreSQL。

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

---

## 社区与相关资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例项目**：<https://github.com/tinystruct/tinystruct-examples>
- **项目骨架**：<https://github.com/tinystruct/tinystruct-archetype>
