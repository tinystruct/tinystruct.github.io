# tinystruct 1.7.38 新特性

本文档介绍 tinystruct 1.7.38 版本的变更。这是一个聚焦稳定性、性能与安全性的版本，涵盖了 ASM CVE 安全修复、JSON `Builder`/`Builders` 往返序列化修复、`.lock` 锁文件 I/O 加速与可配置超时、默认启用文件日志，以及多个服务器和生态组件的同步升级。

> 另请参阅：[1.7.37 新特性](whats-new-1.7.37.md)，其中介绍了静态文件服务访问控制和路径穿越防护。

---

## 1.7.38 亮点

- **安全与依赖升级**：将经由 `nashorn-core` 传递引入的 `org.ow2.asm` 系列工件（`asm`、`asm-commons`、`asm-analysis`、`asm-tree`、`asm-util`）固定为 `9.11.1` 以修复多个 ASM CVE；同时将 `reactor-core` 升级至 `3.8.8`，`sqlite-jdbc` 升级至 `3.54.1.0`。
- **JSON 往返与转义修复**：`Builder` 在序列化时会正确转义对象键名并保留形似字面量的字符串引号；`Builders` 修复了数组元素中的反斜杠转义、字符串反转义及 `Boolean` / `null` 原生类型解析。
- **锁文件 I/O 提速与超时可配置**：`Watcher` 改为单次读取 `.lock` 文件并在内存中扫描槽位、单次写入标志位，显著降低并发锁竞争；新增 `distributed.lock.timeout` 与 `distributed.lock.file.timeout` 配置项（默认 `5000` ms）。
- **并发队列、日志与应用生命周期改进**：`DistributedMessageQueue.take()` 在轮询休眠期间释放锁，避免饿死后台 `copy()` 工作线程；`LogFormatter` 改用线程安全的 `DateTimeFormatter`；`ApplicationManager.uninstall()` 会清理应用的全部匹配动作；取消 `Application.setAction(String, String)` 的 `@Deprecated` 标记以支持动态路由注册。
- **默认启用文件日志**：默认 `application.properties` 在 `ConsoleHandler` 之外同步启用 `java.util.logging.FileHandler`，日志按 5 个 × 10 MB 滚动写入 `logs/tinystruct-%g.log`。
- **服务器与生态组件同步升级**：同步发布 `tinystruct-netty-http-server` (`1.1.12`)、`tinystruct-tomcat-server` (`1.1.12`)、`tinystruct-undertow-server` (`1.1.3`)、`tinystruct-workflow` (`1.0.3`) 以及 `tinystruct-typesafe` (`1.0.1`)。

---

## 详细说明

### 1. 安全与依赖升级

`pom.xml` 中新增或升级的依赖管理与直接依赖：

| 依赖 | 旧版本 | 新版本 | 说明 |
| :--- | :--- | :--- | :--- |
| `org.ow2.asm:asm*`（`asm`、`-commons`、`-analysis`、`-tree`、`-util`） | `7.3.1`（随 `nashorn-core 15.7` 传递引入） | **`9.11.1`** | 通过 `${asm.version}` 统一锁定，修复 `CVE-2026-110257/58/60/61/63` 与 `CVE-2026-110591` |
| `io.projectreactor:reactor-core` | `3.6.18` | **`3.8.8`** | 依赖管理中的传递安全升级 |
| `org.xerial:sqlite-jdbc` | `3.53.4.0` | **`3.54.1.0`** | SQLite JDBC 驱动升级 |

> **提示：** 如果您的项目显式声明了 ASM 或 Reactor，建议将版本号与上表保持一致。

---

### 2. JSON `Builder` / `Builders` 往返与转义修复

`org.tinystruct.data.component.Builder` 和 `Builders` 现在能够在解析与序列化往返之间准确保留结构、转义字符与数据类型：

- **对象键名转义**：由于解析器会对键名做反转义，`Builder.toString()` 现使用 `StringUtilities.escape(...)` 对包含引号、反斜杠或控制字符的键名（例如 `"C:\\dir"`、`"say \"hi\""`）进行对称转义。
- **保持字符串原始类型**：单值 `Builder` 直接按存储值输出字符串并保留引号，不再把 `"true"`、`"false"`、`"null"` 或 `"123"` 当作非引号字面量重新解析。
- **数组原生字面量与反转义**：`Builders` 将未加引号的 `true`、`false`、`null` 数组元素解析为 `Boolean` 或 `null`（`Builder.ofNull()`）而非字符串；正确跳过字符串内的转义字符并还原数组字符串元素的转义内容。

```java
// 混合字面量与形似字面量的字符串在 parse -> toString() 往返后保持不变
String json = "[true,false,null,1,\"true\",\"1\"]";
Builders array = new Builders();
array.parse(json);
assert json.equals(array.toString());

// 包含引号、反斜杠或换行符的对象键名可无损往返
Builder obj = new Builder().put("C:\\dir\\", "v");
Builder reparsed = new Builder();
reparsed.parse(obj.toString());
assert "v".equals(reparsed.get("C:\\dir\\"));
```

---

### 3. 锁文件 I/O 优化与超时配置

针对高并发下使用 `DistributedHashMap` 和 `Watcher` 的场景进行了性能和可配置性优化：

- **单次读取 `.lock` 扫描**：`Watcher` 将原先逐槽位的小字节读取改造为一次性通过 `FileChannel` 读取全部槽位到内存扫描，并直接定位写入单个槽位标志。含 `90` 个残留槽位的锁文件下，单次加解锁周期中位耗时从 `15.5 ms` 降至 `6.4 ms`，磁盘格式（`36` 字节 ID + `8` 字节标志位）保持向后兼容。
- **锁等待超时可配置**：此前硬编码的 `5000 ms` 等待时间现通过 `LockSettings` 读取 `application.properties`（无效或非正数将记录警告并回退至 `5000`）：

```properties
# 分布式锁超时设置（毫秒，默认 5000）
distributed.lock.timeout=5000
distributed.lock.file.timeout=5000
```

- **显式超时构造方法**：`DistributedHashMap` 新增 `new DistributedHashMap(dataFilePath, lockTimeoutMs)` 构造方法，便于按实例指定锁等待超时。

---

### 4. 并发队列、日志与生命周期改进

- **消除队列锁饥饿**：`DistributedMessageQueue.take(String)` 对未注册会话直接返回 `"{}"`，并在每次 `1 ms` 轮询休眠之间释放 `lock`，避免持续占用锁导致后台 `copy()` 工作线程饥饿。
- **线程安全的 `LogFormatter`**：使用共享不可变的 `DateTimeFormatter` 替换原有的非线程安全 `SimpleDateFormat` 实例字段。
- **默认启用文件日志**：默认 `application.properties` 现同时启用控制台与滚动文件日志处理器：

```properties
handlers = java.util.logging.ConsoleHandler, java.util.logging.FileHandler
```

- **`ApplicationManager` 与动态路由**：
  - `ApplicationManager.uninstall(Application)` 现在会移除目标应用注册的全部匹配动作（支持同路径不同 HTTP Method），不再在移除首个匹配后提前返回。
  - `ApplicationManager.init()` 无论 `default.import.applications` 是否配置都会正确标记 `initialized = true`。
  - `Application.setAction(String, String)` 移除 `@Deprecated` 注解，继续支持运行时动态注册动作路由。

---

### 5. 服务器与生态组件同步更新

以下 tinystruct HTTP 服务器模块与生态扩展已基于 `tinystruct 1.7.38` 完成升级与依赖更新并发布：

| 模块 | 版本 | tinystruct 版本 | 说明 |
| :--- | :--- | :--- | :--- |
| [`tinystruct-netty-http-server`](https://github.com/tinystruct/tinystruct-netty-http-server) | **1.1.12** | `1.7.38` | 适配 `1.7.38`；将 Netty 升级至 `4.2.20.Final`，`netty-tcnative` 升级至 `2.0.85.Final`。 |
| [`tinystruct-tomcat-server`](https://github.com/tinystruct/tinystruct-tomcat-server) | **1.1.12** | `1.7.38` | 适配 `1.7.38`，配套嵌入式 Tomcat `11.0.27` 与 `jakarta.servlet-api` `6.1.0`。 |
| [`tinystruct-undertow-server`](https://github.com/tinystruct/tinystruct-undertow-server) | **1.1.3** | `1.7.38` | 适配 `1.7.38`，配套 Undertow `2.4.4.Final`、XNIO `3.8.17.Final` 与 `jboss-logging` `3.6.3.Final`。 |
| [`tinystruct-workflow`](https://github.com/tinystruct/tinystruct-workflow) | **1.0.3** | `1.7.38` | 适配 `1.7.38`；将 Lettuce 升级至 `7.9.0.RELEASE` 并更新 Maven 构建插件。 |
| [`tinystruct-typesafe`](https://github.com/tinystruct/tinystruct-typesafe) | **1.0.1** | `1.7.38` | 面向 `@Action` 的自然语言语义调度器，适配 `tinystruct 1.7.38` 与 `tinystruct-workflow` `1.0.3`；升级 Lettuce (`7.9.0.RELEASE`)，包含待确认调用列表 (`semantic/pending` / `PendingSummary`) 与过期快照清理器。 |

---

## 迁移指南

### 升级到 1.7.38

在 `pom.xml` 中更新核心框架版本：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.38</version>
</dependency>
```

若您的项目使用了对应的服务器或生态组件，请同步升级其版本：

```xml
<!-- HTTP 服务器模块 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-netty-http-server</artifactId>
    <version>1.1.12</version>
</dependency>

<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-tomcat-server</artifactId>
    <version>1.1.12</version>
</dependency>

<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-undertow-server</artifactId>
    <version>1.1.3</version>
</dependency>

<!-- 工作流引擎 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-workflow</artifactId>
    <version>1.0.3</version>
</dependency>

<!-- TypeSafe 自然语言语义调度器 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-typesafe-core</artifactId>
    <version>1.0.1</version>
</dependency>
```

### 从 1.7.37 升级注意事项

- **JSON 数组字面量类型**：JSON 数组中未加引号的 `true`、`false`、`null` 现在会解析为原生 `Boolean` 和 `null`（`Builder.getValue()` 返回对应类型，而带引号的 `"true"`、`"null"` 仍保持为 `String`）。若现有调用方假定数组元素一律为 `String`，请检查相关类型转换。
- **默认文件日志**：框架自带的默认 `application.properties` 现已默认启用 `java.util.logging.FileHandler`，运行后会在工作目录下生成 `logs/tinystruct-%g.log`。如仅需控制台输出，请在项目配置中覆盖为 `handlers = java.util.logging.ConsoleHandler`。
- **分布式锁超时**：如多进程并发竞争较重，可在 `application.properties` 中调整 `distributed.lock.timeout` 与 `distributed.lock.file.timeout`（单位毫秒，默认 `5000`）。

---

## 社区与资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **项目原型**：<https://github.com/tinystruct/tinystruct-archetype>
