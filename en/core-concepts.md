# Core Concepts

## Modern Framework Philosophy

tinystruct embodies a modern approach to Java application development:

1. **No main() method required** - Start applications directly with CLI commands
2. **Unified design for CLI and Web** - Write once, run anywhere
3. **Built-in lightweight servers** - Netty, Tomcat, or Undertow
4. **Minimal configuration** - No excessive XML or YAML
5. **Performance-first architecture** - Zero overhead design
6. **AI-ready** - Built for AI integration with MCP support

## Application Structure

### AbstractApplication

The base class for all tinystruct applications. It provides:

- Configuration management
- Action handling
- Request/response processing
- Database connections
- Event dispatching

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Initialize application
        System.out.println("Initializing MyApp...");
    }

    @Override
    public String version() {
        return "1.0.0";
    }
}
```

## Actions

Actions are the core building blocks of tinystruct applications. They handle both web requests and CLI commands through a unified mechanism.

### Action Annotation

```java
@Action(
    value = "endpoint",           // URL pattern or command name
    description = "Description",  // Action description
    mode = Action.Mode.ALL       // Execution mode
)
```

### HTTP Method-Specific Actions (New in 1.7.17)

You can now specify which HTTP methods an action responds to:

```java
@Action(value = "users", mode = Action.Mode.HTTP_GET)
public String getUsers() {
    // Handle GET request
    return "List of users";
}

@Action(value = "users", mode = Action.Mode.HTTP_POST)
public String createUser() {
    // Handle POST request
    return "User created";
}

@Action(value = "users", mode = Action.Mode.HTTP_PUT)
public String updateUser(Integer id) {
    // Handle PUT request
    return "User updated: " + id;
}

@Action(value = "users", mode = Action.Mode.HTTP_DELETE)
public String deleteUser(Integer id) {
    // Handle DELETE request
    return "User deleted: " + id;
}
```

### Available Action Modes

- `Mode.ALL` - Available in both CLI and Web
- `Mode.CLI` - CLI only
- `Mode.HTTP_GET` - HTTP GET requests only
- `Mode.HTTP_POST` - HTTP POST requests only
- `Mode.HTTP_PUT` - HTTP PUT requests only
- `Mode.HTTP_DELETE` - HTTP DELETE requests only
- `Mode.HTTP_PATCH` - HTTP PATCH requests only
- `Mode.HTTP_HEAD` - HTTP HEAD requests only
- `Mode.HTTP_OPTIONS` - HTTP OPTIONS requests only

### Intelligent URL Matching

```java
@Action("users")    // Automatically matches /users, /users/123, /users/123/posts
```

Tinystruct automatically:
- Matches URL patterns intelligently
- Extracts parameters from URLs
- Maps them to method parameters based on position and type
- No need to define path variables like `{id}` in annotations

Example:
```java
@Action("users")
public String getUser(Integer id) {
    // URL: /users/123
    // id = 123 (automatically extracted)
    return "User: " + id;
}

@Action("users")
public String getUserPosts(Integer userId, String postType) {
    // URL: /users/123/blog
    // userId = 123, postType = "blog"
    return "User " + userId + " posts of type: " + postType;
}
```

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
driver=org.h2.Driver
database.url=jdbc:h2:~/test
database.user=sa
database.password=
database.connections.max=10

# HTTP configuration
default.http.max_content_length=4194304
```

### Accessing Configuration

```java
String appName = getConfiguration().get("application.name");
int port = Integer.parseInt(getConfiguration().get("server.port", "8080"));
boolean devMode = "development".equals(getConfiguration().get("application.mode"));
```

## Server Options

### Netty Server (Recommended for High Performance)

```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```

**Best for:**
- High-throughput applications
- WebSocket support
- SSE (Server-Sent Events)
- Asynchronous I/O
- 86,000+ requests/second capability

### Tomcat Server

```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```

**Best for:**
- Traditional Java web applications
- Servlet-based applications
- JSP support
- Enterprise compatibility

### Undertow Server

```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```

**Best for:**
- Embedded applications
- Microservices
- Lightweight deployments
- Non-blocking I/O

## Database Integration

### Supported Databases

- MySQL
- PostgreSQL
- SQLite
- H2
- Microsoft SQL Server
- Oracle

### Basic Usage

```java
// Using DatabaseOperator (recommended)
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM users WHERE id = ?", id);
    // Process results
}

// Using Repository pattern
Repository repository = Type.MySQL.createRepository();
repository.connect(getConfiguration());
List<Row> results = repository.query("SELECT * FROM users");
```

## Request Handling

### Web Requests

```java
@Action(value = "api/data", mode = Mode.HTTP_GET)
public String getData(Request request, Response response) {
    String param = request.getParameter("key");

    // Set content type
    response.headers().add(Header.CONTENT_TYPE.set("application/json"));

    // Create JSON response using Builder
    Builder builder = new Builder();
    builder.put("key", param);
    builder.put("success", true);

    return builder.toString();
}
```

### CLI Commands

```java
@Action(value = "generate",
        description = "Generate POJO objects",
        mode = Action.Mode.CLI)
public String generate(String tableName) {
    // Command implementation
    return "Generated POJO for table: " + tableName;
}
```

## Event System

tinystruct includes a powerful event system for decoupled communication:

```java
// Register event handler
EventDispatcher dispatcher = EventDispatcher.getInstance();
dispatcher.registerHandler(UserCreatedEvent.class, event -> {
    User user = event.getPayload();
    System.out.println("User created: " + user.getName());
});

// Dispatch event
dispatcher.dispatch(new UserCreatedEvent(newUser));
```

## AI Integration

New in version 1.7.17, tinystruct includes built-in support for AI integration:

### MCP (Model Context Protocol) Support

```java
// MCP configuration in config.properties
mcp.auth.token=your_token_here

// Use MCP in your application
@Action("ai/chat")
public String chat(String message) {
    // Integration with AI models
    return aiService.processMessage(message);
}
```

### SSE (Server-Sent Events) Support

```java
@Action(value = "stream", mode = Mode.HTTP_GET)
public void streamData(Request request, Response response) {
    response.setHeader("Content-Type", "text/event-stream");
    response.setHeader("Cache-Control", "no-cache");
    
    // Stream data to client
    for (int i = 0; i < 10; i++) {
        response.write("data: " + i + "\n\n");
        Thread.sleep(1000);
    }
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

## Performance Characteristics

- **Throughput**: 86,000+ requests/second
- **Latency**: ~17ms average under load
- **Memory**: Minimal footprint
- **Overhead**: Zero reflection-based scanning
- **Method Invocation**: Direct (no proxies)

## Next Steps

- Learn about [Web Applications](web-applications.md)
- Explore [Database Integration](database.md)
- Check out [CLI Applications](cli-applications.md)
- Review [Advanced Features](advanced-features.md)
