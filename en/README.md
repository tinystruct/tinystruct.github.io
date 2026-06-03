# tinystruct framework

`"How many are your works, O LORD! In wisdom you made them all; the earth is full of your creatures."`
***Psalms 104:24***

## Overview

tinystruct is a simple yet powerful framework for Java development. It embraces simple thinking and better design principles, making it easy to use while delivering excellent performance.

## Key Features

- **Modern Architecture**: No `main()` method required, applications start directly via CLI
- **Dual-Mode Support**: CLI and Web are treated as equal citizens
- **Built-in Servers**: Native support for Netty, Tomcat, and Undertow
- **AI-Ready**: Designed for AI integration and Model Context Protocol (MCP)
- **SSE Support**: Native Server-Sent Events for real-time applications
- **High Performance**: Optimized to handle 86,000+ requests per second
- **Minimal Configuration**: Zero-boilerplate philosophy
- **Annotation-Based Routing**: Clean and intuitive routing with `@Action`

## Quick Start

### Maven Integration

Add the dependency to your pom.xml:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.25</version>
    <classifier>jar-with-dependencies</classifier>
</dependency>
```

### Basic Application Example

```java
package tinystruct.examples;

import org.tinystruct.AbstractApplication;
import org.tinystruct.ApplicationException;
import org.tinystruct.system.annotation.Action;

public class Example extends AbstractApplication {

    @Override
    public void init() {
        // Initialization code
    }

    @Action("praise")
    public String praise() {
        return "Praise the Lord!";
    }

    @Action("say")
    public String say(String words) {
        return words;
    }

    @Action(value = "hello", mode = Mode.HTTP_GET)
    public String helloGet() {
        return "GET";
    }
}
```

## What makes tinystruct modern?

1. **No `main()` method required**: Applications can be started directly using CLI commands like `bin/dispatcher`, with no boilerplate code needed.
2. **Unified design for CLI and Web**: Unlike many frameworks, tinystruct treats CLI and Web as equal citizens. This makes it perfect for AI tasks, script automation, and hybrid applications.
3. **Built-in lightweight HTTP server**: Whether it’s Netty or Tomcat, tinystruct integrates the server lifecycle inside the framework.
4. **Minimal configuration philosophy**: Configuration is minimized to the essentials. No need to wire up hundreds of beans or complex XML/YAML files.
5. **Annotation-based routing**: Clean and intuitive routing using `@Action`, eliminating complex controller hierarchies.
6. **Performance-first architecture**: Almost zero overhead. No reflection-based bean scanning or unnecessary interceptors.
7. **AI & MCP Integration**: Built-in support for Model Context Protocol (MCP) and AI-driven workflows.

## Documentation Contents

- [Getting Started](getting-started.md)
- [Core Concepts](core-concepts.md)
- [Web Applications](web-applications.md)
- [CLI Applications](cli-applications.md)
- [Configuration](configuration.md)
- [Database Integration](database.md)
- [Advanced Features](advanced-features.md)
- [Best Practices](best-practices.md)
- [AI & MCP Integration](mcp-integration.md)
- [API Reference](api/README.md)

## Community and Support

- GitHub Repository: [https://github.com/tinystruct/tinystruct](https://github.com/tinystruct/tinystruct)
- Issue Tracker: [https://github.com/tinystruct/tinystruct/issues](https://github.com/tinystruct/tinystruct/issues)
- Discussion Forum: [https://github.com/tinystruct/tinystruct/discussions](https://github.com/tinystruct/tinystruct/discussions)

## License

Licensed under the Apache License, Version 2.0