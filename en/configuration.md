# Configuration in tinystruct

This guide explains how to configure tinystruct applications using properties files and the Configuration API.

## Configuration Basics

tinystruct uses a simple key-value configuration system that is loaded from properties files. The configuration is accessible throughout your application via the `getConfiguration()` method in the `AbstractApplication` class.

## Configuration Files

By default, tinystruct looks for a file named `config.properties` in the classpath. You can also specify a different configuration file when starting your application.

### Basic Configuration File

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

# Default settings
default.file.encoding=UTF-8
default.home.page=welcome
default.reload.mode=true
default.date.format=yyyy-MM-dd HH:mm:ss

# Error handling
default.error.process=false
default.error.page=error

# HTTP configuration
default.http.max_content_length=4194304
```

## Accessing Configuration

### In Application Code

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Get configuration values
        String appName = getConfiguration().get("application.name");
        int port = Integer.parseInt(getConfiguration().get("server.port"));
        boolean devMode = "development".equals(getConfiguration().get("application.mode"));
        
        // Use configuration values
        System.out.println("Starting " + appName + " on port " + port);
        
        if (devMode) {
            System.out.println("Running in development mode");
        }
    }
}
```

### Default Values

You can provide default values when accessing configuration properties:

```java
String encoding = getConfiguration().get("default.file.encoding", "UTF-8");
int maxConnections = Integer.parseInt(getConfiguration().get("database.connections.max", "5"));
```

## Environment-Specific Configuration

You can create different configuration files for different environments:

### Development Configuration

```properties
# config.dev.properties
application.mode=development
server.port=8080
logging.level=DEBUG
```

### Production Configuration

```properties
# config.prod.properties
application.mode=production
server.port=80
logging.level=INFO
```

### Loading Environment-Specific Configuration

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        String env = System.getProperty("env", "dev");
        getConfiguration().load("config." + env + ".properties");
        
        System.out.println("Loaded configuration for " + env + " environment");
    }
}
```

## Dynamic Configuration

You can update configuration values at runtime:

```java
@Action("set-config")
public String setConfig(String key, String value) {
    getConfiguration().set(key, value);
    return "Configuration updated: " + key + " = " + value;
}
```

## Configuration API

### Loading Configuration

```java
// Load from default location
getConfiguration().load();

// Load from specific file
getConfiguration().load("custom-config.properties");

// Load from URL
getConfiguration().load(new URL("http://config-server/app-config.properties"));
```

### Getting Configuration Values

```java
// Get string value
String value = getConfiguration().get("key");

// Get string value with default
String value = getConfiguration().get("key", "default");

// Get integer value
int intValue = getConfiguration().getInt("key");

// Get integer value with default
int intValue = getConfiguration().getInt("key", 0);

// Get boolean value
boolean boolValue = getConfiguration().getBoolean("key");

// Get boolean value with default
boolean boolValue = getConfiguration().getBoolean("key", false);
```

### Setting Configuration Values

```java
// Set string value
getConfiguration().set("key", "value");

// Set integer value
getConfiguration().set("key", 123);

// Set boolean value
getConfiguration().set("key", true);
```

### Checking Configuration

```java
// Check if key exists
boolean exists = getConfiguration().contains("key");

// Get all configuration keys
Set<String> keys = getConfiguration().keySet();

// Get configuration as Properties object
Properties props = getConfiguration().getProperties();
```

## Common Configuration Properties

### Application Settings

| Property | Description | Default |
|----------|-------------|---------|
| application.name | Application name | - |
| application.mode | Application mode (development, production) | development |
| application.version | Application version | - |

### Server Settings

| Property | Description | Default |
|----------|-------------|---------|
| server.port | HTTP server port | 8080 |
| server.host | HTTP server host | localhost |
| server.context | Server context path | / |
| server.threads | Server thread pool size | 10 |

### Database Settings

| Property | Description | Default |
|----------|-------------|---------|
| driver | JDBC driver class | - |
| database.url | Database URL | - |
| database.user | Database username | - |
| database.password | Database password | - |
| database.connections.max | Maximum database connections | 10 |

### Default Settings

| Property | Description | Default |
|----------|-------------|---------|
| default.file.encoding | Default file encoding | UTF-8 |
| default.home.page | Default home page | - |
| default.reload.mode | Enable reload mode | false |
| default.date.format | Default date format | yyyy-MM-dd HH:mm:ss |
| default.error.process | Enable error processing | false |
| default.error.page | Default error page | error |
| default.http.max_content_length | Maximum HTTP content length | 4194304 |

### Logging Settings

| Property | Description | Default |
|----------|-------------|---------|
| logging.override | Override logging configuration | false |
| handlers | Log handlers | java.util.logging.ConsoleHandler |
| java.util.logging.ConsoleHandler.level | Console handler log level | FINE |
| java.util.logging.ConsoleHandler.formatter | Console handler formatter | org.apache.juli.OneLineFormatter |
| java.util.logging.ConsoleHandler.encoding | Console handler encoding | UTF-8 |

## Best Practices

1. **Environment Variables**: Use environment variables for sensitive information like database passwords.

2. **Configuration Hierarchy**: Implement a configuration hierarchy (default → environment-specific → command-line overrides).

3. **Validation**: Validate configuration values at startup to fail fast if required properties are missing.

4. **Documentation**: Document all configuration properties used by your application.

5. **Defaults**: Provide sensible defaults for optional configuration properties.

## Next Steps

- Learn about [Database Integration](database.md)
- Explore [Advanced Features](advanced-features.md)
- Check out [Best Practices](best-practices.md)
