# tinystruct 1.7.19 新特性

本文档重点介绍了 tinystruct 1.7.19 版本中引入的新特性、改进和变更。

## 主要新特性

### 1. 特定 HTTP 方法的 Action

您现在可以指定 Action 响应哪些 HTTP 方法，从而实现恰当的 RESTful API 设计：

```java
@Action(value = "users", mode = Mode.HTTP_GET)
public String getUsers() {
    return userService.findAll().toString();
}

@Action(value = "users", mode = Mode.HTTP_POST)
public String createUser(Request request) {
    String name = request.getParameter("name");
    return userService.create(name).toString();
}

@Action(value = "users", mode = Mode.HTTP_PUT)
public String updateUser(Integer id, Request request) {
    String name = request.getParameter("name");
    return userService.update(id, name).toString();
}

@Action(value = "users", mode = Mode.HTTP_DELETE)
public String deleteUser(Integer id) {
    userService.delete(id);
    return "User deleted";
}
```

**可用的 HTTP 方法模式：**
- `Mode.HTTP_GET`
- `Mode.HTTP_POST`
- `Mode.HTTP_PUT`
- `Mode.HTTP_DELETE`
- `Mode.HTTP_PATCH`
- `Mode.HTTP_HEAD`
- `Mode.HTTP_OPTIONS`

### 2. AI 集成和 MCP 支持

内置对利用模型上下文协议（MCP）集成 AI 的支持：

```properties
# config.properties 中的 MCP 配置
mcp.auth.token=your_token_here
```

**优势：**
- 轻松集成 AI 模型
- 标准化的模型通信协议
- 用于 AI 扩展的插件式架构
- 支持自定义 AI 提供商

**AI 集成示例：**

```java
@Action("ai/chat")
public String chat(String message) {
    // 使用 MCP 与 AI 模型通信
    return aiService.chat(message);
}
```

### 3. 服务器发送事件（SSE）支持

提供原生的 Server-Sent Events（服务器发送事件）支持，用于实时数据流：

```java
@Action(value = "stream", mode = Mode.HTTP_GET)
public void streamData(Request request, Response response) {
    response.setHeader("Content-Type", "text/event-stream");
    response.setHeader("Cache-Control", "no-cache");
    
    // 传输实时数据流
    while (shouldContinue()) {
        String data = getLatestData();
        response.write("data: " + data + "\n\n");
        response.flush();
        Thread.sleep(1000);
    }
}
```

**用例：**
- 实时通知
- 实时数据推送
- 进度更新
- 聊天应用
- 股票行情看板

### 4. 增强的插件架构

针对基于插件的应用程序改进了模块化设计：

```java
// Plugin 接口
public interface Plugin {
    void initialize(Application app);
    void start();
    void stop();
}

// Plugin 实现
public class MyPlugin implements Plugin {
    @Override
    public void initialize(Application app) {
        // 插件初始化
    }
}
```

**优势：**
- 动态插件加载
- 热插拔组件
- 可扩展架构
- 隔离的插件上下文

### 5. 多服务器支持

增强了对多个 HTTP 服务器的支持并改进了性能：

**Netty 服务器（推荐）**
```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```
- 86,000+ 请求/秒
- 异步 I/O
- WebSocket 支持
- SSE 支持

**Tomcat 服务器**
```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```
- 传统的 servlet 支持
- JSP 支持
- 企业级兼容性

**Undertow 服务器**
```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```
- 轻量级占用
- 非阻塞 I/O
- 易于嵌入

## 性能改进

### 基准测试结果

1.7.19 版本实现了卓越的性能：

```
Running 30s test @ http://127.0.0.1:8080/?q=say/Praise the Lord!
12 threads and 400 connections

Thread Stats   Avg      Stdev     Max       +/- Stdev
Latency        17.44ms  33.42ms   377.73ms  88.98%
Req/Sec        7.27k    1.66k     13.55k    69.94%

2,604,473 requests in 30.02s, 524.09MB read

Requests/sec:  86,753.98
Transfer/sec:  17.46MB
```

**关键指标：**
- **吞吐量**: 86,753 请求/秒
- **延迟**: 平均 17.44ms
- **一致性**: 88.98% 在一个标准差内
- **内存占用**: 30秒内 524MB（17.46MB/秒）

### 性能优化

1. **零开销架构**
   - 没有基于反射的 bean 扫描
   - 直接的方法调用
   - 极简的拦截器链

2. **高效的内存管理**
   - 内存占用小
   - 没有过度的对象创建
   - 优化的垃圾回收

3. **智能路由**
   - 预编译的模式匹配
   - 快速 URL 解析
   - 缓存的路由解析

## 架构提升

### 1. 无需 main() 方法

启动应用程序直接无需 main() 方法：

```java
// 不需要 main() 方法！
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 只有初始化代码
    }
}
```

**使用 CLI 启动：**
```bash
bin/dispatcher start --import com.example.MyApp
```

### 2. 统一的 CLI 和 Web 设计

相同的代码在 CLI 和 Web 上都能运行：

```java
@Action(value = "greet", mode = Mode.ALL)
public String greet(String name) {
    return "Hello, " + name + "!";
}

// CLI: bin/dispatcher greet/John
// Web: http://localhost:8080/?q=greet/John
```

### 3. 模块化设计

清晰的关注点分离：

```
应用层 Application Layer
    ↓
操作层 Action Layer (路由/命令)
    ↓
服务层 Service Layer (业务逻辑)
    ↓
存储层 Repository Layer (数据访问)
    ↓
数据库层 Database Layer
```

## API 改进

### 增强的 Builder API

使用 Builder 类改进了 JSON 的构建：

```java
Builder builder = new Builder();
builder.put("success", true);
builder.put("data", dataObject);
builder.put("timestamp", System.currentTimeMillis());

// 嵌套对象
Builder nested = new Builder();
nested.put("id", 123);
nested.put("name", "John");
builder.put("user", nested);

// 数组
Builders array = new Builders();
array.add("item1");
array.add("item2");
builder.put("items", array);

String json = builder.toString();
```

### 改进的 DatabaseOperator

使用更好的资源管理增强了数据库操作：

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // 资源会自动清理
    ResultSet results = operator.query("SELECT * FROM users");
    // 处理结果
} // 资源自动关闭
```

## 破坏性变更

### 无

1.7.19 版本向后兼容以前的 1.8.x 版本。所有现有代码无需修改即可继续运行。

## 迁移指南

### 从 1.7.15 迁移至 1.7.19

1. **更新 Maven 依赖**
   ```xml
   <dependency>
       <groupId>org.tinystruct</groupId>
       <artifactId>tinystruct</artifactId>
       <version>1.7.19</version>
   </dependency>
   ```

2. **可选：使用新的特定 HTTP 方法的 Action**
   ```java
   // 以前的做法（仍然有效）
   @Action("users")
   public String getUsers() { ... }
   
   // 新的做法（推荐用于 RESTful API）
   @Action(value = "users", mode = Mode.HTTP_GET)
   public String getUsers() { ... }
   ```

3. **可选：添加 MCP 配置**
   ```properties
   # config.properties
   mcp.auth.token=your_token_here
   ```

## 社区与资源

- **GitHub**: <https://github.com/tinystruct/tinystruct>
- **文档**: <https://tinystruct.org>
- **示例项目**: <https://github.com/tinystruct/tinystruct-examples>
- **项目骨架**: <https://github.com/tinystruct/tinystruct-archetype>
- **Smalltalk (AI 聊天)**: <https://github.com/tinystruct/smalltalk>

## 下一步

### 未来版本计划

- 增强响应式编程支持
- GraphQL 集成
- gRPC 支持
- Kubernetes 原生特性
- 增强监控和指标
- WebAssembly 支持

## 总结

1.7.19 版本代表了 tinystruct 框架向前迈出的重要一步，增加了特定 HTTP 方法的 Action、AI 集成和 SSE 支持等现代功能，同时保留了框架核心的简单性、性能和易用性理念。

该框架在保持轻量和对开发者友好的同时，继续提供卓越的性能（超过 86,000 请求/秒）。无需 main() 方法以及统一的 CLI/Web 支持，tinystruct 使得 Java 应用程序的开发变得更快、更令人愉悦。

马上来体验不同之处吧！
