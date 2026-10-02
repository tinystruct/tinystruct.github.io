# tinystruct 1.7.35 新特性

本文档介绍 tinystruct 1.7.35 版本的变更。这是一个维护版本，重点在于依赖安全、可靠性和构建工具。

> 另请参阅：[1.7.34 新特性](whats-new-1.7.34.md)，其中介绍了基于注解的 ORM 映射和枚举集合参数。

---

## 1.7.35 亮点

- **依赖升级**：Lettuce 7.8.0、H2 2.5.252、Mockito 5.24.0，并固定 Netty BOM 4.2.18.Final。
- **CVE 修复**：存在漏洞的传递依赖（Netty、Kafka 的 zstd-jni / lz4-java / snappy-java 以及 Reactor）现已覆盖为已修复版本。
- **正确的中断处理**：`DistributedMessageQueue` 和 `AlarmClock` 现在会恢复线程中断标志，而不是吞掉 `InterruptedException`。
- **更简洁的 `DistributedMessageQueue`**：重复的生产者/消费者 Runnable 已提取为共享的 `produce` / `consume` 辅助方法。
- **CI 工作流**：新增 GitHub Actions 构建工作流，并将 central 发布插件升级到 0.11.0。

---

## 详细说明

### 1. 依赖升级与 CVE 修复

| 依赖 | 旧版本 | 新版本 |
|---|---|---|
| Lettuce | 7.7.0.RELEASE | 7.8.0.RELEASE |
| H2 | 2.5.250 | 2.5.252 |
| Mockito | 5.23.0 | 5.24.0 |
| Netty（通过 BOM） | 4.2.13.Final | 4.2.18.Final |
| zstd-jni | 传递依赖 | 1.5.7-20 |
| lz4-java | 传递依赖 | 1.12.0 |
| snappy-java | 传递依赖 | 1.1.10.8 |
| reactor-core | 传递依赖 | 3.6.18 |

框架的 `pom.xml` 现在导入 Netty BOM，并通过 `dependencyManagement` 管理已修复的传递依赖版本，使所有 Netty 模块保持一致。

> **提示：** 如果您的应用依赖 tinystruct 并且直接声明了这些库，建议将自己的版本与上表对齐。

---

### 2. 可靠的中断处理

此前，消息队列和闹钟中被中断的线程只是记录异常后继续运行。现在它们会调用 `Thread.currentThread().interrupt()`，使线程池能够干净地关闭任务：

- 生产者循环在线程被中断后立即退出。
- 消费者循环使用 `while (!Thread.currentThread().isInterrupted())`，并在关闭时停止。
- 队列示例中的控制台 `System.out` 输出已替换为框架日志。

没有 API 变更，现有的 `DistributedMessageQueue` 用法保持不变。

---

## 迁移指南

### 更新到 1.7.35

更新 `pom.xml` 中的依赖：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.35</version>
</dependency>
```

从 1.7.34 升级无需修改源代码。

---

## 社区与资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **项目脚手架**：<https://github.com/tinystruct/tinystruct-archetype>
