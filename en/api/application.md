# Application API Reference

## AbstractApplication

The `AbstractApplication` class is the foundation of all tinystruct applications. It provides core functionality for configuration management, action handling, and application lifecycle.

### Class Definition

```java
public abstract class AbstractApplication implements Application {
    // ...
}
```

### Required Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| init() | void | Initialize the application |
| version() | String | Get the application version |

### Example

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

## Core Methods

### Configuration Management

| Method | Return Type | Description |
|--------|-------------|-------------|
| getConfiguration() | Configuration | Get the application configuration |
| setConfiguration(Configuration) | void | Set the application configuration |

```java
// Get configuration value
String appName = getConfiguration().get("application.name");

// Set configuration value
getConfiguration().set("application.mode", "development");
```

### Action Management

| Method | Return Type | Description |
|--------|-------------|-------------|
| execute(String, Object...) | Object | Execute an action by name with parameters |
| register(Class<?>) | void | Register an action class |
| getContext() | Context | Get the application context |

```java
// Execute an action
Object result = execute("hello", "World");

// Register an action class
register(UserActions.class);

// Get context attribute
String value = getContext().getAttribute("key");

// Set context attribute
getContext().setAttribute("key", "value");
```

### Application Lifecycle

| Method | Return Type | Description |
|--------|-------------|-------------|
| start() | void | Start the application |
| stop() | void | Stop the application |
| restart() | void | Restart the application |
| isRunning() | boolean | Check if the application is running |

```java
// Start the application
application.start();

// Check if running
if (application.isRunning()) {
    // Application is running
}

// Stop the application
application.stop();
```

## Application Interface

The `Application` interface defines the core contract for tinystruct applications.

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

The `ApplicationManager` class manages application instances and provides access to the current application.

### Static Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| getInstance() | ApplicationManager | Get the singleton instance |
| get(String) | Application | Get an application by name |
| register(String, Application) | void | Register an application |
| getCurrent() | Application | Get the current application |
| setCurrent(Application) | void | Set the current application |

```java
// Get application manager
ApplicationManager manager = ApplicationManager.getInstance();

// Register application
manager.register("myapp", new MyApp());

// Get application
Application app = manager.get("myapp");

// Set current application
manager.setCurrent(app);

// Get current application
Application current = manager.getCurrent();
```

## Context

The `Context` interface provides access to application context attributes.

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| getAttribute(String) | Object | Get an attribute by name |
| getAttribute(String, Object) | Object | Get an attribute with default value |
| setAttribute(String, Object) | void | Set an attribute |
| removeAttribute(String) | void | Remove an attribute |
| getAttributeNames() | Enumeration<String> | Get all attribute names |

```java
// Get context
Context context = application.getContext();

// Set attribute
context.setAttribute("user", currentUser);

// Get attribute
User user = (User) context.getAttribute("user");

// Get with default
String theme = (String) context.getAttribute("theme", "default");

// Remove attribute
context.removeAttribute("user");
```

## ApplicationException

The `ApplicationException` class is the base exception class for tinystruct applications.

```java
// Throw application exception
throw new ApplicationException("Something went wrong");

// Throw with cause
throw new ApplicationException("Database error", sqlException);

// Catch application exception
try {
    // Code that might throw ApplicationException
} catch (ApplicationException e) {
    System.err.println("Error: " + e.getMessage());
}
```

## ApplicationRuntimeException

The `ApplicationRuntimeException` class is an unchecked exception for tinystruct applications.

```java
// Throw runtime exception
throw new ApplicationRuntimeException("Unexpected error");

// Throw with cause
throw new ApplicationRuntimeException("Configuration error", configException);
```

## Best Practices

1. **Initialization**: Use the `init()` method to set up your application, register actions, and configure services.

```java
@Override
public void init() {
    // Register action classes
    register(UserActions.class);
    register(AuthActions.class);
    
    // Set up services
    ServiceRegistry.getInstance().register(UserService.class, new UserServiceImpl());
    
    // Configure event handlers
    EventDispatcher.getInstance().registerHandler(UserCreatedEvent.class, event -> {
        // Handle event
    });
}
```

2. **Version Management**: Implement proper versioning in the `version()` method.

```java
@Override
public String version() {
    return "1.2.3"; // Major.Minor.Patch
}
```

3. **Context Usage**: Use the context for request-scoped data, not for application configuration.

```java
// Good: Request-scoped data
getContext().setAttribute("requestId", UUID.randomUUID().toString());

// Bad: Application configuration
getContext().setAttribute("database.url", "jdbc:mysql://localhost:3306/mydb");
```

4. **Exception Handling**: Use appropriate exception types and provide meaningful error messages.

```java
// Good: Specific exception with clear message
throw new ApplicationException("User not found with ID: " + userId);

// Bad: Generic exception with unclear message
throw new ApplicationException("Error");
```

## Related APIs

- [Action API](action.md)
- [Configuration API](configuration.md)
- [Database API](database.md)
