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

The `DatabaseOperator` class provides a convenient way to perform database operations without directly managing Repository instances. It handles connection management, statement preparation, and resource cleanup automatically.

### Creating a DatabaseOperator

```java
// Default constructor - gets connection from ConnectionManager
DatabaseOperator operator = new DatabaseOperator();

// With specific database
DatabaseOperator operator = new DatabaseOperator("myDatabase");

// With existing connection
Connection connection = getConnection();
DatabaseOperator operator = new DatabaseOperator(connection);
```

### Executing Queries

```java
// Simple query without parameters
ResultSet results = operator.query("SELECT * FROM users");

// Query with parameters (using prepared statement)
PreparedStatement stmt = operator.preparedStatement("SELECT * FROM users WHERE id = ?", new Object[]{1});
ResultSet results = operator.executeQuery(stmt);

// Process results
while (results.next()) {
    int id = results.getInt("id");
    String name = results.getString("name");
    // Process row data
}
```

### Executing Updates

```java
// Simple update without parameters
int rowsAffected = operator.update("UPDATE users SET status = 'active'");

// Update with parameters
PreparedStatement stmt = operator.preparedStatement(
    "UPDATE users SET name = ? WHERE id = ?",
    new Object[]{"John Doe", 1}
);
int rowsAffected = operator.executeUpdate(stmt);

// Execute statement that might be query or update
boolean isResultSet = operator.execute("CALL some_procedure()");
```

### Resource Management

```java
// Using try-with-resources for automatic cleanup
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM users");
    // Process results
} // Automatically closes ResultSet, PreparedStatement, and returns Connection to pool
```

### SQL Injection Protection

The DatabaseOperator includes built-in SQL injection detection:

```java
// SQL injection is checked by default
DatabaseOperator operator = new DatabaseOperator();

// Disable SQL injection checking (e.g., for CLI tools)
operator.disableSafeCheck();
```

## Repository API

Tinystruct also uses the Repository pattern for direct database operations. The Repository interface provides methods for executing queries and updates.

### Creating a Repository

```java
// Create a MySQL repository
Repository repository = Type.MySQL.createRepository();

// Create an H2 repository
Repository repository = Type.H2.createRepository();

// Create a SQLite repository
Repository repository = Type.SQLite.createRepository();
```

### Executing Queries

```java
@Action("users")
public String getUser(Integer id, Request request, Response response) {
    try {
        // Create a DatabaseOperator instance
        DatabaseOperator operator = new DatabaseOperator();

        // Execute query with parameter
        ResultSet results = operator.query("SELECT id, name, email FROM users WHERE id = " + id);

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        if (!results.next()) {
            // Create error response
            Builder builder = new Builder();
            builder.put("error", "User not found");
            return builder.toString();
        }

        // Create success response
        Builder builder = new Builder();
        builder.put("id", results.getInt("id"));
        builder.put("name", results.getString("name"));
        builder.put("email", results.getString("email"));

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
public String createUser(Request request, Response response) {
    try {
        String name = request.getParameter("name");
        String email = request.getParameter("email");

        if (name == null || email == null) {
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));
            Builder builder = new Builder();
            builder.put("error", "Name and email are required");
            return builder.toString();
        }

        // Create a DatabaseOperator instance
        DatabaseOperator operator = new DatabaseOperator();

        // Execute update with parameters
        PreparedStatement stmt = operator.preparedStatement(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            new Object[]{name, email}
        );
        int result = operator.executeUpdate(stmt);

        // Set content type to JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // Create success response
        Builder builder = new Builder();
        builder.put("success", true);
        builder.put("rowsAffected", result);

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

### Transactions

Tinystruct provides comprehensive transaction support through the `DatabaseOperator` class.

#### Basic Transaction Usage

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

        PreparedStatement stmt2 = operator.preparedStatement(
            "UPDATE settings SET value = ? WHERE name = ?",
            new Object[]{"new_value", "setting_name"}
        );
        operator.executeUpdate(stmt2);

        // Commit transaction if all operations succeed
        operator.commitTransaction();

    } catch (Exception e) {
        // Rollback transaction if any operation fails
        operator.rollbackTransaction();
        throw e;
    }
}
```

#### Example: Fund Transfer with Transactions

```java
@Action("transfer")
public String transferFunds(Request request, Response response) {
    int fromAccount = Integer.parseInt(request.getParameter("from"));
    int toAccount = Integer.parseInt(request.getParameter("to"));
    double amount = Double.parseDouble(request.getParameter("amount"));

    try (DatabaseOperator operator = new DatabaseOperator()) {
        // Begin transaction
        operator.beginTransaction();

        try {
            // Deduct from source account
            PreparedStatement stmt1 = operator.preparedStatement(
                "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?",
                new Object[]{amount, fromAccount, amount}
            );
            int result1 = operator.executeUpdate(stmt1);

            if (result1 == 0) {
                operator.rollbackTransaction();

                response.headers().add(Header.CONTENT_TYPE.set("application/json"));
                Builder builder = new Builder();
                builder.put("error", "Insufficient funds");
                return builder.toString();
            }

            // Add to destination account
            PreparedStatement stmt2 = operator.preparedStatement(
                "UPDATE accounts SET balance = balance + ? WHERE id = ?",
                new Object[]{amount, toAccount}
            );
            int result2 = operator.executeUpdate(stmt2);

            if (result2 == 0) {
                operator.rollbackTransaction();

                response.headers().add(Header.CONTENT_TYPE.set("application/json"));
                Builder builder = new Builder();
                builder.put("error", "Destination account not found");
                return builder.toString();
            }

            // Log the transaction
            PreparedStatement stmt3 = operator.preparedStatement(
                "INSERT INTO transactions (from_account, to_account, amount, date) VALUES (?, ?, ?, NOW())",
                new Object[]{fromAccount, toAccount, amount}
            );
            operator.executeUpdate(stmt3);

            // Commit the transaction
            operator.commitTransaction();

            response.headers().add(Header.CONTENT_TYPE.set("application/json"));
            Builder builder = new Builder();
            builder.put("success", true);
            return builder.toString();
        } catch (Exception e) {
            // Rollback on error
            operator.rollbackTransaction();
            throw e;
        }
    } catch (Exception e) {
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));
        Builder builder = new Builder();
        builder.put("error", e.getMessage());
        return builder.toString();
    }
}
```

#### Using Savepoints

Savepoints allow you to create points within a transaction that you can roll back to without rolling back the entire transaction.

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // Begin transaction
    operator.beginTransaction();

    // Execute first operation
    PreparedStatement stmt1 = operator.preparedStatement(
        "INSERT INTO users (name) VALUES (?)",
        new Object[]{"John"}
    );
    operator.executeUpdate(stmt1);

    // Create savepoint after first operation
    Savepoint savepoint = operator.createSavepoint("AFTER_INSERT");

    try {
        // Execute second operation
        PreparedStatement stmt2 = operator.preparedStatement(
            "UPDATE settings SET value = ? WHERE name = ?",
            new Object[]{"new_value", "setting_name"}
        );
        operator.executeUpdate(stmt2);
    } catch (Exception e) {
        // If second operation fails, roll back to savepoint
        operator.rollbackTransaction(savepoint);

        // Try alternative operation
        PreparedStatement altStmt = operator.preparedStatement(
            "INSERT INTO logs (message) VALUES (?)",
            new Object[]{"Operation failed"}
        );
        operator.executeUpdate(altStmt);
    }

    // Commit transaction
    operator.commitTransaction();
}
```

#### Transaction Methods

The `DatabaseOperator` class provides the following transaction-related methods:

- `beginTransaction()`: Begins a new transaction
- `commitTransaction()`: Commits the current transaction
- `rollbackTransaction()`: Rolls back the entire transaction
- `rollbackTransaction(Savepoint)`: Rolls back to a specific savepoint
- `createSavepoint(String)`: Creates a named savepoint
- `releaseSavepoint(Savepoint)`: Releases a savepoint
- `isInTransaction()`: Checks if a transaction is active

#### Transaction Best Practices

1. Always use try-with-resources to ensure proper closure of the `DatabaseOperator`
2. Wrap transaction operations in a try-catch block
3. Always commit or rollback transactions explicitly
4. Use savepoints for complex operations where partial rollbacks might be needed
5. Keep transactions as short as possible to avoid locking resources for extended periods
6. Handle exceptions appropriately, ensuring transactions are rolled back on errors

Note: If a `DatabaseOperator` with an active transaction is closed without explicitly committing or rolling back the transaction, the transaction will be automatically rolled back to ensure data integrity.

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
newBook.append(); // Insert a new record into database

// Find a book by ID
Book book = new Book();
book.setId(1);
book.findOneById(); // Find by ID

// Update a book
book.setName("Updated Title");
book.update();

// Delete a book
book.delete(); // Delete the record

// Find all books
List<Book> allBooks = book.findAll();

// Find books with conditions
List<Book> books = book.findWhere("author = ?", "F. Scott Fitzgerald");
```

### Important Note on Data Operations

In the tinystruct framework, there are distinct methods for different database operations:

- `append()`: Use this method specifically for inserting new records into the database.
- `update()`: Use this method specifically for updating existing records in the database.
- `save()`: This method determines whether to insert or update based on whether the record exists. It's a convenience method that internally calls either `append()` or `update()` as appropriate.

For clarity and precise control, it's recommended to use `append()` for inserts and `update()` for updates rather than relying on `save()`.

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
