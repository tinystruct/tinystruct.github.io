# CLI Applications with tinystruct

This guide explains how to build command-line interface (CLI) applications using the tinystruct framework.

## CLI Basics

tinystruct's CLI capabilities are powered by the same action mechanism used for web applications, making it easy to create both CLI tools and web interfaces with shared code.

## Unified Design for CLI and Web

Unlike many other frameworks that treat CLI as an afterthought, tinystruct treats CLI and Web as equal citizens. This means:
- You can use the same `@Action` annotations for both modes.
- Business logic is naturally shared without extra layers.
- You can test your web actions via CLI easily.
- It's perfect for AI-driven tasks and automation.

## No main() Method Required

One of the modern features of tinystruct is that it doesn't require a `main()` method in your application classes. Applications are started directly using the `bin/dispatcher` tool. This reduces boilerplate and focuses your code on the logic itself.

## Creating CLI Commands

### Basic Command

```java
@Action(value = "hello", 
        description = "Display a greeting",
        mode = Action.Mode.CLI)
public String hello() {
    return "Hello, World!";
}
```

### Command with Parameters

```java
@Action(value = "hello", 
        description = "Display a greeting to the specified name",
        mode = Action.Mode.CLI)
public String hello(String name) {
    return "Hello, " + name + "!";
}
```

### Accessing Command Line Arguments

```java
@Action(value = "greet", 
        description = "Greet someone",
        mode = Action.Mode.CLI)
public String greet() {
    String name = getContext().getAttribute("--name");
    String greeting = getContext().getAttribute("--greeting", "Hello");
    
    if (name == null) {
        return "Please provide a name with --name";
    }
    
    return greeting + ", " + name + "!";
}
```

## Command Options

You can define command options using the `options` parameter in the `@Action` annotation:

```java
@Action(
    value = "generate",
    description = "Generate code from a template",
    options = {
        @Argument(name = "template", alias = "t", description = "Template name"),
        @Argument(name = "output", alias = "o", description = "Output directory")
    },
    mode = Action.Mode.CLI
)
public String generate() {
    String template = getContext().getAttribute("--template");
    String output = getContext().getAttribute("--output", "./output");
    
    // Generate code using the template
    return "Generated code using " + template + " template in " + output;
}
```

## Running CLI Applications

### Using the Dispatcher

```bash
# Basic command
bin/dispatcher hello --import com.example.MyApp

# Command with parameter
bin/dispatcher hello/John --import com.example.MyApp

# Command with named arguments
bin/dispatcher greet --name John --greeting Hi --import com.example.MyApp

# Command with options
bin/dispatcher generate --template entity --output ./src/main/java --import com.example.MyApp
```

## Interactive CLI Applications

### Reading User Input

```java
@Action(value = "interactive", 
        description = "Interactive command example",
        mode = Action.Mode.CLI)
public void interactive() {
    System.out.print("Enter your name: ");
    Scanner scanner = new Scanner(System.in);
    String name = scanner.nextLine();
    
    System.out.print("Enter your age: ");
    int age = scanner.nextInt();
    
    System.out.println("Hello, " + name + "! You are " + age + " years old.");
}
```

### Progress Indicators

```java
@Action(value = "process", 
        description = "Process with progress indicator",
        mode = Action.Mode.CLI)
public void process() {
    int total = 100;
    
    for (int i = 0; i <= total; i++) {
        System.out.print("\rProcessing: " + i + "% [");
        int progress = i / 2;
        for (int j = 0; j < 50; j++) {
            if (j < progress) {
                System.out.print("=");
            } else if (j == progress) {
                System.out.print(">");
            } else {
                System.out.print(" ");
            }
        }
        System.out.print("] " + i + "%");
        
        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    System.out.println("\nProcessing complete!");
}
```

## File System Operations

```java
@Action(value = "copy", 
        description = "Copy a file",
        mode = Action.Mode.CLI)
public String copy() {
    String source = getContext().getAttribute("--source");
    String destination = getContext().getAttribute("--destination");
    
    if (source == null || destination == null) {
        return "Please provide --source and --destination parameters";
    }
    
    try {
        Path sourcePath = Paths.get(source);
        Path destinationPath = Paths.get(destination);
        
        Files.copy(sourcePath, destinationPath, StandardCopyOption.REPLACE_EXISTING);
        return "File copied successfully from " + source + " to " + destination;
    } catch (IOException e) {
        return "Error copying file: " + e.getMessage();
    }
}
```

## Database Operations

```java
@Action(value = "export-users", 
        description = "Export users to CSV",
        mode = Action.Mode.CLI)
public String exportUsers() {
    String outputFile = getContext().getAttribute("--output", "users.csv");
    
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> users = repository.query("SELECT id, name, email FROM users");
        
        try (FileWriter writer = new FileWriter(outputFile);
             CSVWriter csvWriter = new CSVWriter(writer)) {
            
            // Write header
            csvWriter.writeNext(new String[]{"ID", "Name", "Email"});
            
            // Write data
            for (Row user : users) {
                csvWriter.writeNext(new String[]{
                    user.getString("id"),
                    user.getString("name"),
                    user.getString("email")
                });
            }
        }
        
        return "Exported " + users.size() + " users to " + outputFile;
    } catch (Exception e) {
        return "Error exporting users: " + e.getMessage();
    }
}
```

## Creating Custom Commands

### Built-in POJO Generator

Tinystruct includes a built-in `generate` command that creates POJO classes and XML mapping files directly from your database schema. It automatically detects Java types from column definitions and adds the required import statements — no manual import specification is needed.

```bash
# Interactive mode — prompts for table names and output path
bin/dispatcher generate

# Non-interactive — specify tables directly
bin/dispatcher generate --tables users

# Multiple tables (semicolon-delimited)
bin/dispatcher generate --tables "users;orders;products"
```

The generator:
- Supports **MySQL**, **MSSQL**, **SQLite**, and **H2** databases
- **Automatically imports** `java.time.LocalDateTime`, `java.util.Date`, `java.sql.Timestamp`, and `java.sql.Time` based on column types
- Generates both the **Java POJO** and the **XML mapping file**
- Auto-detects the project's base package from your source tree
- Singularizes table names for class names (e.g. `users` → `User`)

For full details and generated code examples, see the [Database Integration — Built-in POJO Generator](database.md#built-in-pojo-generator) section.


## Best Practices

1. **Provide Clear Help**: Always include descriptive help text for your commands.

2. **Validate Input**: Check command arguments and provide helpful error messages.

3. **Progress Feedback**: For long-running operations, provide progress indicators.

4. **Exit Codes**: Return appropriate exit codes to indicate success or failure.

5. **Logging**: Implement proper logging for debugging and auditing.

## Next Steps

- Learn about [Configuration](configuration.md)
- Explore [Database Integration](database.md)
- Check out [Advanced Features](advanced-features.md)
