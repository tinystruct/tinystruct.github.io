# tinystruct 配置

本指南解释如何使用属性文件和配置 API 配置 tinystruct 应用程序。

## 配置基础

tinystruct 使用从属性文件加载的简单键值配置系统。通过 `AbstractApplication` 类中的 `getConfiguration()` 方法，可以在整个应用程序中访问配置。

## 配置文件

默认情况下，tinystruct 在类路径中查找名为 `config.properties` 的文件。您也可以在启动应用程序时指定不同的配置文件。

### 基本配置文件

```properties
# 应用程序设置
application.name=MyApp
application.mode=development

# 服务器设置
server.port=8080
server.host=localhost

# 数据库设置
driver=org.h2.Driver
database.url=jdbc:h2:~/test
database.user=sa
database.password=
database.connections.max=10

# 默认设置
default.file.encoding=UTF-8
default.home.page=welcome
default.reload.mode=true
default.date.format=yyyy-MM-dd HH:mm:ss

# 错误处理
default.error.process=false
default.error.page=error

# HTTP 配置
default.http.max_content_length=4194304
```

## 访问配置

### 在应用程序代码中

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 获取配置值
        String appName = getConfiguration().get("application.name");
        int port = Integer.parseInt(getConfiguration().get("server.port"));
        boolean devMode = "development".equals(getConfiguration().get("application.mode"));
        
        // 使用配置值
        System.out.println("启动 " + appName + " 在端口 " + port);
        
        if (devMode) {
            System.out.println("在开发模式下运行");
        }
    }
}
```

### 默认值

访问配置属性时可以提供默认值：

```java
String encoding = getConfiguration().get("default.file.encoding", "UTF-8");
int maxConnections = Integer.parseInt(getConfiguration().get("database.connections.max", "5"));
```

## 环境特定配置

您可以为不同环境创建不同的配置文件：

### 开发配置

```properties
# config.dev.properties
application.mode=development
server.port=8080
logging.level=DEBUG
```

### 生产配置

```properties
# config.prod.properties
application.mode=production
server.port=80
logging.level=INFO
```

### 加载环境特定配置

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        String env = System.getProperty("env", "dev");
        getConfiguration().load("config." + env + ".properties");
        
        System.out.println("已加载 " + env + " 环境的配置");
    }
}
```

## 动态配置

您可以在运行时更新配置值：

```java
@Action("set-config")
public String setConfig(String key, String value) {
    getConfiguration().set(key, value);
    return "配置已更新：" + key + " = " + value;
}
```

## 配置 API

### 加载配置

```java
// 从默认位置加载
getConfiguration().load();

// 从特定文件加载
getConfiguration().load("custom-config.properties");

// 从 URL 加载
getConfiguration().load(new URL("http://config-server/app-config.properties"));
```

### 获取配置值

```java
// 获取字符串值
String value = getConfiguration().get("key");

// 获取带默认值的字符串值
String value = getConfiguration().get("key", "default");

// 获取整数值
int intValue = getConfiguration().getInt("key");

// 获取带默认值的整数值
int intValue = getConfiguration().getInt("key", 0);

// 获取布尔值
boolean boolValue = getConfiguration().getBoolean("key");

// 获取带默认值的布尔值
boolean boolValue = getConfiguration().getBoolean("key", false);
```

### 设置配置值

```java
// 设置字符串值
getConfiguration().set("key", "value");

// 设置整数值
getConfiguration().set("key", 123);

// 设置布尔值
getConfiguration().set("key", true);
```

### 检查配置

```java
// 检查键是否存在
boolean exists = getConfiguration().contains("key");

// 获取所有配置键
Set<String> keys = getConfiguration().keySet();

// 获取配置作为 Properties 对象
Properties props = getConfiguration().getProperties();
```

## 常用配置属性

### 应用程序设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| application.name | 应用程序名称 | - |
| application.mode | 应用程序模式（development、production） | development |
| application.version | 应用程序版本 | - |

### 服务器设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| server.port | HTTP 服务器端口 | 8080 |
| server.host | HTTP 服务器主机 | localhost |
| server.context | 服务器上下文路径 | / |
| server.threads | 服务器线程池大小 | 10 |

### 数据库设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| driver | JDBC 驱动类 | - |
| database.url | 数据库 URL | - |
| database.user | 数据库用户名 | - |
| database.password | 数据库密码 | - |
| database.connections.max | 最大数据库连接数 | 10 |

### 默认设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| default.file.encoding | 默认文件编码 | UTF-8 |
| default.home.page | 默认主页 | - |
| default.reload.mode | 启用重新加载模式 | false |
| default.date.format | 默认日期格式 | yyyy-MM-dd HH:mm:ss |
| default.error.process | 启用错误处理 | false |
| default.error.page | 默认错误页面 | error |
| default.http.max_content_length | 最大 HTTP 内容长度 | 4194304 |

### 日志设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| logging.override | 覆盖日志配置 | false |
| handlers | 日志处理器 | java.util.logging.ConsoleHandler |
| java.util.logging.ConsoleHandler.level | 控制台处理器日志级别 | FINE |
| java.util.logging.ConsoleHandler.formatter | 控制台处理器格式化程序 | org.apache.juli.OneLineFormatter |
| java.util.logging.ConsoleHandler.encoding | 控制台处理器编码 | UTF-8 |

### AI/MCP 设置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| mcp.auth.token | MCP 鉴权令牌 | - |


## 最佳实践

1. **环境变量**：对敏感信息（如数据库密码）使用环境变量。

2. **配置层次结构**：实现配置层次结构（默认 → 环境特定 → 命令行覆盖）。

3. **验证**：在启动时验证配置值，如果缺少必需属性，则快速失败。

4. **文档**：记录应用程序使用的所有配置属性。

5. **默认值**：为可选配置属性提供合理的默认值。

## 下一步

- 了解[数据库集成](database.md)
- 探索[高级特性](advanced-features.md)
- 查看[最佳实践](best-practices.md)
