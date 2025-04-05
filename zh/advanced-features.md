# Tinystruct 高级特性

本指南涵盖 Tinystruct 框架中的高级特性和技术。

## 事件系统

Tinystruct 包含一个强大的事件系统，允许组件在没有直接耦合的情况下进行通信。

### 事件调度器

```java
// 获取事件调度器实例
EventDispatcher dispatcher = EventDispatcher.getInstance();

// 注册事件处理程序
dispatcher.registerHandler(UserCreatedEvent.class, event -> {
    User user = event.getPayload();
    System.out.println("用户已创建: " + user.getName());

    // 发送欢迎邮件
    emailService.sendWelcomeEmail(user.getEmail());
});

// 分发事件
User newUser = userService.createUser("zhangsan@example.com", "password");
dispatcher.dispatch(new UserCreatedEvent(newUser));
```

### 自定义事件

```java
public class UserCreatedEvent implements Event<User> {
    private final User payload;

    public UserCreatedEvent(User user) {
        this.payload = user;
    }

    @Override
    public User getPayload() {
        return payload;
    }
}
```

### 应用生命周期事件

```java
public class MyApp extends AbstractApplication {
    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();

    static {
        // 注册应用启动处理程序
        dispatcher.registerHandler(ApplicationStartEvent.class, event -> {
            System.out.println("应用已启动: " + event.getPayload().getName());
        });

        // 注册应用关闭处理程序
        dispatcher.registerHandler(ApplicationShutdownEvent.class, event -> {
            System.out.println("应用正在关闭: " + event.getPayload().getName());
        });
    }

    @Override
    public void init() {
        // 分发启动事件
        dispatcher.dispatch(new ApplicationStartEvent(this));

        // 注册关闭钩子
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            dispatcher.dispatch(new ApplicationShutdownEvent(this));
        }));
    }
}
```

## 命令行界面 (CLI)

Tinystruct 通过其调度器系统提供强大的命令行界面，允许您从命令行执行操作。

### 基本 CLI 用法

```bash
# 使用参数执行操作
bin/dispatcher say/"Hello World"

# 使用命名参数执行
bin/dispatcher say --words "Hello World" --import tinystruct.examples.example
```

### 创建 CLI 命令

您可以通过在操作注解中添加 `Action.Mode.CLI` 模式来创建自定义 CLI 命令：

```java
@Action(value = "generate",
        description = "POJO 对象生成器",
        mode = Action.Mode.CLI)
public String generatePOJO(String table) {
    // 从数据库表生成 POJO 的实现
    return "为表生成的 POJO：" + table;
}
```

### 内置 CLI 命令

Tinystruct 包含几个内置 CLI 命令：

- `download`：从其他服务器下载资源
- `exec`：执行本地命令
- `generate`：生成 POJO 对象
- `install`：安装包
- `maven-wrapper`：提取 Maven Wrapper
- `open`：在默认浏览器中打开 URL
- `say`：输出文字
- `set`：设置系统属性
- `sql-execute`：执行 SQL 语句
- `sql-query`：执行 SQL 查询
- `update`：更新到最新版本

## HTTP 服务器集成

Tinystruct 支持多种 HTTP 服务器实现，允许您选择最适合您需求的服务器。

### Netty 服务器

```java
// 启动 Netty HTTP 服务器
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```

### Tomcat 服务器

```java
// 启动 Tomcat 服务器
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```

## 上下文管理

Tinystruct 中的上下文系统允许您在应用程序的不同部分之间共享数据。

```java
// 设置上下文属性
getContext().setAttribute("user", currentUser);

// 获取上下文属性
User user = (User) getContext().getAttribute("user");

// 获取带默认值的属性
String theme = (String) getContext().getAttribute("theme", "default");
```

## 配置管理

Tinystruct 提供了灵活的配置系统，允许您管理应用程序设置。

```java
// 获取配置值
String appName = getConfiguration().get("application.name");

// 设置配置值
getConfiguration().set("application.mode", "development");

// 从文件加载配置
getConfiguration().load("config.properties");
```

## 数据库操作

Tinystruct 通过 DatabaseOperator 类提供高级数据库操作。

### 事务管理

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // 开始事务
    operator.beginTransaction();

    try {
        // 执行数据库操作
        PreparedStatement stmt1 = operator.preparedStatement(
            "INSERT INTO users (name) VALUES (?)",
            new Object[]{"张三"}
        );
        operator.executeUpdate(stmt1);

        // 提交事务
        operator.commitTransaction();
    } catch (Exception e) {
        // 回滚事务
        operator.rollbackTransaction();
        throw e;
    }
}
```

### 使用保存点

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // 开始事务
    operator.beginTransaction();

    // 执行第一个操作
    operator.executeUpdate("INSERT INTO users (name) VALUES ('张三')");

    // 创建保存点
    Savepoint savepoint = operator.createSavepoint("AFTER_INSERT");

    try {
        // 执行第二个操作
        operator.executeUpdate("UPDATE settings SET value = 'new_value'");
    } catch (Exception e) {
        // 回滚到保存点
        operator.rollbackTransaction(savepoint);
    }

    // 提交事务
    operator.commitTransaction();
}
```

## 对象关系映射

Tinystruct 通过 AbstractData 类提供简单的对象关系映射系统。

```java
// 定义模型类
public class User extends AbstractData {
    private int id;
    private String name;
    private String email;

    // Getters 和 setters
    // ...
}

// 在资源目录中创建 XML 映射文件
// user.map.xml:
// <mapping>
//     <class name="com.example.model.User" table="users">
//         <property name="id" column="id" type="int" identifier="true"/>
//         <property name="name" column="name" type="string"/>
//         <property name="email" column="email" type="string"/>
//     </class>
// </mapping>

// 使用模型
User user = new User();
user.setName("张三");
user.setEmail("zhangsan@example.com");
user.append(); // 插入数据库

// 按 ID 查找
User foundUser = new User();
foundUser.setId(1);
foundUser.findOneById();

// 更新
foundUser.setName("李四");
foundUser.update();

// 删除
foundUser.delete();

// 查找所有
List<User> allUsers = user.findAll();

// 条件查找
List<User> filteredUsers = user.findWhere("name LIKE ?", "%张%");
```

## JSON 数据处理

Tinystruct 通过 Builder 和 Builders 类提供处理 JSON 数据的工具。

```java
// 创建 JSON 数据
Builder builder = new Builder();
builder.put("name", "张三");
builder.put("age", 30);

// 创建嵌套对象
Builder addressBuilder = new Builder();
addressBuilder.put("street", "主街 123 号");
addressBuilder.put("city", "任何镇");
builder.put("address", addressBuilder);

// 创建数组
Builders hobbiesBuilder = new Builders();
hobbiesBuilder.add("阅读");
hobbiesBuilder.add("徒步");
builder.put("hobbies", hobbiesBuilder);

// 转换为 JSON 字符串
String json = builder.toString();

// 解析 JSON 字符串
Builder parsedBuilder = new Builder();
parsedBuilder.parse(json);

// 访问 JSON 数据
String name = parsedBuilder.get("name").toString();
int age = Integer.parseInt(parsedBuilder.get("age").toString());
Builder address = (Builder) parsedBuilder.get("address");
String city = address.get("city").toString();
Builders hobbies = (Builders) parsedBuilder.get("hobbies");
String firstHobby = hobbies.get(0).toString();
```

## 国际化 (i18n)

Tinystruct 支持国际化，用于构建多语言应用程序。

```java
// 从请求获取区域设置
Locale locale = request.getLocale();

// 获取区域设置的消息包
ResourceBundle bundle = ResourceBundle.getBundle("messages", locale);

// 获取带参数的消息
String greeting = MessageFormat.format(
    bundle.getString("greeting"),
    "张三"
);
```

## 最佳实践

1. **操作组织**：将相关操作分组到单独的类中，以便更好地组织。

2. **错误处理**：为 CLI 和 Web 应用程序实现适当的错误处理。

3. **配置管理**：为不同环境使用特定于环境的配置文件。

4. **数据库连接**：始终使用 try-with-resources 进行数据库操作，以确保正确的资源清理。

5. **事务管理**：对需要原子性的操作使用事务。

## 下一步

- 探索 [API 参考](api/README.md)
- 查看[最佳实践](best-practices.md)指南
