# tinystruct 1.7.36 新特性

本文档介绍 tinystruct 1.7.36 版本的变更。该版本重点在于 MCP 加固、可配置的日志处理器以及更精简的依赖。

> 另请参阅：[1.7.35 新特性](whats-new-1.7.35.md)，其中介绍了依赖安全更新和中断处理修复。

---

## 1.7.36 亮点

- **可配置的日志处理器**：`handlers` 属性现在决定创建哪些处理器，并完整支持 `FileHandler`（滚动、大小限制、追加）。
- **加固的 MCP 服务器**：会话初始化前拒绝请求，活跃会话保持存活，且不再记录生成的认证令牌。
- **更安全的 MCP 输入处理**：`tools/call` 和 `resources/read` 能容忍缺失的参数和查询字符串，并对资源参数进行 URL 解码。
- **统一的 Schema 生成**：工具 Schema 的生成和重载合并统一由 `SchemaGenerator` 负责。
- **移除 Kafka 客户端**：`KafkaClient` 及 Kafka 依赖已从框架中移除。
- **UTF-8 调度脚本**：`bin/dispatcher` 和 `bin/dispatcher.cmd` 强制使用 UTF-8，避免非 ASCII 输出乱码。

---

## 详细说明

### 1. 可配置的日志处理器

`handlers` 属性中列出的处理器现在会在启动时创建，并各自拥有独立的级别、格式化器和编码。默认仍为控制台处理器。如需同时写入日志文件，请追加 `FileHandler`：

```properties
handlers = java.util.logging.ConsoleHandler, java.util.logging.FileHandler

java.util.logging.FileHandler.pattern = logs/tinystruct-%g.log
java.util.logging.FileHandler.limit = 10485760
java.util.logging.FileHandler.count = 5
java.util.logging.FileHandler.level = INFO
java.util.logging.FileHandler.formatter = org.tinystruct.system.logging.LogFormatter
java.util.logging.FileHandler.encoding = UTF-8
```

- 日志目录会自动创建。
- 重新配置时被移除的处理器会被关闭，重复初始化不再产生多余的 `.1` / `.2` 日志文件。
- ANSI 颜色仅用于控制台输出。
- 无法加载已配置的格式化器时会记录警告。
- 默认控制台格式化器改为 `org.tinystruct.system.logging.LogFormatter`。

---

### 2. MCP 服务器加固

- **强制初始化**：除 `initialize` 和 `ping` 外的所有方法，在会话未初始化时都会返回 `Session not initialized` 错误。
- **会话保持存活**：任何请求都会刷新会话活动时间戳，而不仅是 `ping`，因此活跃会话不会再被看门狗过期清理。
- **无状态泄漏**：已不存在的会话遗留的状态（例如 `DISCONNECTED`）会被清除。
- **不记录令牌**：未配置认证令牌时会使用生成的令牌，但不再写入日志。如需固定值，请在配置中设置认证令牌。
- **更安静的客户端**：MCP 客户端将完整的 JSON-RPC 载荷日志从 `INFO` 降为 `FINE`。

---

### 3. 更安全的 `tools/call` 和 `resources/read`

- `tools/call` 的 `arguments` 缺失或不是对象时，按空参数处理，而不是抛出类型转换错误。
- `resources/read` 支持不带查询字符串的 URI，并能稳健解析参数（无值的键、值中包含 `=`），同时进行 URL 解码。

---

### 4. 统一的 Schema 生成

`MCPServer` 和 `MCPTool` 中重复的 Schema 代码已合并到 `SchemaGenerator`，它根据 `@Action` / `@Argument` 元数据构建参数 Schema，并合并重载的工具方法。合并后的 Schema 中，只有所有重载都要求的参数才是必填。工具行为保持不变。

---

### 5. 移除 Kafka 客户端

`org.tinystruct.data.tools.KafkaClient` 及 Kafka 依赖已从框架中移除，依赖树因此更精简。

> **注意：** 如果您的应用使用了 `KafkaClient`，请在自己的项目中添加 Kafka 客户端库并自行封装。

---

### 6. UTF-8 调度脚本

`bin/dispatcher` 和 `bin/dispatcher.cmd` 现在以 `-Dfile.encoding=UTF-8` 启动 JVM，并将标准输出/错误编码设为 UTF-8。Windows 脚本还会通过 `chcp 65001` 切换控制台代码页，使中文等非 ASCII 文本正常显示。

---

## 迁移指南

### 升级到 1.7.36

更新 `pom.xml` 中的依赖：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.36</version>
</dependency>
```

如果使用 `dispatcher` 脚本，请同时更新其引用的版本号。

从 1.7.35 升级时请检查：

- MCP 客户端必须在其他请求之前发送 `initialize`（符合规范的客户端本来就会这样做）。
- 依赖 `KafkaClient` 的项目需要自行添加 Kafka 依赖。
- 如果复制过 `application.properties`，建议将控制台格式化器改为 `org.tinystruct.system.logging.LogFormatter`。

---

## 社区与资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **项目原型**：<https://github.com/tinystruct/tinystruct-archetype>
