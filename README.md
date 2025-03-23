# tinystruct 框架详解

## 目录
- [简介](#简介)
- [核心特性](#核心特性)
- [Action 机制](#action-机制)
- [服务器实现](#服务器实现)
- [模块化设计](#模块化设计)
- [事件驱动机制](#事件驱动机制)
- [上下文与参数处理](#上下文与参数处理)
- [部署模式](#部署模式)
- [应用示例](#应用示例)
- [配置参考](#配置参考)

## 简介

tinystruct 是一个轻量级 Java 应用框架，设计用于构建从命令行工具到 Web 应用的各种应用程序。它的核心理念是"编写一次，随处运行"，通过统一的 Action 机制实现命令行和 Web 环境下的代码复用。

框架特别适合资源受限环境，提供了模块化设计、事件驱动机制和灵活的部署选项，使开发者能够构建高效、可扩展的应用。

## 核心特性

### 统一的方法调用机制

tinystruct 通过 `@Action` 注解实现了方法的动态调用，支持同一方法同时作为命令行工具和 Web 服务：

```
public class UserAction extends AbstractApplication {

    @Action("users")
    public String getUser(String id) {
        return "User ID: " + id;
    }
    
    @Override
    public void init() {
        // ... existing code ...
    }
}

// 命令行调用: bin/dispatcher users/123
// HTTP调用: GET /users/123
```

### 低延迟服务调用

框架支持服务间直接方法调用，避免了传统微服务架构中的网络开销：

```
// 服务A调用服务B
Application serviceB = ApplicationManager.get("ServiceB");
return (String) serviceB.invoke("transform-data", new Object[]{input});
```

### 轻量级设计

框架核心非常轻量，适合资源受限环境：
- 核心库体积小，无外部依赖
- 启动迅速，内存占用低（典型场景下<50MB）
- 支持按需加载组件，最小化资源占用

### 灵活的部署选项

支持多种部署策略：
- 单一JVM中运行多个模块（单体模式）
- 每个模块独立部署（微服务模式）
- 按业务关联度组合部署（混合模式）

## Action 机制

Action 是 tinystruct 框架的核心概念，它通过注解将 Java 方法暴露为可调用的动作。

### 基本用法

```
@Action("say")
public String say(String words) {
return words;
}

// 支持方法重载
@Action("say")
public String say() throws ApplicationException {
if (null != getContext().getAttribute("--words"))
return getContext().getAttribute("--words").toString();

    throw new ApplicationException("Could not find the parameter <i>--words</i>.");
}
```

### 命令行参数与路径参数

Action 支持通过命令行路径参数传递值：

```
@Action("users")
public String getUser(String id) {
return "User ID: " + id;
}

// 命令行调用: bin/dispatcher users/123
// 此时 id 参数值为 "123"
```

Action 也支持通过 `@Argument` 注解定义命令行参数：

```
@Action(value = "start", description = "Start a Tomcat server.", options = {
@Argument(key = "server-port", description = "Server port"),
@Argument(key = "http.proxyHost", description = "Proxy host for http")
}, example = "bin/dispatcher start --import org.tinystruct.system.TomcatServer --server-port 777",
mode = org.tinystruct.application.Action.Mode.CLI)
public void start() throws ApplicationException {
// ...
}
```

### 执行模式

Action 支持不同的执行模式，可以限制方法只在特定环境中可用：

```
// 只在Web环境中可用
@Action(value = "web-only", mode = Action.Mode.Web)
public String webOnly() { ... }

// 只在命令行环境中可用
@Action(value = "cli-only", mode = Action.Mode.CLI)
public String cliOnly() { ... }

// 两种环境都可用
@Action(value = "both", mode = Action.Mode.All)
public String both() { ... }
```

## 服务器实现

tinystruct 框架提供了多种服务器实现，包括 TomcatServer 和 NettyHttpServer。

### 服务器启动

```
# 使用Tomcat服务器
bin/dispatcher start --import org.tinystruct.system.TomcatServer --server-port 8080

# 使用Netty服务器
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --server-port 8080
```

### TomcatServer

基于 Apache Tomcat 实现，提供了成熟稳定的服务器环境：

```
public class TomcatServer extends AbstractApplication implements Bootstrap {

    @Action(value = "start", description = "Start a Tomcat server.", 
            options = { /* ... */ }, 
            example = "bin/dispatcher start --import org.tinystruct.system.TomcatServer --server-port 777", 
            mode = org.tinystruct.application.Action.Mode.CLI)
    @Override
    public void start() throws ApplicationException {
        // 服务器启动逻辑...
    }
}
```

特点：
- 基于成熟的 Tomcat 容器
- 支持 Servlet 规范
- 提供完整的 Web 容器功能
- 适合传统 Java Web 应用

### NettyHttpServer

基于 Netty 框架实现，提供高性能的异步非阻塞服务器：

```
public class NettyHttpServer extends AbstractApplication implements Bootstrap {

    @Action(value = "start", description = "Start up the netty-based http server.", 
            options = { /* ... */ }, 
            example = "bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --server-port 777", 
            mode = org.tinystruct.application.Action.Mode.CLI)
    @Override
    public void start() throws ApplicationException {
        // 服务器启动逻辑...
    }
}
```

特点：
- 基于高性能的 Netty 框架
- 支持异步非阻塞 I/O
- 自动检测并使用 Epoll（在 Linux 上）
- 适合高并发、低延迟场景
- 支持 SSL/TLS

### 服务器选择指南

1. **TomcatServer 适用场景**：
   - 传统 Java Web 应用
   - 需要完整 Servlet 容器支持
   - 稳定性优先于性能
   - 与现有 Servlet 应用集成

2. **NettyHttpServer 适用场景**：
   - 高性能、低延迟要求
   - 微服务和 API 服务
   - 资源受限环境（如嵌入式设备）
   - 高并发应用
   - 长连接和 WebSocket 应用

## 模块化设计

tinystruct 支持模块化设计，允许应用被分解为可独立开发、测试和部署的模块。

### 模块导入

可以通过配置文件或命令行参数导入模块：

```
# application.properties
default.import.applications=org.example.UserModule;org.example.ProductModule
default.apps.package=org.example.modules
```

```
# 命令行导入
bin/dispatcher start --import org.example.UserModule --import org.example.ProductModule
```

### 动态模块管理

支持在运行时动态加载和卸载模块：

```
public class ModuleManager extends AbstractApplication {

    @Action("install-module")
    public String installModule(String className) {
        // 动态加载并安装模块...
    }
    
    @Action("uninstall-module")
    public String uninstallModule(String name) {
        // 卸载模块...
    }
}
```

## 事件驱动机制

tinystruct 提供了事件驱动编程模型，支持应用间松耦合通信。

### 事件定义

```
class DataChangeEvent implements Event<String> {
private final String data;

    public DataChangeEvent(String data) {
        this.data = data;
    }
    
    @Override
    public String getName() {
        return "DataChange";
    }
    
    @Override
    public String getPayload() {
        return data;
    }
}
```

### 事件处理

```
public class EventDrivenApp extends AbstractApplication {

    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();
    
    static {
        // 注册事件处理器
        dispatcher.registerHandler(DataChangeEvent.class, event -> {
            System.out.println("Data changed: " + event.getPayload());
        });
    }
    
    @Action("update-data")
    public String updateData(String data) {
        // 触发数据变更事件
        dispatcher.dispatch(new DataChangeEvent(data));
        return "Data updated";
    }
}
```

## 上下文与参数处理

tinystruct 提供了强大的上下文处理能力，支持命令行参数和 Web 请求参数的统一访问。

### 参数获取

```
@Action("process")
public String process() throws ApplicationException {
// 从上下文获取命令行参数
if (null != getContext().getAttribute("--data")) {
String data = getContext().getAttribute("--data").toString();
return processData(data);
}

    throw new ApplicationException("Missing required parameter: --data");
}
```

### HTTP 请求/响应访问

```
@Action("error")
public Object exceptionCaught() throws ApplicationException {
Request request = (Request) getContext().getAttribute(HTTP_REQUEST);
Response response = (Response) getContext().getAttribute(HTTP_RESPONSE);

    // 处理请求和响应...
}
```

## 部署模式

tinystruct 支持多种部署模式，适应不同的应用场景。

### 单体模式

所有模块在同一进程中运行：

```
bin/dispatcher start --import org.example.ModuleA --import org.example.ModuleB --import org.example.ModuleC
```

### 微服务模式

每个模块独立运行：

```
# 终端1
bin/dispatcher start --import org.example.ModuleA --server-port 8081
# 终端2
bin/dispatcher start --import org.example.ModuleB --server-port 8082
```

### 混合模式

按业务关联度组合部署：

```
# 终端1
bin/dispatcher start --import org.example.ModuleA --import org.example.ModuleB --server-port 8081
# 终端2
bin/dispatcher start --import org.example.ModuleC --server-port 8082
```

## 应用示例

### 基本应用

```
public class ExampleApp extends AbstractApplication {

    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();

    static {
        dispatcher.registerHandler(InitEvent.class, handler -> 
            System.out.println(handler.getPayload()));
    }

    @Override
    public void init() {
        // 初始化时触发事件
        dispatcher.dispatch(new InitEvent());
    }

    @Action("praise")
    public String praise() {
        return "Praise the Lord!";
    }

    @Action("say")
    public String say() throws ApplicationException {
        if (null != getContext().getAttribute("--words"))
            return getContext().getAttribute("--words").toString();

        throw new ApplicationException("Could not find the parameter <i>--words</i>.");
    }

    @Action("say")
    public String say(String words) {
        return words;
    }

    @Override
    public String version() {
        return "1.0";
    }
}

// 自定义事件
class InitEvent implements Event<String> {

    @Override
    public String getName() {
        return "Initialize";
    }

    @Override
    public String getPayload() {
        return "The app started at " + new SimpleDateFormat().format(new Date());
    }
}
```

### 命令行调用

```
# 基本调用
bin/dispatcher praise --import org.example.ExampleApp

# 带参数调用
bin/dispatcher say --words "Hello World" --import org.example.ExampleApp
bin/dispatcher say/"Hello World" --import org.example.ExampleApp

# 带路径参数调用
bin/dispatcher users/123 --import org.example.UserModule

# 启动服务器
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --import org.example.ExampleApp --server-port 8080
```

## 配置参考

### application.properties

```
# 数据库配置
driver=org.h2.Driver
database.url=jdbc:h2:~/test
database.user=
database.password=
database.connections.max=10

# 默认设置
default.file.encoding=UTF-8
default.home.page=say/Praise the Lord!
default.reload.mode=true
default.date.format=yyyy-MM-dd HH:mm:ss
#default.import.applications=custom.application.hello;
#default.apps.package=custom.application
#default.session.repository=org.tinystruct.http.MemorySession

# 错误处理
default.error.process=false
default.error.page=error

# HTTP配置
default.http.max_content_length = 4194304

# 系统目录
system.directory=

# 邮件配置
mail.smtp.host=
mail.pop3.host=
mail.smtp.port=
mail.pop3.port=
mail.smtp.auth=
mail.pop3.auth=
smtp.auth.user=
smtp.auth.pwd=

# 日志配置
logging.override = !TRUE
handlers = java.util.logging.ConsoleHandler
java.util.logging.ConsoleHandler.level = FINE
java.util.logging.ConsoleHandler.formatter = org.apache.juli.OneLineFormatter
java.util.logging.ConsoleHandler.encoding = UTF-8
org.tinystruct.valve.Watcher$LockEventListener.level=WARNING

# MQTT配置
mqtt.server.host=tcp://192.168.0.101
mqtt.server.port=1883

# MCP配置
mcp.auth.token=123456
```

通过这些特性，tinystruct 框架为 Java 应用开发提供了一种轻量、灵活且高效的解决方案，特别适合对性能、资源效率和部署灵活性有较高要求的现代应用场景。