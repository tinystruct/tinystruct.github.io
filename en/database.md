# Database Integration in Tinystruct

This guide explains how to integrate and work with databases in Tinystruct applications.

## Supported Databases

Tinystruct provides built-in support for multiple database systems:

- MySQL
- SQLite
- H2
- Redis
- Microsoft SQL Server

## Configuration

### Database Properties

Configure your database connection in your properties file:

```properties
# MySQL Configuration
driver=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
database.user=root
database.password=password
database.connections.max=10

# H2 Configuration
# driver=org.h2.Driver
# database.url=jdbc:h2:~/test
# database.user=sa
# database.password=
# database.connections.max=10

# SQLite Configuration
# driver=org.sqlite.JDBC
# database.url=jdbc:sqlite:mydb.sqlite
# database.user=
# database.password=
# database.connections.max=10
```

## Database Access Approaches

Tinystruct offers several approaches for database access:

1. **DatabaseOperator**: A convenient utility class for database operations
2. **Direct Repository API**: Using the Repository interface for raw SQL queries and updates
3. **Object Mapping**: Using mapped Java objects with XML configuration for a more object-oriented approach

## DatabaseOperator

The `DatabaseOperator` class provides a convenient way to perform database operations without directly managing Repository instances.

### Basic Usage

```java
// Create a DatabaseOperator instance
DatabaseOperator operator = new DatabaseOperator();

// Execute a query
List<Map<String, Object>> results = operator.query("SELECT * FROM users WHERE id = ?", 1);

// Execute an update
int rowsAffected = operator.update("UPDATE users SET name = ? WHERE id = ?", "John Doe", 1);

// Execute an insert
int newId = operator.insert("INSERT INTO users (name, email) VALUES (?, ?)", "Jane Smith", "jane@example.com");

// Execute a delete
operator.update("DELETE FROM users WHERE id = ?", 1);
```

### Transaction Support

```java
// Start a transaction
operator.begin();

try {
    // Perform multiple operations
    operator.update("UPDATE accounts SET balance = balance - ? WHERE id = ?", 100.0, 1);
    operator.update("UPDATE accounts SET balance = balance + ? WHERE id = ?", 100.0, 2);

    // Commit the transaction
    operator.commit();
} catch (Exception e) {
    // Rollback on error
    operator.rollback();
    throw e;
}
```

## Repository API

Tinystruct also uses the Repository pattern for direct database operations. The Repository interface provides methods for executing queries and updates.

### Creating a Repository

```java
// Create a MySQL repository
Repository repository = Type.MySQL.createRepository();
repository.connect(getConfiguration());

// Create an H2 repository
Repository repository = Type.H2.createRepository();
repository.connect(getConfiguration());

// Create a SQLite repository
Repository repository = Type.SQLite.createRepository();
repository.connect(getConfiguration());
```

### Executing Queries

```java
@Action("users")
public String getUsers(Request request, Response response) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        List<Row> users = repository.query("SELECT id, name, email FROM users");

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create JSON response
        Builder builder = new Builder();
        builder.put("users", users);

        return builder.toString();
    } catch (Exception e) {
        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create error response
        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    }
}
```

### Parameterized Queries

```java
@Action("users")
public String getUser(Integer id, Request request, Response response) {
    try {
        // Create a DatabaseOperator instance
        DatabaseOperator operator = new DatabaseOperator();

        // Execute query with parameter
        List<Map<String, Object>> results = operator.query("SELECT id, name, email FROM users WHERE id = ?", id);

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        if (results.isEmpty()) {
            // Create error response
            Builder builder = new Builder();
            builder.put("error", "User not found");
            return builder.toString();
        }

        // Create success response
        Builder builder = new Builder();
        builder.put("user", results.get(0));
        return builder.toString();
    } catch (Exception e) {
        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create error response
        Builder builder = new Builder();
        builder.put("error", e.getMessage());
        return builder.toString();
    }
}
```

### Executing Updates

```java
@Action("users/create")
public JsonResponse createUser(Request request) {
    try {
        String name = request.getParameter("name");
        String email = request.getParameter("email");

        if (name == null || email == null) {
            return new JsonResponse(Map.of("error", "Name and email are required"));
        }

        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        int result = repository.execute(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            name, email
        );

        return new JsonResponse(Map.of("success", true, "rowsAffected", result));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### Transactions

```java
@Action("transfer")
public JsonResponse transferFunds(Request request) {
    int fromAccount = Integer.parseInt(request.getParameter("from"));
    int toAccount = Integer.parseInt(request.getParameter("to"));
    double amount = Double.parseDouble(request.getParameter("amount"));

    Repository repository = Type.MySQL.createRepository();
    repository.connect(getConfiguration());

    try {
        repository.setAutoCommit(false);

        // Deduct from source account
        int result1 = repository.execute(
            "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?",
            amount, fromAccount, amount
        );

        if (result1 == 0) {
            repository.rollback();
            return new JsonResponse(Map.of("error", "Insufficient funds"));
        }

        // Add to destination account
        int result2 = repository.execute(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            amount, toAccount
        );

        if (result2 == 0) {
            repository.rollback();
            return new JsonResponse(Map.of("error", "Destination account not found"));
        }

        // Log the transaction
        repository.execute(
            "INSERT INTO transactions (from_account, to_account, amount, date) VALUES (?, ?, ?, NOW())",
            fromAccount, toAccount, amount
        );

        repository.commit();

        return new JsonResponse(Map.of("success", true));
    } catch (Exception e) {
        repository.rollback();
        return new JsonResponse(Map.of("error", e.getMessage()));
    } finally {
        repository.setAutoCommit(true);
    }
}
```

## Working with Results

### Row Interface

The `Row` interface provides methods for accessing column values:

```java
List<Row> results = repository.query("SELECT id, name, email FROM users");

for (Row row : results) {
    int id = row.getInt("id");
    String name = row.getString("name");
    String email = row.getString("email");

    System.out.println("User: " + id + ", " + name + ", " + email);
}
```

### Converting Results to Objects

```java
List<User> users = new ArrayList<>();
List<Row> results = repository.query("SELECT id, name, email FROM users");

for (Row row : results) {
    User user = new User();
    user.setId(row.getInt("id"));
    user.setName(row.getString("name"));
    user.setEmail(row.getString("email"));

    users.add(user);
}
```

## Database Utilities

### Schema Creation

```java
@Action(value = "init-db",
        description = "Initialize database schema",
        mode = Action.Mode.CLI)
public String initDatabase() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        // Create users table
        repository.execute(
            "CREATE TABLE IF NOT EXISTS users (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "name VARCHAR(100) NOT NULL, " +
            "email VARCHAR(100) NOT NULL UNIQUE, " +
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ")"
        );

        // Create posts table
        repository.execute(
            "CREATE TABLE IF NOT EXISTS posts (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "user_id INT NOT NULL, " +
            "title VARCHAR(200) NOT NULL, " +
            "content TEXT, " +
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
            "FOREIGN KEY (user_id) REFERENCES users(id)" +
            ")"
        );

        return "Database schema initialized successfully";
    } catch (Exception e) {
        return "Error initializing database: " + e.getMessage();
    }
}
```

### Data Import/Export

```java
@Action(value = "export-data",
        description = "Export data to CSV",
        mode = Action.Mode.CLI)
public String exportData() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        List<Row> users = repository.query("SELECT id, name, email FROM users");

        try (FileWriter writer = new FileWriter("users.csv");
             CSVWriter csvWriter = new CSVWriter(writer)) {

            // Write header
            csvWriter.writeNext(new String[]{"ID", "Name", "Email"});

            // Write data
            for (Row user : users) {
                csvWriter.writeNext(new String[]{
                    String.valueOf(user.getInt("id")),
                    user.getString("name"),
                    user.getString("email")
                });
            }
        }

        return "Exported " + users.size() + " users to users.csv";
    } catch (Exception e) {
        return "Error exporting data: " + e.getMessage();
    }
}
```

## Advanced Database Operations

### Batch Operations

```java
@Action("batch-insert")
public JsonResponse batchInsert(Request request) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        // Prepare batch data
        List<Object[]> batchData = new ArrayList<>();
        batchData.add(new Object[]{"John Doe", "john@example.com"});
        batchData.add(new Object[]{"Jane Smith", "jane@example.com"});
        batchData.add(new Object[]{"Bob Johnson", "bob@example.com"});

        // Execute batch insert
        int[] results = repository.executeBatch(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            batchData
        );

        return new JsonResponse(Map.of("success", true, "rowsAffected", Arrays.stream(results).sum()));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### Stored Procedures

```java
@Action("call-procedure")
public JsonResponse callProcedure(Request request) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());

        List<Row> results = repository.query(
            "CALL get_user_posts(?)",
            Integer.parseInt(request.getParameter("userId"))
        );

        return new JsonResponse(results);
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

## Object Mapping Approach

Tinystruct also supports an object-oriented approach to database access using Java objects mapped to database tables via XML configuration files.

### 1. Define a Model Class

Create a Java class that represents your database entity:

```java
package custom.objects;

import org.tinystruct.data.component.AbstractData;

public class Book extends AbstractData {
    private int id;
    private String name;
    private String author;
    private String content;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
```

### 2. Create an XML Mapping File

Create an XML file that maps the Java class to a database table. Place this file in the resources directory with a path that matches the package structure of your model class:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mapping>
    <class name="custom.objects.Book" table="books">
        <property name="id" column="id" type="int" identifier="true"/>
        <property name="name" column="name" type="string"/>
        <property name="author" column="author" type="string"/>
        <property name="content" column="content" type="string"/>
    </class>
</mapping>
```

### 3. Using the Mapped Object

```java
@Action("books")
public String getBooks(Request request, Response response) {
    try {
        // Create a new Book instance
        Book book = new Book();

        // Find all books
        List<Book> books = book.findAll();

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create JSON response
        Builder builder = new Builder();
        builder.put("books", books);

        return builder.toString();
    } catch (Exception e) {
        // Handle error
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);

        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    }
}

@Action("books")
public String getBook(Integer id, Request request, Response response) {
    try {
        // Create a new Book instance
        Book book = new Book();

        // Set the ID to search for
        book.setId(id);

        // Find the book by ID
        book.find();

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create JSON response
        Builder builder = new Builder();
        builder.put("book", book);

        return builder.toString();
    } catch (Exception e) {
        // Handle error
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);

        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    }
}
```

### 4. CRUD Operations

```java
// Create a new book
Book newBook = new Book();
newBook.setName("The Great Gatsby");
newBook.setAuthor("F. Scott Fitzgerald");
newBook.setContent("In my younger and more vulnerable years...");
newBook.save(); // Insert into database

// Find a book by ID
Book book = new Book();
book.setId(1);
book.find();

// Update a book
book.setName("Updated Title");
book.update();

// Delete a book
book.remove();

// Find all books
List<Book> allBooks = book.findAll();

// Find books with conditions
List<Book> books = book.findWhere("author = ?", "F. Scott Fitzgerald");
```

## Best Practices

1. **Connection Management**: Always close your database connections when done.

2. **Parameterized Queries**: Use parameterized queries to prevent SQL injection.

3. **Transactions**: Use transactions for operations that require atomicity.

4. **Error Handling**: Implement proper error handling for database operations.

5. **Connection Pooling**: Configure appropriate connection pool settings for your application's needs.

6. **Object Mapping**: Use the object mapping approach for cleaner, more maintainable code when working with database entities.

7. **XML Mapping Files**: Keep your XML mapping files organized in a directory structure that matches your Java package structure.

## Next Steps

- Learn about [Advanced Features](advanced-features.md)
- Explore [Best Practices](best-practices.md)
- Check out the [Database API Reference](api/database.md)
