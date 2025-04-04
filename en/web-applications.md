# Web Applications with tinystruct

This guide explains how to build web applications using the tinystruct framework.

## Web Server Integration

tinystruct supports multiple web servers:

### Netty HTTP Server

```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```

### Tomcat Server

```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```

### Undertow Server

```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```

## Request Handling

### URL Patterns

Tinystruct uses an intelligent pattern matching system for routing:

```java
@Action("users")    // Automatically matches /users, /users/123, /users/123/posts
```

The framework automatically routes requests to the appropriate method based on the URL pattern and method parameters. There's no need to define path variables like `{id}` in the @Action annotation.

### Accessing Request Parameters

```java
@Action("search")
public Response search(Request request) {
    String query = request.getParameter("q");
    int page = Integer.parseInt(request.getParameter("page", "1"));

    // Process search
    return new JsonResponse(results);
}
```

### Method Parameters

```java
@Action("users")
public Response getUser(Integer id) {
    User user = userService.findById(id);
    return new JsonResponse(user);
}
```

When a request like `/users/123` is received, Tinystruct automatically extracts the ID from the URL and passes it to the method parameter. The framework intelligently maps URL segments to method parameters based on their position and type.

## Response Types

tinystruct provides several response types:

### Text Response

```java
@Action("hello")
public String hello(String name) {
    return "Hello, " + name + "!";
}
```

### JSON Response

```java
@Action("api/users")
public JsonResponse getUsers() {
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}
```

### Template Response

```java
@Action("profile")
public TemplateResponse showProfile(Integer id) {
    User user = userService.findById(id);

    Map<String, Object> context = new HashMap<>();
    context.put("user", user);

    return new TemplateResponse("profile.html", context);
}
```

### File Response

```java
@Action("download/{filename}")
public FileResponse downloadFile(String filename) {
    File file = new File("/path/to/files/" + filename);
    return new FileResponse(file);
}
```

## Session Management

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

    return new TemplateResponse("login.html", Map.of("error", "Invalid credentials"));
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

## Cookie Management

```java
@Action("set-preference")
public Response setPreference(Request request) {
    String theme = request.getParameter("theme");

    Cookie cookie = new Cookie("theme", theme);
    cookie.setMaxAge(60 * 60 * 24 * 30); // 30 days

    Response response = new RedirectResponse("/");
    response.addCookie(cookie);

    return response;
}
```

## File Upload

```java
@Action("upload")
public Response uploadFile(Request request) {
    FileItem file = request.getFile("document");

    if (file != null) {
        String filename = file.getName();
        file.write("/path/to/uploads/" + filename);

        return new JsonResponse(Map.of("success", true, "filename", filename));
    }

    return new JsonResponse(Map.of("success", false, "error", "No file uploaded"));
}
```

## Error Handling

```java
@Action("api/resource/{id}")
public Response getResource(Integer id) {
    try {
        Resource resource = resourceService.findById(id);

        if (resource == null) {
            throw new NotFoundException("Resource not found: " + id);
        }

        return new JsonResponse(resource);
    } catch (NotFoundException e) {
        return new ErrorResponse(404, e.getMessage());
    } catch (Exception e) {
        logger.error("Error retrieving resource", e);
        return new ErrorResponse(500, "Internal server error");
    }
}
```

## Security

### CSRF Protection

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
        return new ErrorResponse(403, "Invalid CSRF token");
    }

    // Process form
    return new RedirectResponse("/success");
}
```

### Authentication and Authorization

```java
@Action("admin/users")
public Response adminUsers(Request request) {
    if (!isAuthenticated(request)) {
        return new RedirectResponse("/login");
    }

    if (!hasRole(request, "ADMIN")) {
        return new ErrorResponse(403, "Access denied");
    }

    List<User> users = userService.findAll();
    return new TemplateResponse("admin/users.html", Map.of("users", users));
}
```

## Best Practices

1. **Separation of Concerns**: Keep your action methods focused on handling the request/response cycle, and delegate business logic to service classes.

2. **Input Validation**: Always validate user input before processing.

3. **Error Handling**: Implement consistent error handling across your application.

4. **Security**: Apply proper authentication, authorization, and input sanitization.

5. **Testing**: Write unit and integration tests for your web endpoints.

## Next Steps

- Learn about [Database Integration](database.md)
- Explore [Advanced Features](advanced-features.md)
- Check out [Best Practices](best-practices.md)
