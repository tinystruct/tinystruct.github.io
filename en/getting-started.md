# Getting Started with tinystruct

This guide will help you set up your first tinystruct application and understand the basic workflow.

## Prerequisites

- Java Development Kit (JDK) 17 or higher
- Maven (for dependency management)
- A text editor or IDE (IntelliJ IDEA, Eclipse, VS Code, etc.)

## Installation

### Maven Dependency

Add the tinystruct dependency to your project's `pom.xml` file:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.12</version>
    <classifier>jar-with-dependencies</classifier>
</dependency>
```

### Manual Installation

Alternatively, you can download the JAR file directly from the [Maven Repository](https://mvnrepository.com/artifact/org.tinystruct/tinystruct) and add it to your project's classpath.

## Creating Your First Application

### 1. Create a Basic Application Class

Create a new Java class that extends `AbstractApplication`:

```java
package com.example;

import org.tinystruct.AbstractApplication;
import org.tinystruct.system.annotation.Action;

public class HelloWorldApp extends AbstractApplication {

    @Override
    public void init() {
        // Initialization code
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
```

### 3. Running as a CLI Application

You can run your application from the command line using the tinystruct dispatcher:

```bash
# Display version
bin/dispatcher --version

# Run the hello action
bin/dispatcher hello --import com.example.HelloWorldApp

# Run with a parameter
bin/dispatcher hello/John --import com.example.HelloWorldApp
```

### 4. Running as a Web Application

To run your application as a web server:

```bash
# Start the server with Netty
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --import com.example.HelloWorldApp
```

Then access your application at:
- http://localhost:8080/?q=hello
- http://localhost:8080/?q=hello/John

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
│   │   │           └── ...
│   │   └── resources/
│   │       └── config.properties
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── HelloWorldAppTest.java
├── bin/
│   └── dispatcher
└── pom.xml
```

## Next Steps

- Learn about [Core Concepts](core-concepts.md)
- Explore [Web Applications](web-applications.md)
- Check out [CLI Applications](cli-applications.md)
- Understand [Configuration](configuration.md)
- Dive into [Database Integration](database.md)
