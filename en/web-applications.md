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

## Request Handling

### URL Patterns

Tinystruct uses an intelligent pattern matching system for routing:

```java
@Action("users")    // Automatically matches /users, /users/123, /users/123/posts
```

The framework automatically routes requests to the appropriate method based on the URL pattern and method parameters. There's no need to define path variables like `{id}` in the @Action annotation.

### HTTP Method-Specific Actions

New in version 1.7.17, you can specify which HTTP methods an action responds to using the `mode` parameter:

```java
import org.tinystruct.system.annotation.Action.Mode;

@Action(value = "users", mode = Mode.HTTP_GET)
public String getUsers() {
    return "Get all users";
}

@Action(value = "users", mode = Mode.HTTP_POST)
public String createUser() {
    return "Create user";
}

@Action(value = "users", mode = Mode.HTTP_PUT)
public String updateUser() {
    return "Update user";
}

@Action(value = "users", mode = Mode.HTTP_DELETE)
public String deleteUser() {
    return "Delete user";
}
```

### Accessing Request Parameters

```java
@Action("search")
public String search(Request request, Response response) {
    String query = request.getParameter("q");
    int page = Integer.parseInt(request.getParameter("page", "1"));

    // Process search
    // Set content type to JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Use Builder to create JSON data
    Builder builder = new Builder();
    builder.put("results", results);

    return builder.toString();
}
```

### Method Parameters

```java
@Action("users")
public String getUser(Integer id, Response response) {
    User user = userService.findById(id);

    // Set content type to JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Use Builder to create JSON data
    Builder builder = new Builder();
    builder.put("user", user);

    return builder.toString();
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
public String getUsers(Request request, Response response) {
    List<User> users = userService.findAll();

    // Set content type to JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Use Builder to create JSON data
    Builder builder = new Builder();
    builder.put("users", users);

    return builder.toString();
}
```

You can also use `org.tinystruct.data.component.Builder` and `Builders` to parse JSON data:

```java
// Parse JSON string
String jsonString = "{\"name\":\"John\",\"age\":30,\"items\":[\"book\",\"pen\"]}";
Builder builder = new Builder();
builder.parse(jsonString);

// Access JSON data
String name = builder.get("name").toString();
int age = Integer.parseInt(builder.get("age").toString());

// Access array data
Builders items = (Builders) builder.get("items");
for (int i = 0; i < items.size(); i++) {
    System.out.println(items.get(i));
}

// Create JSON data
Builder responseBuilder = new Builder();
responseBuilder.put("success", true);
responseBuilder.put("message", "Operation completed");

// Create nested JSON object
Builder userBuilder = new Builder();
userBuilder.put("id", 123);
userBuilder.put("name", "John");
responseBuilder.put("user", userBuilder);

// Create JSON array
Builders rolesBuilders = new Builders();
rolesBuilders.add("admin");
rolesBuilders.add("user");
responseBuilder.put("roles", rolesBuilders);

// Convert to JSON string
String jsonResponse = responseBuilder.toString();
```

### Template Rendering

```java
@Action("profile")
public Object showProfile(Integer id, Request request, Response response) {
    User user = userService.findById(id);

    // Set variables for the template
    this.setVariable("user_name", user.getName());
    this.setVariable("user_email", user.getEmail());
    this.setVariable("user_id", String.valueOf(user.getId()));

    // Return this instance, the template will be automatically selected
    return this;
}
```

In tinystruct, you set variables using the `setVariable()` method and return the current instance with `return this;`. The framework will automatically select and render the appropriate template based on the class name. For example, if your action is in a class named `ProfileAction.java`, the framework will look for a template named `profile.view`. This convention-based approach eliminates the need to explicitly specify template names, making the code cleaner and more maintainable.

### File Response

```java
@Action("download")
public byte[] downloadFile(String filename, Request request, Response response) throws ApplicationException {
    // Create path to download the file
    final String fileDir = "/path/to/files";

    // Get the file path
    Path path = Paths.get(fileDir, filename);

    try {
        // Set the appropriate content type
        String mimeType = Files.probeContentType(path);
        if (mimeType != null) {
            response.headers().add(Header.CONTENT_TYPE.set(mimeType));
        } else {
            response.headers().add(Header.CONTENT_DISPOSITION.set("application/octet-stream;filename=\"" + filename + "\""));
        }

        // Read and return the file as byte array
        return Files.readAllBytes(path);
    } catch (IOException e) {
        throw new ApplicationException("Error reading the file: " + e.getMessage(), e);
    }
}
```

## Session Management

```java
@Action("login")
public Object login(Request request, Response response) {
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (authService.authenticate(username, password)) {
        Session session = request.getSession(true);
        session.setAttribute("user", username);

        // Create a Reforward object for redirection
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=dashboard");
        return reforward.forward();
    }

    // Set error variable for the template
    this.setVariable("error", "Invalid credentials");

    // Return this instance, the template will be automatically selected
    return this;
}

@Action("dashboard")
public Object dashboard(Request request, Response response) {
    Session session = request.getSession(false);

    if (session == null || session.getAttribute("user") == null) {
        // Create a Reforward object for redirection
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=login");
        return reforward.forward();
    }

    // Set user variable for the template
    this.setVariable("username", session.getAttribute("user"));

    // Return this instance, the template will be automatically selected
    return this;
}
```

## Cookie Management

```java
@Action("set-preference")
public Object setPreference(Request request, Response response) {
    String theme = request.getParameter("theme");

    // Create and configure cookie
    Cookie cookie = new Cookie("theme", theme);
    cookie.setMaxAge(60 * 60 * 24 * 30); // 30 days

    // Add cookie to response
    response.addCookie(cookie);

    // Redirect to home page
    Reforward reforward = new Reforward(request, response);
    reforward.setDefault("/?q=home");
    return reforward.forward();
}
```

## File Upload

```java
@Action("upload")
public String uploadFile(Request request, Response response) {
    List<FileEntity> files = request.getAttachments();

    if (files != null && !files.isEmpty()) {
        FileEntity file = files.get(0);
        String filename = file.getFilename();

        // Set path to save the file
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

            // Set content type to JSON
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));

            // Create success response
            Builder builder = new Builder();
            builder.put("success", true);
            builder.put("filename", filename);

            return builder.toString();
        } catch (IOException e) {
            // Set content type to JSON
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));

            // Create error response
            Builder builder = new Builder();
            builder.put("success", false);
            builder.put("error", "Error uploading file: " + e.getMessage());

            return builder.toString();
        }
    }

    // Set content type to JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Create error response
    Builder builder = new Builder();
    builder.put("success", false);
    builder.put("error", "No file uploaded");

    return builder.toString();
}
```

## Error Handling

```java
@Action("api/resource")
public String getResource(Integer id, Request request, Response response) {
    try {
        Resource resource = resourceService.findById(id);

        if (resource == null) {
            throw new NotFoundException("Resource not found: " + id);
        }

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Use Builder to create JSON data
        Builder builder = new Builder();
        builder.put("resource", resource);

        return builder.toString();
    } catch (NotFoundException e) {
        // Set error status code
        response.setStatus(ResponseStatus.NOT_FOUND);
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create error response
        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    } catch (Exception e) {
        logger.error("Error retrieving resource", e);

        // Set error status code
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create error response
        Builder builder = new Builder();
        builder.put("error", "Internal server error");

        return builder.toString();
    }
}
```

## Security

### CSRF Protection

```java
@Action("form")
public String showForm(Request request) {
    // Generate CSRF token
    String csrfToken = UUID.randomUUID().toString();

    // Store token in session
    request.getSession(true).setAttribute("csrf_token", csrfToken);

    // Set token for the template
    this.setVariable("csrfToken", csrfToken);

    // Return this instance, the template will be automatically selected
    return this;
}

@Action("submit")
public Object processForm(Request request, Response response) {
    String csrfToken = request.getParameter("csrf_token");
    String storedToken = (String) request.getSession(false).getAttribute("csrf_token");

    if (storedToken == null || !storedToken.equals(csrfToken)) {
        // Set error status code
        response.setStatus(ResponseStatus.FORBIDDEN);

        // Set error message for the template
        this.setVariable("error", "Invalid CSRF token");

        // Return this instance, the template will be automatically selected
        return this;
    }

    // Process form

    // Redirect to success page
    Reforward reforward = new Reforward(request, response);
    reforward.setDefault("/?q=success");
    return reforward.forward();
}
```

### Authentication and Authorization

```java
@Action("admin/users")
public Object adminUsers(Request request, Response response) {
    // Check if user is authenticated
    Session session = request.getSession(false);
    if (session == null || session.getAttribute("user") == null) {
        // Redirect to login page
        Reforward reforward = new Reforward(request, response);
        reforward.setDefault("/?q=login");
        return reforward.forward();
    }

    // Check if user has admin role
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("ADMIN")) {
        // Set error status code
        response.setStatus(ResponseStatus.FORBIDDEN);

        // Set error message for the template
        this.setVariable("error", "Access denied");

        // Return error template
        return "error";
    }

    // Get users from service
    List<User> users = userService.findAll();

    // Set users for the template
    for (int i = 0; i < users.size(); i++) {
        User user = users.get(i);
        this.setVariable("user_" + i + "_id", String.valueOf(user.getId()));
        this.setVariable("user_" + i + "_name", user.getName());
        this.setVariable("user_" + i + "_email", user.getEmail());
    }
    this.setVariable("user_count", String.valueOf(users.size()));

    // Return this instance, the template will be automatically selected
    return this;
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
