# Database Integration in tinystruct

This guide explains how to integrate and work with databases in tinystruct applications.

## Supported Databases

tinystruct provides built-in support for multiple database systems:

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

## Repository API

tinystruct uses the Repository pattern for database operations. The Repository interface provides methods for executing queries and updates.

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
public JsonResponse getUsers() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> users = repository.query("SELECT id, name, email FROM users");
        
        return new JsonResponse(users);
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### Parameterized Queries

```java
@Action("users/{id}")
public JsonResponse getUser(Integer id) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> results = repository.query("SELECT id, name, email FROM users WHERE id = ?", id);
        
        if (results.isEmpty()) {
            return new JsonResponse(Map.of("error", "User not found"));
        }
        
        return new JsonResponse(results.get(0));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
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

## Best Practices

1. **Connection Management**: Always close your database connections when done.

2. **Parameterized Queries**: Use parameterized queries to prevent SQL injection.

3. **Transactions**: Use transactions for operations that require atomicity.

4. **Error Handling**: Implement proper error handling for database operations.

5. **Connection Pooling**: Configure appropriate connection pool settings for your application's needs.

## Next Steps

- Learn about [Advanced Features](advanced-features.md)
- Explore [Best Practices](best-practices.md)
- Check out the [Database API Reference](api/database.md)
