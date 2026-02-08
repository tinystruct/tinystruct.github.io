# Advanced Features in tinystruct

This guide covers advanced features and techniques in the tinystruct framework.

## Event System

tinystruct includes a powerful event system that allows components to communicate without direct coupling.

### Event Dispatcher

```java
// Get the event dispatcher instance
EventDispatcher dispatcher = EventDispatcher.getInstance();

// Register an event handler
dispatcher.registerHandler(UserCreatedEvent.class, event -> {
    User user = event.getPayload();
    System.out.println("User created: " + user.getName());

    // Send welcome email
    emailService.sendWelcomeEmail(user.getEmail());
});

// Dispatch an event
User newUser = userService.createUser("john@example.com", "password");
dispatcher.dispatch(new UserCreatedEvent(newUser));
```

### Custom Events

```java
public class UserCreatedEvent implements Event<User> {
    private final User user;

    public UserCreatedEvent(User user) {
        this.user = user;
    }

    @Override
    public User getPayload() {
        return user;
    }
}
```

### Application Lifecycle Events

```java
public class MyApp extends AbstractApplication {
    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();

    static {
        // Register application startup handler
        dispatcher.registerHandler(ApplicationStartEvent.class, event -> {
            System.out.println("Application started: " + event.getPayload().getName());
        });

        // Register application shutdown handler
        dispatcher.registerHandler(ApplicationShutdownEvent.class, event -> {
            System.out.println("Application shutting down: " + event.getPayload().getName());
        });
    }

    @Override
    public void init() {
        // Dispatch startup event
        dispatcher.dispatch(new ApplicationStartEvent(this));

        // Register shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            dispatcher.dispatch(new ApplicationShutdownEvent(this));
        }));
    }
}
```

## Command Line Interface (CLI)

Tinystruct provides a powerful command-line interface through its dispatcher system, allowing you to execute actions from the command line.

### Basic CLI Usage

```bash
# Execute an action with parameters
bin/dispatcher say/"Hello World"

# Execute with named parameters
bin/dispatcher say --words "Hello World" --import tinystruct.examples.example
```

### Creating CLI Commands

You can create custom CLI commands by adding the `Action.Mode.CLI` mode to your action annotations:

```java
@Action(value = "generate",
        description = "POJO object generator",
        mode = Action.Mode.CLI)
public String generatePOJO(String table) {
    // Implementation for generating POJO from database table
    return "Generated POJO for table: " + table;
}
```

### Built-in CLI Commands

Tinystruct includes several built-in CLI commands:

- `download`: Download resources from other servers
- `exec`: Execute native commands
- `generate`: Generate POJO objects
- `install`: Install packages
- `maven-wrapper`: Extract Maven Wrapper
- `open`: Open URLs in the default browser
- `say`: Output words
- `set`: Set system properties
- `sql-execute`: Execute SQL statements
- `sql-query`: Execute SQL queries
- `update`: Update to the latest version

## HTTP Server Integration

Tinystruct supports multiple HTTP server implementations, allowing you to choose the one that best fits your needs.

### Netty Server

```java
// Start a Netty HTTP server
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer
```

### Tomcat Server

```java
// Start a Tomcat server
bin/dispatcher start --import org.tinystruct.system.TomcatServer
```

### Undertow Server

```java
// Start an Undertow server
bin/dispatcher start --import org.tinystruct.system.UndertowServer
```

## Context Management

The Context system in Tinystruct allows you to share data between different parts of your application.

```java
// Set a context attribute
getContext().setAttribute("user", currentUser);

// Get a context attribute
User user = (User) getContext().getAttribute("user");

// Get with default value
String theme = (String) getContext().getAttribute("theme", "default");
```

## Configuration Management

Tinystruct provides a flexible configuration system that allows you to manage application settings.

```java
// Get configuration value
String appName = getConfiguration().get("application.name");

// Set configuration value
getConfiguration().set("application.mode", "development");

// Load configuration from file
getConfiguration().load("config.properties");
```

## Database Operations

Tinystruct offers advanced database operations through the DatabaseOperator class.

### Transaction Management

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // Begin transaction
    operator.beginTransaction();

    try {
        // Execute database operations
        PreparedStatement stmt1 = operator.preparedStatement(
            "INSERT INTO users (name) VALUES (?)",
            new Object[]{"John"}
        );
        operator.executeUpdate(stmt1);

        // Commit transaction
        operator.commitTransaction();
    } catch (Exception e) {
        // Rollback transaction
        operator.rollbackTransaction();
        throw e;
    }
}
```

### Using Savepoints

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // Begin transaction
    operator.beginTransaction();

    // Execute first operation
    operator.executeUpdate("INSERT INTO users (name) VALUES ('John')");

    // Create savepoint
    Savepoint savepoint = operator.createSavepoint("AFTER_INSERT");

    try {
        // Execute second operation
        operator.executeUpdate("UPDATE settings SET value = 'new_value'");
    } catch (Exception e) {
        // Roll back to savepoint
        operator.rollbackTransaction(savepoint);
    }

    // Commit transaction
    operator.commitTransaction();
}
```

## Object-Relational Mapping

Tinystruct provides a simple object-relational mapping system through the AbstractData class.

```java
// Define a model class
public class User extends AbstractData {
    private int id;
    private String name;
    private String email;

    // Getters and setters
    // ...
}

// Create XML mapping file in resources directory
// user.map.xml:
// <mapping>
//     <class name="com.example.model.User" table="users">
//         <property name="id" column="id" type="int" identifier="true"/>
//         <property name="name" column="name" type="string"/>
//         <property name="email" column="email" type="string"/>
//     </class>
// </mapping>

// Use the model
User user = new User();
user.setName("John Doe");
user.setEmail("john@example.com");
user.append(); // Insert into database

// Find by ID
User foundUser = new User();
foundUser.setId(1);
foundUser.findOneById();

// Update
foundUser.setName("Jane Doe");
foundUser.update();

// Delete
foundUser.delete();

// Find all
List<User> allUsers = user.findAll();

// Find with condition
List<User> filteredUsers = user.findWhere("name LIKE ?", "%Doe%");

## JSON Data Handling

Tinystruct provides utilities for working with JSON data through the Builder and Builders classes.

```java
// Create JSON data
Builder builder = new Builder();
builder.put("name", "John Doe");
builder.put("age", 30);

// Create nested objects
Builder addressBuilder = new Builder();
addressBuilder.put("street", "123 Main St");
addressBuilder.put("city", "Anytown");
builder.put("address", addressBuilder);

// Create arrays
Builders hobbiesBuilder = new Builders();
hobbiesBuilder.add("Reading");
hobbiesBuilder.add("Hiking");
builder.put("hobbies", hobbiesBuilder);

// Convert to JSON string
String json = builder.toString();

// Parse JSON string
Builder parsedBuilder = new Builder();
parsedBuilder.parse(json);

// Access JSON data
String name = parsedBuilder.get("name").toString();
int age = Integer.parseInt(parsedBuilder.get("age").toString());
Builder address = (Builder) parsedBuilder.get("address");
String city = address.get("city").toString();
Builders hobbies = (Builders) parsedBuilder.get("hobbies");
String firstHobby = hobbies.get(0).toString();
```

## Internationalization (i18n)

Tinystruct supports internationalization for building multilingual applications.

```java
// Get locale from request
Locale locale = request.getLocale();

// Get message bundle for locale
ResourceBundle bundle = ResourceBundle.getBundle("messages", locale);

// Get message with parameters
String greeting = MessageFormat.format(
    bundle.getString("greeting"),
    "John"
);
```

## AI Integration

New in version 1.7.17, tinystruct includes built-in support for AI integration, specifically designed to work with the Model Context Protocol (MCP).

### MCP Integration

To use MCP (Model Context Protocol) features, you first need to configure your authentication token:

```properties
# config.properties
mcp.auth.token=your_mcp_token_here
```

Then you can build AI-enabled actions:

```java
@Action("ai/generate")
public String generateContent(String prompt) {
    // Basic example of handling AI requests
    // detailed implementation depends on specific MCP client usage
    return "Generated content for: " + prompt;
}
```

## Server-Sent Events (SSE)

tinystruct 1.7.17 introduces native support for Server-Sent Events, making it easy to build real-time applications like chat interfaces or live feeds.

```java
@Action(value = "stream", mode = Mode.HTTP_GET)
public void streamData(Request request, Response response) throws InterruptedException {
    // Set proper headers for SSE
    response.setHeader("Content-Type", "text/event-stream");
    response.setHeader("Cache-Control", "no-cache");
    response.setHeader("Connection", "keep-alive");
    
    // Simulate streaming data
    for (int i = 0; i < 5; i++) {
        String data = "data: {\"time\": \"" + new Date() + "\", \"count\": " + i + "}\n\n";
        response.write(data);
        
        // In a real app, you might wait for events instead of sleeping
        Thread.sleep(1000);
    }
    
    response.write("event: close\ndata: end\n\n");
}
```

## Best Practices

1. **Action Organization**: Group related actions in separate classes for better organization.

2. **Error Handling**: Implement proper error handling for both CLI and web applications.

3. **Configuration Management**: Use environment-specific configuration files for different environments.

4. **Database Connections**: Always use try-with-resources for database operations to ensure proper resource cleanup.

5. **Transaction Management**: Use transactions for operations that require atomicity.

## Next Steps

- Explore the [API Reference](api/README.md)
- Check out the [Best Practices](best-practices.md) guide
