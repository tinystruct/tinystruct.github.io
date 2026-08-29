# tinystruct 1.7.29 新特性

本文档介绍了 tinystruct 1.7.29 版本中引入的新功能、安全增强、性能改进和变更。

> 另请参阅：[1.7.23 新特性](whats-new-1.7.23.md)，了解自动化 POJO 代码生成和原生 `LocalDateTime` 支持等早期功能。

---

## 1.7.29 核心亮点

- **非对称 RSA 与可配置 JWT 安全**：支持 RSA 公钥/私钥对签名与验证，并通过 `application.properties` 提供灵活配置。
- **高级 HTTP 服务器安全与主机过滤**：通过 `server.name` 限制 Host 请求头、强力防范路径遍历攻击、基于环境的错误响应脱敏以及安全 Cookie 标识。
- **解耦架构与域名独立**：移除了 `HttpServer` 和 `SSEPushManager` 中的硬编码域名依赖，完美支持多域名、容器化和本地开发环境。
- **模型上下文协议 (MCP) 与 AI 工具增强**：支持重载工具方法并自动合并入参 Schema、增加空闲会话看门狗与自动清理、增强工具异常恢复能力。
- **现代化 ANSI 控制台日志与 StackWalker 调用者追踪**：色彩鲜明的控制台日志格式化，结合零开销的精确类、方法及行号追踪。
- **可配置 HTTP 客户端超时**：为 `URLRequest` 和 `HTTPHandler` 提供精确的连接超时与读取超时配置。
- **依赖库全面升级**：升级了 SQLite JDBC (3.53.2.1)、JUnit Jupiter (6.1.1)、JNA (5.19.1) 和 Apache Kafka (4.3.1)。

---

## 主要新功能与改进

### 1. 非对称 RSA 与可配置 JWT 安全

`JWTManager` 现已全面支持对称 HMAC 密钥与非对称 RSA 公私钥对，支持企业级认证架构（例如：认证服务器使用私钥签名 Token，资源服务器使用公钥验证 Token）。

#### `JWTManager` 中的 RSA 密钥对支持：
```java
JWTManager jwtManager = new JWTManager();

// 使用 RSA 私钥签名 (Base64 PKCS#8 格式)
jwtManager.withPrivateKey(base64PrivateKey);
String token = jwtManager.createToken(builder);

// 使用 RSA 公钥验证 (Base64 X.509 格式)
jwtManager.withPublicKey(base64PublicKey);
Map<String, Object> claims = jwtManager.verify(token);
```

#### 在 `application.properties` 中声明式配置：
内置 HTTP 服务器会自动读取 JWT 配置用于 Bearer Token 验证：

```properties
# 使用 RSA 公钥验证 (Base64 X.509 格式)
jwt.key.public=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQE...

# 或使用 HMAC 密钥验证
jwt.secret=your-256-bit-secret-key-here
jwt.secret.format=plain # 'plain' 或 'base64' (默认)

# 可选的 JWT 验证时区
jwt.timezone=UTC
```

---

### 2. HTTP 服务器安全控制与主机过滤

#### Host 请求头验证 (`server.name`)：
限制只有匹配指定域名/主机名的请求才可访问，有效防范 HTTP Host 头攻击：

```properties
# 限制允许的主机名 (逗号分隔)。留空则允许所有主机访问。
server.name=localhost:8080, api.example.com, example.com
```

#### 路径遍历防护：
`HttpServer` 和 `Dispatcher` 中的静态资源路径解析采用 `Path.normalize()` 并对基础目录边界进行严格校验，杜绝任何跨目录遍历风险。

#### 安全 Cookie 与环境感知错误响应：
- HTTPS 请求下自动标记 `Secure` Cookie 属性。
- `production` 环境下自动对内部异常堆栈进行脱敏处理，而在 `system.environment=development` 时保留详细诊断信息。

---

### 3. 模型上下文协议 (MCP) 与 AI 集成提升

Model Context Protocol (MCP) 实现迎来了多项重要升级：

- **重载工具方法支持**：`MCPServer` 支持具有相同动作路径的重载方法，自动合并输入 Schema 并动态分发参数。
- **会话看门狗与空闲清理**：内置 Ping 探测机制、心跳看门狗及自动断连会话回收。
- **直接注册普通 Java 对象 (POJO)**：无需继承 `MCPTool` 即可直接将任何服务或对象注册为 AI 工具。

```java
public class CustomMCPServer extends MCPServer {
    @Override
    public void init() {
        super.init();
        // 直接注册任意普通对象
        this.registerTool(new CalculatorService());
    }
}
```

---

### 4. ANSI 控制台日志与 StackWalker 追踪

日志系统全新升级：
- **ANSI 终端色彩**：直观区分各日志级别 (INFO、WARNING、SEVERE、DEBUG)。
- **精准调用者追踪**：利用 Java 9+ `StackWalker` API 实现无开销的准确源类名、方法名和行号捕获。
- **默认 INFO 级别**：开箱即用，无需繁琐配置。

---

### 5. 可配置 HTTP 客户端超时与浏览器自动化

- **`URLRequest` 和 `HTTPHandler` 超时控制**：
  ```java
  URLRequest request = new URLRequest(new URL("https://api.example.com/data"))
          .setConnectTimeout(5000)  // 5 秒连接超时
          .setReadTimeout(10000);   // 10 秒读取超时
  ```
- **自动打开浏览器**：可通过配置 `server.openbrowser=true` 和 `server.openbrowser.command` 在启动服务时自动打开默认浏览器。

---

### 6. 依赖库升级列表

| 依赖库 | 原版本 | 新版本 (1.7.29) |
|---|---|---|
| **SQLite JDBC** | 3.45.1.0 | `3.53.2.1` |
| **JUnit Jupiter** | 5.10.2 | `6.1.1` |
| **JNA** | 5.14.0 | `5.19.1` |
| **Apache Kafka** | 3.7.0 | `4.3.1` |
| **Maven Assembly Plugin** | 2.2-beta-5 | `3.7.1` |

---

## 升级指南

### 升级至 1.7.29

在 `pom.xml` 中将 tinystruct 依赖版本更新为 `1.7.29`：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.29</version>
</dependency>
```

#### JWT Secret 配置
若在 `application.properties` 中使用明文字符串作为密钥，请指定 `jwt.secret.format=plain`：

```properties
jwt.secret=my-plain-text-secret-key
jwt.secret.format=plain
```

---

## 社区与相关资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例项目**：<https://github.com/tinystruct/tinystruct-examples>
- **项目骨架**：<https://github.com/tinystruct/tinystruct-archetype>
