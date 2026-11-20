# tinystruct 1.7.39 新特性

本文档介绍 tinystruct 1.7.39 版本的变更。这是一个聚焦安全性、稳定性与跨平台便携性的重要版本，引入了全新的 `TokenGuard` 预认证 Token 校验引擎、精确的 HTTP 与 MCP 状态码映射、模板引擎跨平台路径与语言环境修复、ClassLoader 层级回退解析，以及核心 DOM 与连接管理器的缺陷修复。

> 另请参阅：[1.7.38 新特性](whats-new-1.7.38.md)，其中介绍了 ASM CVE 安全修复、JSON 往返序列化修复与锁文件 I/O 提速。

---

## 1.7.39 亮点

- **TokenGuard 预认证防御体系**：新增 `org.tinystruct.http.security.TokenGuard`，为全框架提供前置、轻量的 Token 安全校验。支持最大长度限制（默认 `4096` 字符）、空白与非法控制字符过滤、严格的 Base64 填充语法校验以及 RFC 7515/7519 紧凑型 JWT 结构校验，在执行昂贵的高开销密码学验证之前提前拦截恶意或畸形输入。
- **ReDoS 防护与步数预算机制**：Token 黑名单正则匹配采用步数受限的 `CharSequence` 进行评估（上限 50,000 次字符读取），彻底阻断灾难性回溯导致的正则表达式拒绝服务攻击（ReDoS），超额时安全闭锁（fail-closed）。
- **HTTP 与 MCP 安全状态码映射**：`HttpServer` 与 `AuthorizationHandler` 深度集成 `TokenGuard`。`HttpServer` 将校验与解析结果精准映射为 HTTP 响应状态码：畸形或超长 Token 返回 `400 Bad Request`，签名错误或凭证过期返回 `401 Unauthorized`，策略拦截返回 `403 Forbidden`。`AuthorizationHandler` 支持规范解析 `Bearer ` 头部，避免误判空格。
- **模板引擎跨平台路径一致性**：`AbstractApplication.toString()` 将模板路径拼接统一规范为 `/`，替代平台相关的 `File.separatorChar`，保证模板在 Windows 环境及可执行 JAR 包内部均能正确加载。
- **多语言环境解析与 ClassLoader 回退链**：移除了 `AbstractApplication` 中硬编码的 `Locale.CHINA` 比较，使所有配置的语言环境均能正确匹配对应模板；在 `getResourceAsStream` 中实现了线程上下文类加载器、应用类加载器与系统类加载器的三级回退查找。
- **资源泄漏防护**：`AbstractApplication` 中的模板输入流读取改为 try-with-resources 模式，杜绝异常情况下的输入流泄漏。
- **DOM 与核心稳定性修复**：修复 `Element.removeElement(String)` 遍历子节点未推进索引导致的死循环；`Document.load(...)` 解析异常时直接保留原始 `IOException` 异常原因；`ConnectionManager` 安全解析未提供密码的 URI 用户凭据；`AbstractApplication.setLocale(...)` 支持 1、2 或 3 段式的 Locale 格式解析。

---

## 详细说明

### 1. TokenGuard 预认证防御体系

在 1.7.39 之前，非法或恶意构造的认证 Token 会直接传递给底层的密码学解析器（如 JJWT），这在遇到超长内容、深层嵌套或畸形数据时可能会消耗大量 CPU 资源甚至引发内存溢出。

`org.tinystruct.http.security.TokenGuard` 提供了独立、轻量的预认证校验层：

- **超长 Token 防护**：严格限制 Token 字符长度（默认 `4096` 字符，通过 `security.token.guard.max-length` 可调）。在进入密码学解析前，以亚毫秒级速度拒绝超长输入，有效防止缓冲区消耗与 DoS 攻击。
- **控制字符与空白过滤**：去除两端空格，并拒绝包含换行符（`\r`、`\n`）、制表符、空字节或非打印 ASCII 控制字符（`< 0x20` 或 `0x7F`）的输入。
- **Base64 填充语法校验**：严格校验 Base64 的 `=` 填充字符只能出现在数据末尾、最多允许 2 个填充字符，且存在填充时整个字符串长度必须为 4 的整数倍。
- **RFC 7515/7519 紧凑型 JWT 校验**：针对 JWT 凭据，验证其是否包含恰好 2 个 `.` 分隔符将内容划分为 3 个非空 Base64URL 片段（`header.payload.signature`），并在解码前检查非法字符。
- **日志安全脱敏**：提供 `TokenGuard.mask(token)` 工具方法，在日志记录时自动脱敏敏感凭据（如 `eyJ...abc [len=142]`），杜绝密钥外泄风险。

```java
// 创建并自定义 TokenGuard
TokenGuard guard = new TokenGuard();
guard.setMaxLength(2048);
guard.setPatternDetection(true);
guard.setBlockPatterns("^revoked-.*,.*malicious.*");

// 在昂贵的密码学验签前执行校验
TokenGuard.ValidationResult result = guard.validate(rawToken, TokenGuard.TokenType.JWT);
if (!result.isValid()) {
    // 状态包括：INVALID_FORMAT、OVERSIZED、MALFORMED、BLOCKED
    logger.warning("Token 校验未通过: " + result.getStatus() + " - " + result.getMessage());
}

// 绑定到 JWTManager
JWTManager jwtManager = new JWTManager().withTokenGuard(guard);
```

---

### 2. ReDoS 防护与步数预算机制

当启用 Token 模式检测（`security.token.guard.pattern-detection=true`）时，TokenGuard 会依据配置的黑名单正则规则（`security.token.guard.block-patterns`）进行匹配。

为防止复杂或恶意正则引发灾难性回溯（ReDoS），`TokenGuard` 采用了带有步数预算的 `BudgetedCharSequence`，将匹配过程中的字符读取上限硬性锁定为 **50,000 次**：

- 若正则回溯消耗的字符读取次数超出预算，将直接抛出内部预算异常。
- 校验机制立即安全闭锁（fail-closed），返回 `TokenGuard.Status.BLOCKED`，确保无论输入多么极端，校验时间始终稳定在 1 毫秒以内。

```java
// 正则步数预算避免回溯攻击耗尽线程池
tokenGuard.setPatternDetection(true);
tokenGuard.setBlockPatterns("a*a*a*a*a*b");

// 灾难性回溯输入会在步数用尽后快速失败并闭锁拦截
TokenGuard.ValidationResult result = tokenGuard.validate("aaaaaaaaaaaaaaaaaaaaaaaaa", TokenGuard.TokenType.GENERIC);
assert TokenGuard.Status.BLOCKED == result.getStatus();
```

---

### 3. HTTP 与 MCP 安全状态码映射

`HttpServer` 与 MCP `AuthorizationHandler` 现已全面整合 `TokenGuard`，能够按失败原因返回明确的 HTTP 响应状态码：

| 状态码 | 含义 | 触发条件 |
| :--- | :--- | :--- |
| **`400 Bad Request`** | 请求语法或格式错误 | Token 超长、包含控制字符、Base64 填充非法或 JWT 结构损坏 |
| **`401 Unauthorized`** | 认证失败 | Token 签名无效、凭证已过期或服务端未配置 JWT 密钥 |
| **`403 Forbidden`** | 策略拦截 | Token 命中配置的 `security.token.guard.block-patterns` 黑名单规则 |

在 MCP `AuthorizationHandler` 中：
- 规范兼容可选的 `Bearer ` 前缀，并在提取有效凭证后再执行校验，防止常规的授权协议头空格被错误识别为非法字符。
- 畸形或超长凭证直接在内存比对前快速失败。

---

### 4. 模板引擎跨平台路径与 ClassLoader 优化

- **统一跨平台路径分隔符**：`AbstractApplication.toString()` 中模板路径的拼接由原先的 `File.separatorChar` 改为统一的 `/`。在 Windows 系统上，原本生成的反斜杠路径 `\` 无法在 JAR 包内部虚拟文件系统正确寻址，此改动确保跨平台行为完全一致。
- **语言环境解析修复**：移除了 `AbstractApplication` 中硬编码的 `Locale.CHINA` 引用，修复了非中文环境下本地化模板无法正确加载的问题。
- **三级类加载器回退**：`AbstractApplication.getResourceAsStream(...)` 实现了健壮的类加载器查找顺序：
  1. 线程上下文类加载器：`Thread.currentThread().getContextClassLoader()`
  2. 当前类加载器：`AbstractApplication.class.getClassLoader()`
  3. 系统类加载器：`ClassLoader.getSystemClassLoader()`
- **防止流泄漏**：模板文件的读取均纳入 `try-with-resources` 管理，保证输入流在异常时能正常关闭。

---

### 5. DOM、数据与核心缺陷修复

- **`Element.removeElement(String)` 死循环修复**：修复了在按名称移除 XML / DOM 子节点时循环索引未推进的问题。
- **`Document.load(...)` 异常原因保留**：XML 文档解析失败时，包装并保留原始 `IOException`，避免以往因 `e.getCause()` 为 `null` 而丢失底层关键错误信息。
- **`ConnectionManager` 用户信息安全解析**：当 URI 中仅提供用户名而无冒号或密码时（如 `user@host`），避免数组越界异常。
- **多段式 Locale 解析**：`AbstractApplication.setLocale(String)` 现能安全兼容 1 段、2 段或 3 段式的 Locale 格式（如 `en`、`zh_CN`、`zh_CN_POSIX`）。

---

### 6. 配置项参考

`application.properties` 中新增的配置项：

| 配置项 | 说明 | 默认值 |
| :--- | :--- | :--- |
| `security.token.guard.enabled` | 是否启用预认证 Token 校验防护 (`TokenGuard`) | `true` |
| `security.token.guard.max-length` | Token 允许的最大字符长度 | `4096` |
| `security.token.guard.reject-malformed` | 是否拒绝非法 Base64 填充、控制字符及畸形 JWT 结构 | `true` |
| `security.token.guard.pattern-detection` | 是否启用正则黑名单匹配 | `false` |
| `security.token.guard.block-patterns` | 逗号分隔的 Token 拦截正则列表 | _(空)_ |

`application.properties` 配置示例：

```properties
# TokenGuard 安全校验配置
security.token.guard.enabled=true
security.token.guard.max-length=4096
security.token.guard.reject-malformed=true
security.token.guard.pattern-detection=false
security.token.guard.block-patterns=
```

---

## 升级指引

### 升级到 1.7.39

在项目的 `pom.xml` 中将版本更新为：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.39</version>
</dependency>
```

### 从 1.7.38 升级的注意事项

- **预校验返回状态码变化**：结构严重破损或填充错误的 Token 请求以往可能会返回 `401 Unauthorized`，现在会返回 `400 Bad Request`。若客户端有严格的状态码断言，请留意配合调整。
- **Token 长度上限**：若业务系统中存在承载超大载荷或深层权限集的 JWT（长度超过 4 KB），请在 `application.properties` 中适当调大 `security.token.guard.max-length`。
- **模板路径分隔符**：如果项目自定义了依赖 Windows 反斜杠的模板加载逻辑，请统一调整为正斜杠 `/`。

---

## 社区与资源

- **GitHub 仓库**：<https://github.com/tinystruct/tinystruct>
- **官方文档**：<https://tinystruct.org>
- **示例**：<https://github.com/tinystruct/tinystruct-examples>
- **项目原型**：<https://github.com/tinystruct/tinystruct-archetype>
