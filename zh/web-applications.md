# 使用 tinystruct 开发 Web 应用

本指南解释如何使用 tinystruct 框架构建 Web 应用程序。

## Web 服务器集成

tinystruct 支持多种 Web 服务器：

### Netty HTTP 服务器

```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```

### Tomcat 服务器

```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```

## 请求处理

### URL 模式

Tinystruct 使用智能的模式匹配系统进行路由：

```java
@Action("users")    // 自动匹配 /users、/users/123、/users/123/posts
```

框架会根据 URL 模式和方法参数自动将请求路由到适当的方法。无需在 @Action 注解中定义像 `{id}` 这样的路径变量。

### HTTP 特定方法操作

1.7.17 版本新增功能，您可以使用 `mode` 参数指定操作响应的 HTTP 方法：

```java
import org.tinystruct.system.annotation.Action.Mode;

@Action(value = "users", mode = Mode.HTTP_GET)
public String getUsers() {
    return "获取所有用户";
}

@Action(value = "users", mode = Mode.HTTP_POST)
public String createUser() {
    return "创建用户";
}

@Action(value = "users", mode = Mode.HTTP_PUT)
public String updateUser() {
    return "更新用户";
}

@Action(value = "users", mode = Mode.HTTP_DELETE)
public String deleteUser() {
    return "删除用户";
}
```

### 访问请求参数

```java
@Action("search")
public String search(Request request, Response response) {
    String query = request.getParameter("q");
    int page = Integer.parseInt(request.getParameter("page", "1"));

    // 处理搜索
    // 设置内容类型为 JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // 使用 Builder 创建 JSON 数据
    Builder builder = new Builder();
    builder.put("results", results);

    return builder.toString();
}
```

### 方法参数

```java
@Action("users")
public String getUser(Integer id, Response response) {
    User user = userService.findById(id);

    // 设置内容类型为 JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // 使用 Builder 创建 JSON 数据
    Builder builder = new Builder();
    builder.put("user", user);

    return builder.toString();
}
```

当收到像 `/users/123` 这样的请求时，Tinystruct 会自动从 URL 中提取 ID 并将其传递给方法参数。框架根据位置和类型智能地将 URL 片段映射到方法参数。

## 响应类型

tinystruct 提供多种响应类型：

### 文本响应

```java
@Action("hello")
public String hello(String name) {
    return "你好，" + name + "！";
}
```

### JSON 响应

```java
@Action("api/users")
public String getUsers(Request request, Response response) {
    List<User> users = userService.findAll();

    // 设置内容类型为 JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // 使用 Builder 创建 JSON 数据
    Builder builder = new Builder();
    builder.put("users", users);

    return builder.toString();
}
```

您也可以使用 `org.tinystruct.data.component.Builder` 和 `Builders` 来解析 JSON 数据：

```java
// 解析 JSON 字符串
String jsonString = "{\"name\":\"John\",\"age\":30,\"items\":[\"book\",\"pen\"]}";
Builder builder = new Builder();
builder.parse(jsonString);

// 访问 JSON 数据
String name = builder.get("name").toString();
int age = Integer.parseInt(builder.get("age").toString());

// 访问数组数据
Builders items = (Builders) builder.get("items");
for (int i = 0; i < items.size(); i++) {
    System.out.println(items.get(i));
}

// 创建 JSON 数据
Builder responseBuilder = new Builder();
responseBuilder.put("success", true);
responseBuilder.put("message", "操作完成");

// 创建嵌套 JSON 对象
Builder userBuilder = new Builder();
userBuilder.put("id", 123);
userBuilder.put("name", "John");
responseBuilder.put("user", userBuilder);

// 创建 JSON 数组
Builders rolesBuilders = new Builders();
rolesBuilders.add("admin");
rolesBuilders.add("user");
responseBuilder.put("roles", rolesBuilders);

// 转换为 JSON 字符串
String jsonResponse = responseBuilder.toString();
```

### 模板渲染

```java
@Action("profile")
public Object showProfile(Integer id, Request request, Response response) {
    User user = userService.findById(id);

    // 为模板设置变量
    this.setVariable("user_name", user.getName());
    this.setVariable("user_email", user.getEmail());
    this.setVariable("user_id", String.valueOf(user.getId()));

    // 返回当前实例，模板将自动选择
    return this;
}
```

在 tinystruct 中，您使用 `setVariable()` 方法设置变量，并使用 `return this;` 返回当前实例。框架将根据类名自动选择并渲染适当的模板。例如，如果您的操作在名为 `ProfileAction.java` 的类中，框架将查找名为 `profile.view` 的模板。这种基于约定的方法消除了显式指定模板名称的需要，使代码更加清晰和易于维护。

### 文件响应

```java
@Action("download")
public byte[] downloadFile(String filename, Request request, Response response) throws ApplicationException {
    // 创建下载文件的路径
    final String fileDir = "/path/to/files";

    // 获取文件路径
    Path path = Paths.get(fileDir, filename);

    try {
        // 设置适当的内容类型
        String mimeType = Files.probeContentType(path);
        if (mimeType != null) {
            response.headers().add(Header.CONTENT_TYPE.set(mimeType));
        } else {
            response.headers().add(Header.CONTENT_DISPOSITION.set("application/octet-stream;filename=\"" + filename + "\""));
        }

        // 读取并返回文件作为字节数组
        return Files.readAllBytes(path);
    } catch (IOException e) {
        throw new ApplicationException("读取文件时出错：" + e.getMessage(), e);
    }
}
```

## 会话管理

```java
@Action("login")
public Object login(Request request, Response response) {
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (authService.authenticate(username, password)) {
        Session session = request.getSession(true);
        session.setAttribute("user", username);

        // 创建 Reforward 对象进行重定向
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=dashboard");
        return reforward.forward();
    }

    // 为模板设置错误变量
    this.setVariable("error", "无效的凭据");

    // 返回当前实例，模板将自动选择
    return this;
}

@Action("dashboard")
public Object dashboard(Request request, Response response) {
    Session session = request.getSession(false);

    if (session == null || session.getAttribute("user") == null) {
        // 创建 Reforward 对象进行重定向
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=login");
        return reforward.forward();
    }

    // 为模板设置用户变量
    this.setVariable("username", session.getAttribute("user"));

    // 返回当前实例，模板将自动选择
    return this;
}
```

## Cookie 管理

```java
@Action("set-preference")
public Object setPreference(Request request, Response response) {
    String theme = request.getParameter("theme");

    // 创建并配置 cookie
    Cookie cookie = new Cookie("theme", theme);
    cookie.setMaxAge(60 * 60 * 24 * 30); // 30 天

    // 将 cookie 添加到响应中
    response.addCookie(cookie);

    // 重定向到主页
    Reforward reforward = new Reforward(request, response);
    reforward.setDefault("/?q=home");
    return reforward.forward();
}
```

## 文件上传

```java
@Action("upload")
public String uploadFile(Request request, Response response) {
    List<FileEntity> files = request.getAttachments();

    if (files != null && !files.isEmpty()) {
        FileEntity file = files.get(0);
        String filename = file.getFilename();

        // 设置保存文件的路径
        final String path = "/path/to/uploads";
        final File f = new File(path + File.separator + filename);

        if (!f.getParentFile().exists()) {
            f.getParentFile().mkdirs();
        }

        try (final OutputStream out = new FileOutputStream(f);
             final BufferedOutputStream bout = new BufferedOutputStream(out);
             final BufferedInputStream bs = new BufferedInputStream(new ByteArrayInputStream(file.get()))) {

            final byte[] bytes = new byte[1024];
            int read;

            while ((read = bs.read(bytes)) != -1) {
                bout.write(bytes, 0, read);
            }

            // 设置内容类型为 JSON
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));

            // 创建成功响应
            Builder builder = new Builder();
            builder.put("success", true);
            builder.put("filename", filename);

            return builder.toString();
        } catch (IOException e) {
            // 设置内容类型为 JSON
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));

            // 创建错误响应
            Builder builder = new Builder();
            builder.put("success", false);
            builder.put("error", "上传文件时出错：" + e.getMessage());

            return builder.toString();
        }
    }

    // 设置内容类型为 JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // 创建错误响应
    Builder builder = new Builder();
    builder.put("success", false);
    builder.put("error", "未上传文件");

    return builder.toString();
}
```

## 错误处理

```java
@Action("api/resource")
public String getResource(Integer id, Request request, Response response) {
    try {
        Resource resource = resourceService.findById(id);

        if (resource == null) {
            throw new NotFoundException("未找到资源：" + id);
        }

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 使用 Builder 创建 JSON 数据
        Builder builder = new Builder();
        builder.put("resource", resource);

        return builder.toString();
    } catch (NotFoundException e) {
        // 设置错误状态码
        response.setStatus(ResponseStatus.NOT_FOUND);
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建错误响应
        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    } catch (Exception e) {
        logger.error("检索资源时出错", e);

        // 设置错误状态码
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建错误响应
        Builder builder = new Builder();
        builder.put("error", "内部服务器错误");

        return builder.toString();
    }
}
```

## 安全性

### CSRF 保护

```java
@Action("form")
public String showForm(Request request) {
    // 生成 CSRF 令牌
    String csrfToken = UUID.randomUUID().toString();

    // 将令牌存储在会话中
    request.getSession(true).setAttribute("csrf_token", csrfToken);

    // 为模板设置令牌
    this.setVariable("csrfToken", csrfToken);

    // 返回当前实例，模板将自动选择
    return this;
}

@Action("submit")
public Object processForm(Request request, Response response) {
    String csrfToken = request.getParameter("csrf_token");
    String storedToken = (String) request.getSession(false).getAttribute("csrf_token");

    if (storedToken == null || !storedToken.equals(csrfToken)) {
        // 设置错误状态码
        response.setStatus(ResponseStatus.FORBIDDEN);

        // 为模板设置错误消息
        this.setVariable("error", "无效的 CSRF 令牌");

        // 返回当前实例，模板将自动选择
        return this;
    }

    // 处理表单

    // 重定向到成功页面
    Reforward reforward = new Reforward(request, response);
    reforward.setDefault("/?q=success");
    return reforward.forward();
}
```

### 身份验证和授权

```java
@Action("admin/users")
public Object adminUsers(Request request, Response response) {
    // 检查用户是否已经认证
    Session session = request.getSession(false);
    if (session == null || session.getAttribute("user") == null) {
        // 重定向到登录页面
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=login");
        return reforward.forward();
    }

    // 检查用户是否有管理员角色
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("ADMIN")) {
        // 设置错误状态码
        response.setStatus(ResponseStatus.FORBIDDEN);

        // 为模板设置错误消息
        this.setVariable("error", "访问被拒绝");

        // 返回错误模板
        return "error";
    }

    // 从服务获取用户
    List<User> users = userService.findAll();

    // 为模板设置用户
    for (int i = 0; i < users.size(); i++) {
        User user = users.get(i);
        this.setVariable("user_" + i + "_id", String.valueOf(user.getId()));
        this.setVariable("user_" + i + "_name", user.getName());
        this.setVariable("user_" + i + "_email", user.getEmail());
    }
    this.setVariable("user_count", String.valueOf(users.size()));

    // 返回当前实例，模板将自动选择
    return this;
}
```

## 最佳实践

1. **关注点分离**：保持您的动作方法专注于处理请求/响应周期，并将业务逻辑委托给服务类。

2. **输入验证**：在处理之前始终验证用户输入。

3. **错误处理**：在整个应用程序中实现一致的错误处理。

4. **安全性**：应用适当的身份验证、授权和输入净化。

5. **测试**：为您的 Web 端点编写单元和集成测试。

## 下一步

- 了解[数据库集成](database.md)
- 探索[高级特性](advanced-features.md)
- 查看[最佳实践](best-practices.md)
