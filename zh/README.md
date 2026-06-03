# tinystruct 框架

`"耶和华啊，你所造的何其多！都是你用智慧造成的；遍地满了你的丰富。"`
***诗篇 104:24***

## 概述

tinystruct 是一个简单而强大的 Java 开发框架。它秉承简单思维和更好的设计原则，易于使用的同时提供卓越的性能。

## 主要特性

- **现代架构**：无需 `main()` 方法，通过 CLI 命令直接启动
- **双模式支持**：CLI 和 Web 是平等公民，代码库统一
- **内置服务器**：原生支持 Netty, Tomcat 和 Undertow
- **AI 就绪**：专为 AI 集成和 Model Context Protocol (MCP) 设计
- **SSE 支持**：原生 Server-Sent Events 支持，用于实时应用
- **高性能**：优化的执行效率，处理超过 86,000 req/s
- **极简配置**：零样板代码哲学
- **注解路由**：使用 `@Action` 进行简洁直观的路由


## 快速开始

### Maven 集成

在 pom.xml 中添加依赖：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.25</version>
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

    @Action(value = "hello", mode = Mode.HTTP_GET)
    public String helloGet() {
        return "GET";
    }
}
```

## 为什么 tinystruct 是现代化的？

1. **无需 `main()` 方法**：应用程序可以通过 `bin/dispatcher` 等 CLI 命令直接启动，无需样板代码。
2. **CLI 和 Web 的统一设计**：与许多框架不同，tinystruct 将 CLI 和 Web 视为平等公民。这使其非常适合 AI 任务、脚本自动化和混合应用。
3. **内置轻量级 HTTP 服务器**：无论是 Netty 还是 Tomcat，tinystruct 都将服务器生命周期集成在框架内部。
4. **极简配置哲学**：配置被简化到极致。无需配置数百个 bean 或复杂的 XML/YAML 文件。
5. **基于注解的路由**：使用 `@Action` 进行清晰直观的路由，消除了复杂的控制器层级。
6. **性能优先架构**：几乎零开销。没有基于反射的 bean 扫描或不必要的拦截器。
7. **AI 和 MCP 集成**：内置对 Model Context Protocol (MCP) 和 AI 驱动工作流的支持。

## 文档目录

- [入门指南](getting-started.md)
- [核心概念](core-concepts.md)
- [Web应用开发](web-applications.md)
- [命令行应用](cli-applications.md)
- [配置说明](configuration.md)
- [数据库集成](database.md)
- [高级特性](advanced-features.md)
- [最佳实践](best-practices.md)
- [AI 与 MCP 集成](mcp-integration.md)
- [API 参考](api/README.md)

## 社区与支持

- GitHub 仓库：[https://github.com/tinystruct/tinystruct](https://github.com/tinystruct/tinystruct)
- 问题追踪：[https://github.com/tinystruct/tinystruct/issues](https://github.com/tinystruct/tinystruct/issues)
- 讨论论坛：[https://github.com/tinystruct/tinystruct/discussions](https://github.com/tinystruct/tinystruct/discussions)

## 许可证

基于 Apache License 2.0 授权