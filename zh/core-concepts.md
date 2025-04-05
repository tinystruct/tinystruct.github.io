# 核心概念

## 应用结构

### AbstractApplication

所有 tinystruct 应用的基类。它提供：

- 配置管理
- 动作处理
- 请求/响应处理
- 数据库连接

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 初始化应用
    }

    @Override
    public String version() {
        return "1.0.0";
    }
}
```

## 动作（Actions）

动作是 tinystruct 应用的核心构建块。它们同时处理 Web 请求和 CLI 命令。

### Action 注解

```java
@Action(
    value = "endpoint",           // URL模式或命令名称
    description = "描述",         // 动作描述
    mode = Action.Mode.ALL       // 执行模式（ALL、WEB、CLI）
)
```

### URL 模式

```java
@Action("users")    // 自动匹配 /users、/users/123、/users/123/posts
```

Tinystruct 会根据 URL 模式自动匹配正确的功能。无需在 @Action 注解中定义像 `{id}` 这样的变量。框架会根据参数智能地将请求路由到适当的方法。

## 配置

### 属性文件

```properties
# 应用设置
application.name=MyApp
application.mode=development

# 服务器设置
server.port=8080
server.host=localhost

# 数据库设置
database.type=MySQL
database.url=jdbc:mysql://localhost:3306/mydb
```

### 访问配置

```java
String appName = getConfiguration().get("application.name");
int port = Integer.parseInt(getConfiguration().get("server.port"));
```

## 数据库集成

### 仓库类型

- MySQL
- SQLite
- H2
- Redis
- Microsoft SQL Server

### 基本用法

```java
Repository repository = Type.MySQL.createRepository();
repository.connect(getConfiguration());

// 执行查询
List<Row> results = repository.query("SELECT * FROM users");

// 执行更新
repository.execute("UPDATE users SET name = ? WHERE id = ?",
                  "张三", 1);
```

## 请求处理

### Web 请求

```java
@Action("api/data")
public String getData(Request request, Response response) {
    String param = request.getParameter("key");

    // 设置内容类型为 JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // 创建 JSON 响应
    Builder builder = new Builder();
    builder.put("key", param);

    return builder.toString();
}
```

### CLI 命令

```java
@Action(value = "generate",
        description = "生成 POJO 对象",
        mode = Action.Mode.CLI)
public void generate() {
    // 命令实现
}
```

## 安全性

### 身份验证

```java
@Action("secure/endpoint")
public Response secureEndpoint(Request request) {
    if (!isAuthenticated(request)) {
        throw new UnauthorizedException();
    }
    // 受保护的代码
}
```

### 授权

```java
@Action("admin/users")
public Response adminOnly(Request request) {
    if (!hasRole(request, "ADMIN")) {
        throw new ForbiddenException();
    }
    // 仅管理员代码
}
```

## 错误处理

```java
try {
    // 您的代码
} catch (ApplicationException e) {
    logger.log(Level.SEVERE, e.getMessage(), e);
    throw new ApplicationRuntimeException(e.getMessage(), e);
}
```

## 下一步

- 了解[Web应用开发](web-applications.md)
- 探索[数据库集成](database.md)
- 查看[命令行应用](cli-applications.md)