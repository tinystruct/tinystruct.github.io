# Configuration API Reference

## Configuration Interface

The `Configuration` interface provides methods for managing application configuration properties.

### Interface Definition

```java
public interface Configuration {
    // Core methods
    String get(String key);
    String get(String key, String defaultValue);
    void set(String key, String value);
    boolean contains(String key);
    void remove(String key);
    
    // Loading methods
    void load();
    void load(String file);
    void load(URL url);
    
    // Type-specific getters
    int getInt(String key);
    int getInt(String key, int defaultValue);
    boolean getBoolean(String key);
    boolean getBoolean(String key, boolean defaultValue);
    double getDouble(String key);
    double getDouble(String key, double defaultValue);
    
    // Collection methods
    Set<String> keySet();
    Properties getProperties();
}
```

## Core Methods

### Getting Values

| Method | Return Type | Description |
|--------|-------------|-------------|
| get(String) | String | Get a string value for the specified key |
| get(String, String) | String | Get a string value with a default value |
| getInt(String) | int | Get an integer value |
| getInt(String, int) | int | Get an integer value with a default |
| getBoolean(String) | boolean | Get a boolean value |
| getBoolean(String, boolean) | boolean | Get a boolean value with a default |
| getDouble(String) | double | Get a double value |
| getDouble(String, double) | double | Get a double value with a default |

```java
// Get string value
String appName = configuration.get("application.name");

// Get string with default
String encoding = configuration.get("default.file.encoding", "UTF-8");

// Get integer value
int port = configuration.getInt("server.port");

// Get integer with default
int maxConnections = configuration.getInt("database.connections.max", 10);

// Get boolean value
boolean devMode = configuration.getBoolean("application.development");

// Get boolean with default
boolean reloadMode = configuration.getBoolean("default.reload.mode", false);

// Get double value
double threshold = configuration.getDouble("performance.threshold");

// Get double with default
double factor = configuration.getDouble("scaling.factor", 1.5);
```

### Setting Values

| Method | Return Type | Description |
|--------|-------------|-------------|
| set(String, String) | void | Set a string value |
| set(String, int) | void | Set an integer value |
| set(String, boolean) | void | Set a boolean value |
| set(String, double) | void | Set a double value |

```java
// Set string value
configuration.set("application.name", "MyApp");

// Set integer value
configuration.set("server.port", 8080);

// Set boolean value
configuration.set("application.development", true);

// Set double value
configuration.set("scaling.factor", 1.5);
```

### Checking and Removing

| Method | Return Type | Description |
|--------|-------------|-------------|
| contains(String) | boolean | Check if a key exists |
| remove(String) | void | Remove a key-value pair |

```java
// Check if key exists
if (configuration.contains("database.url")) {
    // Use database URL
}

// Remove a key
configuration.remove("temporary.setting");
```

## Loading Configuration

| Method | Return Type | Description |
|--------|-------------|-------------|
| load() | void | Load from default location |
| load(String) | void | Load from specified file path |
| load(URL) | void | Load from URL |

```java
// Load from default location
configuration.load();

// Load from specific file
configuration.load("config.properties");

// Load from URL
configuration.load(new URL("http://config-server/app-config.properties"));
```

## Collection Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| keySet() | Set<String> | Get all configuration keys |
| getProperties() | Properties | Get configuration as Properties object |

```java
// Get all keys
Set<String> keys = configuration.keySet();
for (String key : keys) {
    System.out.println(key + " = " + configuration.get(key));
}

// Get as Properties
Properties props = configuration.getProperties();
```

## DefaultConfiguration

The `DefaultConfiguration` class is the standard implementation of the `Configuration` interface.

```java
// Create a new configuration
Configuration configuration = new DefaultConfiguration();

// Load configuration
configuration.load("config.properties");

// Use configuration
String appName = configuration.get("application.name");
```

## Environment-Specific Configuration

```java
// Load base configuration
configuration.load("config.properties");

// Load environment-specific configuration
String env = System.getProperty("env", "dev");
configuration.load("config." + env + ".properties");
```

## System Property Integration

```java
// Override with system properties
String javaHome = configuration.get("java.home");
if (javaHome == null) {
    javaHome = System.getProperty("java.home");
}

// Set system property from configuration
System.setProperty("app.name", configuration.get("application.name"));
```

## Configuration Hierarchy

```java
// Create a hierarchical configuration
Configuration defaultConfig = new DefaultConfiguration();
defaultConfig.load("default-config.properties");

Configuration appConfig = new DefaultConfiguration();
appConfig.load("app-config.properties");

// Combine configurations
for (String key : defaultConfig.keySet()) {
    if (!appConfig.contains(key)) {
        appConfig.set(key, defaultConfig.get(key));
    }
}
```

## Best Practices

1. **Default Values**: Always provide default values for optional configuration properties.

```java
// Good: Provides default value
int timeout = configuration.getInt("connection.timeout", 30000);

// Bad: May throw exception if key doesn't exist
int timeout = configuration.getInt("connection.timeout");
```

2. **Configuration Validation**: Validate critical configuration values at startup.

```java
public void validateConfiguration() {
    // Check required properties
    String[] required = {"database.url", "database.user", "server.port"};
    
    List<String> missing = new ArrayList<>();
    for (String key : required) {
        if (!configuration.contains(key) || configuration.get(key).isEmpty()) {
            missing.add(key);
        }
    }
    
    if (!missing.isEmpty()) {
        throw new ApplicationException("Missing required configuration: " + String.join(", ", missing));
    }
    
    // Validate values
    int port = configuration.getInt("server.port");
    if (port < 1 || port > 65535) {
        throw new ApplicationException("Invalid server port: " + port);
    }
}
```

3. **Sensitive Information**: Avoid storing sensitive information in plain text.

```java
// Bad: Plain text password
configuration.set("database.password", "secret123");

// Better: Use environment variable
String dbPassword = System.getenv("DB_PASSWORD");
if (dbPassword == null) {
    dbPassword = configuration.get("database.password");
}
```

4. **Configuration Documentation**: Document all configuration properties.

```java
/**
 * Application configuration properties:
 * 
 * application.name - Application name
 * application.mode - Application mode (development, production)
 * server.port - HTTP server port (default: 8080)
 * server.host - HTTP server host (default: localhost)
 * database.url - Database connection URL
 * database.user - Database username
 * database.password - Database password
 * database.connections.max - Maximum database connections (default: 10)
 */
```

## MCP Configuration

| Property | Description | Default |
|----------|-------------|---------|
| mcp.auth.token | MCP authentication token | - |

## Related APIs


- [Application API](application.md)
- [Database API](database.md)
