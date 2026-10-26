# tinystruct 1.7.37 新特性

本文档介绍 tinystruct 1.7.37 版本的变更。这是一个安全与稳定性版本，重点在于静态文件服务访问控制、路径穿越防护以及各服务器模块的行为统一。

> 另请参阅：[1.7.36 新特性](whats-new-1.7.36.md)，其中介绍了 MCP 加固和可配置日志处理器。

---

## 1.7.37 亮点

- **静态文件服务防护**：静态文件仅限从专用的静态资源目录（`server.static.dirs` 或 `server.static.dir`，默认为 `static`）对外提供。项目根目录及源码永远不会被暴露。
- **路径穿越与别名攻击防护**：包含路径穿越序列、空字符、URL 编码穿越或 Windows NTFS 备用数据流（`::$DATA`）和尾随点号/空格别名的请求均被严格拒绝并返回 `403 Forbidden`。
- **符号链接边界校验**：文件解析后的真实路径（`toRealPath`）必须严格位于配置的静态目录下，杜绝利用软链接逃逸出静态目录。
- **HTTP 缓存与条件请求**：全面支持 `If-Modified-Since`（HTTP 304 Not Modified）、`Cache-Control` 和 `Expires` 响应头。
- **各服务器模块统一升级**：同步升级 `tinystruct-netty-http-server` (1.1.11)、`tinystruct-tomcat-server` (1.1.11) 和 `tinystruct-undertow-server` (1.1.2)，保持安全策略与行为一致。
- **日志测试强化**：新增测试套件验证 `LoggerConfigurer` 多处理器日志轮换、文件日志中 ANSI 颜色转义字符过滤以及资源正确关闭释放。

---

## 详细说明

### 1. 静态文件访问控制

在以往版本中，未命中特定静态目录时，静态资源查找可能回退到项目运行目录。1.7.37 版本引入了严格的目录白名单机制：

- 静态文件仅可从 `server.static.dirs`（逗号或分号分隔）或 `server.static.dir`（默认为 `static`）配置的目录中读取。
- 任何直接访问项目根目录文件（如 `pom.xml`、`application.properties`、`.git/config` 或 `src/` 中的源码）的请求均直接被拦截并返回 `403 Forbidden`（提示 `This request is forbidden!`）。
- 工作目录边界校验：配置的静态目录不能为工作目录本身或上层目录。

```properties
# 自定义静态资源目录（未配置时默认为 "static"）
server.static.dirs = static, public, assets
```

---

### 2. 路径穿越与 Windows 别名防护

URI 清洗与静态文件解析机制已在 `HttpServer` 以及所有服务器模块中进行了全面重构：

- **路径穿越**：任何相对段（`..` 或 `.`）、URL 编码的穿越序列（`%2e%2e`、`%2f`、`%5c`）及双斜杠均在文件查找前被拒绝。
- **非法字符**：空字符（`\0`）与冒号（`:`）立即拦截，杜绝盘符注入和 Windows NTFS 备用数据流攻击（如 `file.txt::$DATA`）。
- **尾随点与空格**：Windows 文件系统会将 `secret.txt.` 或 `secret.txt ` 规范化为 `secret.txt`。1.7.37 显式拒绝任何段带有尾随点号或空格的路径。
- **隐藏文件**：永远不会对外提供隐藏文件与隐藏文件夹（如 `.env`、`.git`）。
- **软链接安全**：在发送文件前，通过比对 `toRealPath()` 确保目标文件确实位于静态目录树内。

---

### 3. HTTP 缓存与 304 Not Modified

静态文件响应现已自动处理缓存校验：

- 发送 `Cache-Control: public, max-age=86400, must-revalidate` 与对应 `Expires` 头。
- 将请求的 `If-Modified-Since` 头与文件最后修改时间进行比对，若未修改则返回 `304 Not Modified`，不传输包体直接关闭连接。
- 自动解析 `/META-INF/mime.types` 获取 MIME 类型，若未匹配则回退到 `java.nio.file.Files.probeContentType`。

---

### 4. 服务器模块同步更新

tinystruct 旗下的所有 HTTP 服务器模块均已更新并适配全新的静态文件安全架构：

| 模块 | 版本 | tinystruct 版本 | 说明 |
| :--- | :--- | :--- | :--- |
| `tinystruct-netty-http-server` | **1.1.11** | `1.7.37` | `HttpStaticFileHandler` 遵守静态目录规范并拦截根目录下载。 |
| `tinystruct-tomcat-server` | **1.1.11** | `1.7.37` | Filter 拦截静态路由，在进入 DefaultServlet 前完成路径校验。 |
| `tinystruct-undertow-server` | **1.1.2** | `1.7.37` | 校验白名单路径，利用工作线程以阻塞流形式高效输出文件内容。 |

---

### 5. 日志测试套件增强

新增 `LoggerConfigurerTest` 针对 `LoggerConfigurer` 进行严格的行为测试：
- 多处理器配置：支持同时创建 `ConsoleHandler` 与 `FileHandler`。
- ANSI 转义符过滤：验证写入文件的日志内容不含控制台颜色转义符，而控制台仍保留彩色高亮。
- 多次初始化安全：重复调用 `LoggerConfigurer.setup()` 时会正确释放之前的文件锁，杜绝产生 `.log.1`、`.log.2` 垃圾文件。
- 容错回退：配置了不存在的 Formatter 类名时，优雅回退到内置的格式化器。

---

## 迁移指南

### 升级到 1.7.37

在 `pom.xml` 中更新依赖版本：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.37</version>
</dependency>
```

若使用了独立服务器模块，请同步升级其版本：

```xml
<!-- Netty HTTP 服务器 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-netty-http-server</artifactId>
    <version>1.1.11</version>
</dependency>

<!-- Tomcat 服务器 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-tomcat-server</artifactId>
    <version>1.1.11</version>
</dependency>

<!-- Undertow 服务器 -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-undertow-server</artifactId>
    <version>1.1.2</version>
</dependency>
```

### 静态资源放置规范

若您的应用此前将静态前端文件存放在项目根目录中，请将它们移动到 `static/` 目录下（或通过 `server.static.dirs` 自定义目录）：

```
my-project/
├── pom.xml
├── src/
└── static/               <-- 静态网页资源请放置在此处
    ├── css/
    ├── js/
    └── images/
```

---

## 社区与资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **项目原型**：<https://github.com/tinystruct/tinystruct-archetype>
