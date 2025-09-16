# tinystruct 框架

`"耶和华啊，你所造的何其多！都是你用智慧造成的；遍地满了你的丰富。"`
***诗篇 104:24***

## 概述

tinystruct 是一个简单而强大的 Java 开发框架。它秉承简单思维和更好的设计原则，易于使用的同时提供卓越的性能。

## 主要特性

- **轻量级架构**：最小的开销，最大的灵活性
- **双模式支持**：同时支持 Web 应用和命令行工具开发
- **简单配置**：易于设置和自定义
- **高性能**：优化的执行效率
- **数据库集成**：内置多数据库支持
- **RESTful 支持**：便捷的 API 开发
- **命令行工具**：强大的 CLI 功能

## 快速开始

### Maven 集成

在 pom.xml 中添加依赖：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.5</version>
    <classifier>jar-with-dependencies</classifier>
</dependency>
```

### 基础应用示例

```java
package tinystruct.examples;

import org.tinystruct.AbstractApplication;
import org.tinystruct.ApplicationException;
import org.tinystruct.system.annotation.Action;

public class Example extends AbstractApplication {

    @Override
    public void init() {
        // 初始化代码
    }

    @Action("praise")
    public String praise() {
        return "赞美主！";
    }

    @Action("say")
    public String say(String words) {
        return words;
    }
}
```

## 文档目录

- [入门指南](getting-started.md)
- [核心概念](core-concepts.md)
- [Web应用开发](web-applications.md)
- [命令行应用](cli-applications.md)
- [配置说明](configuration.md)
- [数据库集成](database.md)
- [高级特性](advanced-features.md)
- [最佳实践](best-practices.md)
- [API 参考](api/README.md)

## 社区与支持

- GitHub 仓库：[https://github.com/tinystruct/tinystruct](https://github.com/tinystruct/tinystruct)
- 问题追踪：[https://github.com/tinystruct/tinystruct/issues](https://github.com/tinystruct/tinystruct/issues)
- 讨论论坛：[https://github.com/tinystruct/tinystruct/discussions](https://github.com/tinystruct/tinystruct/discussions)

## 许可证

基于 Apache License 2.0 授权