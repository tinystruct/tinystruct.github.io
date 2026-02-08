# Getting Started with tinystruct

This guide will help you set up your first tinystruct application and understand the basic workflow.

## Prerequisites

- Java Development Kit (JDK) 17 or higher
- Maven (for dependency management)
- A text editor or IDE (IntelliJ IDEA, Eclipse, VS Code, etc.)

## Installation

### Option 1: Using the tinystruct Archetype (Recommended)

The fastest way to create a tinystruct project is using the official archetype:

```bash
# Visit and follow the instructions at:
# https://github.com/tinystruct/tinystruct-archetype
```

This will automatically set up a complete project structure with all necessary dependencies and configurations.

### Option 2: Maven Dependency

Add the tinystruct dependency to your project's `pom.xml` file:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.17</version>
    <classifier>jar-with-dependencies</classifier>
</dependency>
```

### Option 3: Manual Installation

Alternatively, you can download the JAR file directly from the [Maven Repository](https://mvnrepository.com/artifact/org.tinystruct/tinystruct) and add it to your project's classpath.

## Creating Your First Application

### 1. Create a Basic Application Class

Create a new Java class that extends `AbstractApplication`:

```java
package com.example;

import org.tinystruct.AbstractApplication;
import org.tinystruct.system.annotation.Action;
import org.tinystruct.system.annotation.Action.Mode;

public class HelloWorldApp extends AbstractApplication {

    @Override
    public void init() {
        // Initialization code
        System.out.println("Initializing HelloWorldApp...");
    }

    @Override
    public String version() {
        return "1.0.0";
    }

    @Action("hello")
    public String hello() {
        return "Hello, World!";
    }

    @Action("hello")
    public String hello(String name) {
        return "Hello, " + name + "!";
    }

    // HTTP method-specific actions (new in 1.7.17)
    @Action(value = "greet", mode = Mode.HTTP_GET)
    public String greetGet() {
        return "GET: Hello!";
    }

    @Action(value = "greet", mode = Mode.HTTP_POST)
    public String greetPost() {
        return "POST: Hello!";
    }
}
```

### 2. Create a Configuration File

Create a `config.properties` file in your project's resources directory:

```properties
# Application settings
application.name=HelloWorldApp
application.mode=development

# Server settings
server.port=8080
server.host=localhost

# Default settings
default.file.encoding=UTF-8
default.home.page=hello/World
default.reload.mode=true
default.date.format=yyyy-MM-dd HH:mm:ss

# HTTP configuration
default.http.max_content_length=4194304
```

### 3. Running as a CLI Application

You can run your application from the command line using the tinystruct dispatcher:

```bash
# Display version
bin/dispatcher --version

# Display help
bin/dispatcher --help

# Run the hello action
bin/dispatcher hello --import com.example.HelloWorldApp

# Run with a parameter
bin/dispatcher hello/John --import com.example.HelloWorldApp
```

### 4. Running as a Web Application

To run your application as a web server:

#### Using Netty (Recommended for high performance)

```bash
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --import com.example.HelloWorldApp
```

#### Using Tomcat

```bash
bin/dispatcher start --import org.tinystruct.system.TomcatServer --import com.example.HelloWorldApp
```

#### Using Undertow

```bash
bin/dispatcher start --import org.tinystruct.system.UndertowServer --import com.example.HelloWorldApp
```

Then access your application at:
- http://localhost:8080/?q=hello
- http://localhost:8080/?q=hello/John
- http://localhost:8080/?q=greet (GET request)

## Understanding the Framework

### No main() Method Required

Unlike traditional Java applications, tinystruct doesn't require a `main()` method. Applications are started directly using the CLI dispatcher, which removes unnecessary boilerplate code.

### Action-Based Routing

The `@Action` annotation defines routes and commands:

```java
@Action("users")              // Matches /users, /users/123, /users/123/posts
@Action(value = "api/data", mode = Mode.HTTP_GET)  // HTTP GET only
```

The framework automatically:
- Routes requests based on URL patterns
- Extracts parameters from URLs
- Maps them to method parameters

### HTTP Method-Specific Actions

New in version 1.7.17, you can specify which HTTP methods an action responds to:

```java
@Action(value = "resource", mode = Mode.HTTP_GET)
public String getResource() { ... }

@Action(value = "resource", mode = Mode.HTTP_POST)
public String createResource() { ... }

@Action(value = "resource", mode = Mode.HTTP_PUT)
public String updateResource() { ... }

@Action(value = "resource", mode = Mode.HTTP_DELETE)
public String deleteResource() { ... }
```

## Project Structure

A typical tinystruct project structure looks like this:

```
my-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── HelloWorldApp.java
│   │   │           ├── actions/
│   │   │           ├── models/
│   │   │           ├── services/
│   │   │           └── repositories/
│   │   └── resources/
│   │       ├── config.properties
│   │       └── templates/
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── HelloWorldAppTest.java
├── bin/
│   └── dispatcher
└── pom.xml
```

## Performance Considerations

tinystruct is designed for high performance:

- **86,000+ requests/second** throughput
- **~17ms average latency** under load
- **Zero overhead** - no reflection-based scanning
- **Direct method invocation** - no proxy layers
- **Minimal memory footprint**

## Next Steps

- Learn about [Core Concepts](core-concepts.md)
- Explore [Web Applications](web-applications.md)
- Check out [CLI Applications](cli-applications.md)
- Understand [Configuration](configuration.md)
- Dive into [Database Integration](database.md)
- Review [Advanced Features](advanced-features.md)
- Follow [Best Practices](best-practices.md)

## Examples and Resources

- **Smalltalk Project**: <https://github.com/tinystruct/smalltalk>
  A complete chat application with OpenAI GPT integration
- **tinystruct Examples**: <https://github.com/tinystruct/tinystruct-examples>
  Various example applications demonstrating framework features
- **Main Repository**: <https://github.com/tinystruct/tinystruct>
  The framework source code and documentation
