# What's New in tinystruct 1.7.17

This document highlights the new features, improvements, and changes introduced in tinystruct version 1.7.17.

## Major New Features

### 1. HTTP Method-Specific Actions

You can now specify which HTTP methods an action responds to, enabling proper RESTful API design:

```java
@Action(value = "users", mode = Mode.HTTP_GET)
public String getUsers() {
    return userService.findAll().toString();
}

@Action(value = "users", mode = Mode.HTTP_POST)
public String createUser(Request request) {
    String name = request.getParameter("name");
    return userService.create(name).toString();
}

@Action(value = "users", mode = Mode.HTTP_PUT)
public String updateUser(Integer id, Request request) {
    String name = request.getParameter("name");
    return userService.update(id, name).toString();
}

@Action(value = "users", mode = Mode.HTTP_DELETE)
public String deleteUser(Integer id) {
    userService.delete(id);
    return "User deleted";
}
```

**Available HTTP Method Modes:**
- `Mode.HTTP_GET`
- `Mode.HTTP_POST`
- `Mode.HTTP_PUT`
- `Mode.HTTP_DELETE`
- `Mode.HTTP_PATCH`
- `Mode.HTTP_HEAD`
- `Mode.HTTP_OPTIONS`

### 2. AI Integration and MCP Support

Built-in support for AI integration with Model Context Protocol (MCP):

```properties
# MCP configuration in config.properties
mcp.auth.token=your_token_here
```

**Benefits:**
- Easy integration with AI models
- Standardized protocol for model communication
- Plugin-based architecture for AI extensions
- Support for custom AI providers

**Example AI Integration:**

```java
@Action("ai/chat")
public String chat(String message) {
    // Use MCP to communicate with AI models
    return aiService.chat(message);
}
```

### 3. Server-Sent Events (SSE) Support

Native support for Server-Sent Events for real-time data streaming:

```java
@Action(value = "stream", mode = Mode.HTTP_GET)
public void streamData(Request request, Response response) {
    response.setHeader("Content-Type", "text/event-stream");
    response.setHeader("Cache-Control", "no-cache");
    
    // Stream real-time data
    while (shouldContinue()) {
        String data = getLatestData();
        response.write("data: " + data + "\n\n");
        response.flush();
        Thread.sleep(1000);
    }
}
```

**Use Cases:**
- Real-time notifications
- Live data feeds
- Progress updates
- Chat applications
- Stock tickers

### 4. Enhanced Plugin Architecture

Improved modular design for plugin-based applications:

```java
// Plugin interface
public interface Plugin {
    void initialize(Application app);
    void start();
    void stop();
}

// Plugin implementation
public class MyPlugin implements Plugin {
    @Override
    public void initialize(Application app) {
        // Plugin initialization
    }
}
```

**Benefits:**
- Dynamic plugin loading
- Hot-swappable components
- Extensible architecture
- Isolated plugin contexts

### 5. Multiple Server Support

Enhanced support for multiple HTTP servers with improved performance:

**Netty Server (Recommended)**
```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```
- 86,000+ requests/second
- Async I/O
- WebSocket support
- SSE support

**Tomcat Server**
```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```
- Traditional servlet support
- JSP support
- Enterprise compatibility

**Undertow Server**
```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```
- Lightweight footprint
- Non-blocking I/O
- Embedded-friendly

## Performance Improvements

### Benchmark Results

Version 1.7.17 achieves exceptional performance:

```
Running 30s test @ http://127.0.0.1:8080/?q=say/Praise the Lord!
12 threads and 400 connections

Thread Stats   Avg      Stdev     Max       +/- Stdev
Latency        17.44ms  33.42ms   377.73ms  88.98%
Req/Sec        7.27k    1.66k     13.55k    69.94%

2,604,473 requests in 30.02s, 524.09MB read

Requests/sec:  86,753.98
Transfer/sec:  17.46MB
```

**Key Metrics:**
- **Throughput**: 86,753 requests/second
- **Latency**: 17.44ms average
- **Consistency**: 88.98% within one standard deviation
- **Memory**: 524MB over 30 seconds (17.46MB/s)

### Performance Optimizations

1. **Zero Overhead Architecture**
   - No reflection-based bean scanning
   - Direct method invocation
   - Minimal interceptor chain

2. **Efficient Memory Management**
   - Small memory footprint
   - No excessive object creation
   - Optimized garbage collection

3. **Smart Routing**
   - Compiled pattern matching
   - Fast URL parsing
   - Cached route resolution

## Architecture Enhancements

### 1. No main() Method Required

Applications can be started directly without a main() method:

```java
// No main() method needed!
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Just initialization
    }
}
```

**Start with CLI:**
```bash
bin/dispatcher start --import com.example.MyApp
```

### 2. Unified CLI and Web Design

Same code works for both CLI and Web:

```java
@Action(value = "greet", mode = Mode.ALL)
public String greet(String name) {
    return "Hello, " + name + "!";
}

// CLI: bin/dispatcher greet/John
// Web: http://localhost:8080/?q=greet/John
```

### 3. Modular Design

Clean separation of concerns:

```
Application Layer
    ↓
Action Layer (Routes/Commands)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Database Layer
```

## API Improvements

### Enhanced Builder API

Improved JSON building with Builder class:

```java
Builder builder = new Builder();
builder.put("success", true);
builder.put("data", dataObject);
builder.put("timestamp", System.currentTimeMillis());

// Nested objects
Builder nested = new Builder();
nested.put("id", 123);
nested.put("name", "John");
builder.put("user", nested);

// Arrays
Builders array = new Builders();
array.add("item1");
array.add("item2");
builder.put("items", array);

String json = builder.toString();
```

### Improved DatabaseOperator

Enhanced database operations with better resource management:

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // Automatic resource cleanup
    ResultSet results = operator.query("SELECT * FROM users");
    // Process results
} // Resources automatically closed
```

## Breaking Changes

### None

Version 1.7.17 maintains backward compatibility with previous 1.7.x versions. All existing code should continue to work without modifications.

## Migration Guide

### From 1.7.15 to 1.7.17

1. **Update Maven Dependency**
   ```xml
   <dependency>
       <groupId>org.tinystruct</groupId>
       <artifactId>tinystruct</artifactId>
       <version>1.7.17</version>
   </dependency>
   ```

2. **Optional: Use New HTTP Method-Specific Actions**
   ```java
   // Old way (still works)
   @Action("users")
   public String getUsers() { ... }
   
   // New way (recommended for RESTful APIs)
   @Action(value = "users", mode = Mode.HTTP_GET)
   public String getUsers() { ... }
   ```

3. **Optional: Add MCP Configuration**
   ```properties
   # config.properties
   mcp.auth.token=your_token_here
   ```

## Community and Resources

- **GitHub**: <https://github.com/tinystruct/tinystruct>
- **Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
- **Smalltalk (AI Chat)**: <https://github.com/tinystruct/smalltalk>

## What's Next

### Planned for Future Releases

- Enhanced reactive programming support
- GraphQL integration
- gRPC support
- Kubernetes native features
- Enhanced monitoring and metrics
- WebAssembly support

## Conclusion

Version 1.7.17 represents a significant step forward for the tinystruct framework, adding modern features like HTTP method-specific actions, AI integration, and SSE support while maintaining the framework's core philosophy of simplicity, performance, and ease of use.

The framework continues to deliver exceptional performance (86,000+ req/s) while remaining lightweight and developer-friendly. With no main() method required and unified CLI/Web support, tinystruct makes Java application development faster and more enjoyable.

Try it today and experience the difference!
