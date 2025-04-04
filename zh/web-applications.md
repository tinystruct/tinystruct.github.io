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

### Undertow 服务器

```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```

## 请求处理

### URL 模式

Tinystruct 使用智能的模式匹配系统进行路由：

```java
@Action("users")    // 自动匹配 /users、/users/123、/users/123/posts
```

框架会根据 URL 模式和方法参数自动将请求路由到适当的方法。无需在 @Action 注解中定义像 `{id}` 这样的路径变量。

### 访问请求参数

```java
@Action("search")
public Response search(Request request) {
    String query = request.getParameter("q");
    int page = Integer.parseInt(request.getParameter("page", "1"));

    // 处理搜索
    return new JsonResponse(results);
}
```

### 方法参数

```java
@Action("users")
public Response getUser(Integer id) {
    User user = userService.findById(id);
    return new JsonResponse(user);
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
public JsonResponse getUsers() {
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}
```

### 模板响应

```java
@Action("profile")
public TemplateResponse showProfile(Integer id) {
    User user = userService.findById(id);

    Map<String, Object> context = new HashMap<>();
    context.put("user", user);

    return new TemplateResponse("profile.html", context);
}
```

### 文件响应

```java
@Action("download/{filename}")
public FileResponse downloadFile(String filename) {
    File file = new File("/path/to/files/" + filename);
    return new FileResponse(file);
}
```

## 会话管理

```java
@Action("login")
public Response login(Request request) {
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (authService.authenticate(username, password)) {
        Session session = request.getSession(true);
        session.setAttribute("user", username);
        return new RedirectResponse("/dashboard");
    }

    return new TemplateResponse("login.html", Map.of("error", "无效的凭据"));
}

@Action("dashboard")
public Response dashboard(Request request) {
    Session session = request.getSession(false);

    if (session == null || session.getAttribute("user") == null) {
        return new RedirectResponse("/login");
    }

    return new TemplateResponse("dashboard.html");
}
```

## Cookie 管理

```java
@Action("set-preference")
public Response setPreference(Request request) {
    String theme = request.getParameter("theme");

    Cookie cookie = new Cookie("theme", theme);
    cookie.setMaxAge(60 * 60 * 24 * 30); // 30 天

    Response response = new RedirectResponse("/");
    response.addCookie(cookie);

    return response;
}
```

## 文件上传

```java
@Action("upload")
public Response uploadFile(Request request) {
    FileItem file = request.getFile("document");

    if (file != null) {
        String filename = file.getName();
        file.write("/path/to/uploads/" + filename);

        return new JsonResponse(Map.of("success", true, "filename", filename));
    }

    return new JsonResponse(Map.of("success", false, "error", "未上传文件"));
}
```

## 错误处理

```java
@Action("api/resource/{id}")
public Response getResource(Integer id) {
    try {
        Resource resource = resourceService.findById(id);

        if (resource == null) {
            throw new NotFoundException("未找到资源：" + id);
        }

        return new JsonResponse(resource);
    } catch (NotFoundException e) {
        return new ErrorResponse(404, e.getMessage());
    } catch (Exception e) {
        logger.error("检索资源时出错", e);
        return new ErrorResponse(500, "内部服务器错误");
    }
}
```

## 安全性

### CSRF 保护

```java
@Action("form")
public Response showForm(Request request) {
    String csrfToken = generateCSRFToken(request);

    Map<String, Object> context = new HashMap<>();
    context.put("csrfToken", csrfToken);

    return new TemplateResponse("form.html", context);
}

@Action("submit")
public Response processForm(Request request) {
    String csrfToken = request.getParameter("csrf_token");

    if (!validateCSRFToken(request, csrfToken)) {
        return new ErrorResponse(403, "无效的 CSRF 令牌");
    }

    // 处理表单
    return new RedirectResponse("/success");
}
```

### 身份验证和授权

```java
@Action("admin/users")
public Response adminUsers(Request request) {
    if (!isAuthenticated(request)) {
        return new RedirectResponse("/login");
    }

    if (!hasRole(request, "ADMIN")) {
        return new ErrorResponse(403, "访问被拒绝");
    }

    List<User> users = userService.findAll();
    return new TemplateResponse("admin/users.html", Map.of("users", users));
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
