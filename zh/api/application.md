# Application API 参考

## AbstractApplication

`AbstractApplication` 类是所有 tinystruct 应用程序的基础。它提供了配置管理、动作处理和应用程序生命周期的核心功能。

### 类定义

```java
public abstract class AbstractApplication implements Application {
    // ...
}
```

### 必需方法

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| init() | void | 初始化应用程序 |
| version() | String | 获取应用程序版本 |

### 示例

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 初始化应用程序
        System.out.println("正在初始化 MyApp...");
    }
    
    @Override
    public String version() {
        return "1.0.0";
    }
}
```

## 核心方法

### 配置管理

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| getConfiguration() | Configuration | 获取应用程序配置 |
| setConfiguration(Configuration) | void | 设置应用程序配置 |

```java
// 获取配置值
String appName = getConfiguration().get("application.name");

// 设置配置值
getConfiguration().set("application.mode", "development");
```

### 动作管理

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| execute(String, Object...) | Object | 使用参数按名称执行动作 |
| register(Class<?>) | void | 注册动作类 |
| getContext() | Context | 获取应用程序上下文 |

```java
// 执行动作
Object result = execute("hello", "World");

// 注册动作类
register(UserActions.class);

// 获取上下文属性
String value = getContext().getAttribute("key");

// 设置上下文属性
getContext().setAttribute("key", "value");
```

### 应用程序生命周期

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| start() | void | 启动应用程序 |
| stop() | void | 停止应用程序 |
| restart() | void | 重启应用程序 |
| isRunning() | boolean | 检查应用程序是否正在运行 |

```java
// 启动应用程序
application.start();

// 检查是否正在运行
if (application.isRunning()) {
    // 应用程序正在运行
}

// 停止应用程序
application.stop();
```

## Application 接口

`Application` 接口定义了 tinystruct 应用程序的核心契约。

```java
public interface Application {
    void init();
    String version();
    Object execute(String action, Object... parameters) throws ApplicationException;
    Context getContext();
    void setContext(Context context);
    Configuration getConfiguration();
    void setConfiguration(Configuration configuration);
}
```

## ApplicationManager

`ApplicationManager` 类管理应用程序实例并提供对当前应用程序的访问。

### 静态方法

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| getInstance() | ApplicationManager | 获取单例实例 |
| get(String) | Application | 按名称获取应用程序 |
| register(String, Application) | void | 注册应用程序 |
| getCurrent() | Application | 获取当前应用程序 |
| setCurrent(Application) | void | 设置当前应用程序 |

```java
// 获取应用程序管理器
ApplicationManager manager = ApplicationManager.getInstance();

// 注册应用程序
manager.register("myapp", new MyApp());

// 获取应用程序
Application app = manager.get("myapp");

// 设置当前应用程序
manager.setCurrent(app);

// 获取当前应用程序
Application current = manager.getCurrent();
```

## Context

`Context` 接口提供对应用程序上下文属性的访问。

### 方法

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| getAttribute(String) | Object | 按名称获取属性 |
| getAttribute(String, Object) | Object | 获取带默认值的属性 |
| setAttribute(String, Object) | void | 设置属性 |
| removeAttribute(String) | void | 移除属性 |
| getAttributeNames() | Enumeration<String> | 获取所有属性名称 |

```java
// 获取上下文
Context context = application.getContext();

// 设置属性
context.setAttribute("user", currentUser);

// 获取属性
User user = (User) context.getAttribute("user");

// 获取带默认值
String theme = (String) context.getAttribute("theme", "default");

// 移除属性
context.removeAttribute("user");
```

## ApplicationException

`ApplicationException` 类是 tinystruct 应用程序的基本异常类。

```java
// 抛出应用程序异常
throw new ApplicationException("出现问题");

// 带原因抛出
throw new ApplicationException("数据库错误", sqlException);

// 捕获应用程序异常
try {
    // 可能抛出 ApplicationException 的代码
} catch (ApplicationException e) {
    System.err.println("错误：" + e.getMessage());
}
```

## ApplicationRuntimeException

`ApplicationRuntimeException` 类是 tinystruct 应用程序的未检查异常。

```java
// 抛出运行时异常
throw new ApplicationRuntimeException("意外错误");

// 带原因抛出
throw new ApplicationRuntimeException("配置错误", configException);
```

## 最佳实践

1. **初始化**：使用 `init()` 方法设置应用程序、注册动作和配置服务。

```java
@Override
public void init() {
    // 注册动作类
    register(UserActions.class);
    register(AuthActions.class);
    
    // 设置服务
    ServiceRegistry.getInstance().register(UserService.class, new UserServiceImpl());
    
    // 配置事件处理程序
    EventDispatcher.getInstance().registerHandler(UserCreatedEvent.class, event -> {
        // 处理事件
    });
}
```

2. **版本管理**：在 `version()` 方法中实现适当的版本控制。

```java
@Override
public String version() {
    return "1.2.3"; // 主要.次要.补丁
}
```

3. **上下文使用**：将上下文用于请求范围的数据，而不是应用程序配置。

```java
// 好：请求范围的数据
getContext().setAttribute("requestId", UUID.randomUUID().toString());

// 坏：应用程序配置
getContext().setAttribute("database.url", "jdbc:mysql://localhost:3306/mydb");
```

4. **异常处理**：使用适当的异常类型并提供有意义的错误消息。

```java
// 好：具有明确消息的特定异常
throw new ApplicationException("未找到 ID 为 " + userId + " 的用户");

// 坏：具有不明确消息的通用异常
throw new ApplicationException("错误");
```

## 相关 API

- [Action API](action.md)
- [Configuration API](configuration.md)
- [Database API](database.md)
