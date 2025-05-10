# tinystruct Framework

`"How many are your works, O LORD! In wisdom you made them all; the earth is full of your creatures."`
***Psalms 104:24***

## Overview

tinystruct is a simple yet powerful framework for Java development. It embraces simple thinking and better design principles, making it easy to use while delivering excellent performance.

## Key Features

- **Lightweight Architecture**: Minimal overhead with maximum flexibility
- **Dual-Mode Support**: Build both web applications and CLI tools
- **Simple Configuration**: Easy to set up and customize
- **High Performance**: Optimized for efficient execution
- **Database Integration**: Built-in support for multiple databases
- **RESTful Support**: Easy API development
- **Command Line Tools**: Powerful CLI capabilities

## Quick Start

### Maven Integration

Add the dependency to your pom.xml:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.6.7</version>
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
}
```

## Documentation Contents

- [Getting Started](getting-started.md)
- [Core Concepts](core-concepts.md)
- [Web Applications](web-applications.md)
- [CLI Applications](cli-applications.md)
- [Configuration](configuration.md)
- [Database Integration](database.md)
- [Advanced Features](advanced-features.md)
- [Best Practices](best-practices.md)
- [API Reference](api/README.md)

## Community and Support

- GitHub Repository: [https://github.com/tinystruct/tinystruct](https://github.com/tinystruct/tinystruct)
- Issue Tracker: [https://github.com/tinystruct/tinystruct/issues](https://github.com/tinystruct/tinystruct/issues)
- Discussion Forum: [https://github.com/tinystruct/tinystruct/discussions](https://github.com/tinystruct/tinystruct/discussions)

## License

Licensed under the Apache License, Version 2.0