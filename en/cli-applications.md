# CLI Applications with tinystruct

This guide explains how to build command-line interface (CLI) applications using the tinystruct framework.

## CLI Basics

tinystruct's CLI capabilities are powered by the same action mechanism used for web applications, making it easy to create both CLI tools and web interfaces with shared code.

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

### POJO Generator Example

```java
@Action(
    value = "generate-pojo",
    description = "Generate POJO class from database table",
    options = {
        @Argument(name = "table", description = "Database table name"),
        @Argument(name = "package", description = "Java package name"),
        @Argument(name = "output", description = "Output directory")
    },
    mode = Action.Mode.CLI
)
public String generatePojo() {
    String table = getContext().getAttribute("--table");
    String packageName = getContext().getAttribute("--package", "com.example.model");
    String output = getContext().getAttribute("--output", "./src/main/java");
    
    if (table == null) {
        return "Please provide a table name with --table";
    }
    
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        // Get table metadata
        List<Row> columns = repository.query(
            "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE " +
            "FROM INFORMATION_SCHEMA.COLUMNS " +
            "WHERE TABLE_NAME = ?", table);
        
        if (columns.isEmpty()) {
            return "Table not found or has no columns: " + table;
        }
        
        // Generate class name (convert snake_case to CamelCase)
        String className = Arrays.stream(table.split("_"))
            .map(word -> word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase())
            .collect(Collectors.joining());
        
        // Generate Java code
        StringBuilder code = new StringBuilder();
        code.append("package ").append(packageName).append(";\n\n");
        code.append("public class ").append(className).append(" {\n\n");
        
        // Generate fields
        for (Row column : columns) {
            String columnName = column.getString("COLUMN_NAME");
            String dataType = column.getString("DATA_TYPE");
            String javaType = mapSqlTypeToJava(dataType);
            String fieldName = toCamelCase(columnName);
            
            code.append("    private ").append(javaType).append(" ").append(fieldName).append(";\n");
        }
        
        code.append("\n");
        
        // Generate getters and setters
        for (Row column : columns) {
            String columnName = column.getString("COLUMN_NAME");
            String dataType = column.getString("DATA_TYPE");
            String javaType = mapSqlTypeToJava(dataType);
            String fieldName = toCamelCase(columnName);
            String capitalizedFieldName = fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
            
            // Getter
            code.append("    public ").append(javaType).append(" get").append(capitalizedFieldName).append("() {\n");
            code.append("        return ").append(fieldName).append(";\n");
            code.append("    }\n\n");
            
            // Setter
            code.append("    public void set").append(capitalizedFieldName).append("(").append(javaType).append(" ").append(fieldName).append(") {\n");
            code.append("        this.").append(fieldName).append(" = ").append(fieldName).append(";\n");
            code.append("    }\n\n");
        }
        
        code.append("}");
        
        // Write to file
        String packagePath = packageName.replace('.', '/');
        Path outputPath = Paths.get(output, packagePath, className + ".java");
        Files.createDirectories(outputPath.getParent());
        Files.write(outputPath, code.toString().getBytes());
        
        return "Generated " + className + ".java in " + outputPath;
    } catch (Exception e) {
        return "Error generating POJO: " + e.getMessage();
    }
}

private String toCamelCase(String snakeCase) {
    StringBuilder result = new StringBuilder();
    boolean nextUpper = false;
    
    for (char c : snakeCase.toCharArray()) {
        if (c == '_') {
            nextUpper = true;
        } else {
            if (nextUpper) {
                result.append(Character.toUpperCase(c));
                nextUpper = false;
            } else {
                result.append(Character.toLowerCase(c));
            }
        }
    }
    
    return result.toString();
}

private String mapSqlTypeToJava(String sqlType) {
    switch (sqlType.toUpperCase()) {
        case "VARCHAR":
        case "CHAR":
        case "TEXT":
            return "String";
        case "INT":
        case "SMALLINT":
        case "TINYINT":
            return "Integer";
        case "BIGINT":
            return "Long";
        case "DECIMAL":
        case "NUMERIC":
            return "BigDecimal";
        case "FLOAT":
            return "Float";
        case "DOUBLE":
            return "Double";
        case "BOOLEAN":
        case "BIT":
            return "Boolean";
        case "DATE":
            return "LocalDate";
        case "TIME":
            return "LocalTime";
        case "DATETIME":
        case "TIMESTAMP":
            return "LocalDateTime";
        default:
            return "Object";
    }
}
```

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
