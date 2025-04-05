# Core Concepts

## Application Structure

### AbstractApplication

The base class for all tinystruct applications. It provides:

- Configuration management
- Action handling
- Request/response processing
- Database connections

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Initialize application
    }

    @Override
    public String version() {
        return "1.0.0";
    }
}
```

## Actions

Actions are the core building blocks of tinystruct applications. They handle both web requests and CLI commands.

### Action Annotation

```java
@Action(
    value = "endpoint",           // URL pattern or command name
    description = "Description",  // Action description
    mode = Action.Mode.ALL       // Execution mode (ALL, WEB, CLI)
)
```

### URL Patterns

```java
@Action("users")    // Automatically matches /users, /users/123, /users/123/posts
```

Tinystruct automatically matches the right functionality based on the URL pattern. There's no need to define variables like `{id}` in the @Action annotation. The framework intelligently routes requests to the appropriate method based on the parameters.

## Configuration

### Properties File

```properties
# Application settings
application.name=MyApp
application.mode=development

# Server settings
server.port=8080
server.host=localhost

# Database settings
database.type=MySQL
database.url=jdbc:mysql://localhost:3306/mydb
```

### Accessing Configuration

```java
String appName = getConfiguration().get("application.name");
int port = Integer.parseInt(getConfiguration().get("server.port"));
```

## Database Integration

### Repository Types

- MySQL
- SQLite
- H2
- Redis
- Microsoft SQL Server

### Basic Usage

```java
Repository repository = Type.MySQL.createRepository();
repository.connect(getConfiguration());

// Execute query
List<Row> results = repository.query("SELECT * FROM users");

// Execute update
repository.execute("UPDATE users SET name = ? WHERE id = ?",
                  "John Doe", 1);
```

## Request Handling

### Web Requests

```java
@Action("api/data")
public String getData(Request request, Response response) {
    String param = request.getParameter("key");

    // Set content type to JSON
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Create JSON response
    Builder builder = new Builder();
    builder.put("key", param);

    return builder.toString();
}
```

### CLI Commands

```java
@Action(value = "generate",
        description = "Generate POJO objects",
        mode = Action.Mode.CLI)
public void generate() {
    // Command implementation
}
```

## Security

### Authentication

```java
@Action("secure/endpoint")
public Response secureEndpoint(Request request) {
    if (!isAuthenticated(request)) {
        throw new UnauthorizedException();
    }
    // Protected code
}
```

### Authorization

```java
@Action("admin/users")
public Response adminOnly(Request request) {
    if (!hasRole(request, "ADMIN")) {
        throw new ForbiddenException();
    }
    // Admin-only code
}
```

## Error Handling

```java
try {
    // Your code
} catch (ApplicationException e) {
    logger.log(Level.SEVERE, e.getMessage(), e);
    throw new ApplicationRuntimeException(e.getMessage(), e);
}
```

## Next Steps

- Learn about [Web Applications](web-applications.md)
- Explore [Database Integration](database.md)
- Check out [CLI Applications](cli-applications.md)
