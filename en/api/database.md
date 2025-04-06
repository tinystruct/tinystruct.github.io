# Database API Reference

## Repository Interface

The `Repository` interface provides methods for executing database operations.

### Interface Definition

```java
public interface Repository {
    // Query methods
    List<Row> query(String sql, Object... parameters) throws SQLException;
    Row queryOne(String sql, Object... parameters) throws SQLException;
    
    // Update methods
    int update(String sql, Object... parameters) throws SQLException;
    int[] batchUpdate(String sql, List<Object[]> parametersList) throws SQLException;
    
    // Execute methods
    boolean execute(String sql, Object... parameters) throws SQLException;
    
    // Transaction methods
    void begin() throws SQLException;
    void commit() throws SQLException;
    void rollback() throws SQLException;
    
    // Connection management
    Connection getConnection() throws SQLException;
    void close() throws SQLException;
}
```

## DatabaseOperator

The `DatabaseOperator` class provides a convenient way to perform database operations.

### Class Definition

```java
public class DatabaseOperator implements AutoCloseable {
    // Constructors
    public DatabaseOperator();
    public DatabaseOperator(String database);
    public DatabaseOperator(Connection connection);
    
    // Query methods
    public ResultSet query(String sql) throws SQLException;
    public ResultSet executeQuery(PreparedStatement statement) throws SQLException;
    
    // Update methods
    public int update(String sql) throws SQLException;
    public int executeUpdate(PreparedStatement statement) throws SQLException;
    
    // Execute methods
    public boolean execute(String sql) throws SQLException;
    public boolean execute(PreparedStatement statement) throws SQLException;
    
    // Prepared statement
    public PreparedStatement preparedStatement(String sql, Object[] parameters) throws SQLException;
    
    // Transaction methods
    public Savepoint beginTransaction() throws SQLException;
    public void commitTransaction() throws SQLException;
    public void rollbackTransaction() throws SQLException;
    public void rollbackTransaction(Savepoint savepoint) throws SQLException;
    public Savepoint createSavepoint(String name) throws SQLException;
    public void releaseSavepoint(Savepoint savepoint) throws SQLException;
    public boolean isInTransaction() throws SQLException;
    
    // SQL injection protection
    public void enableSafeCheck();
    public void disableSafeCheck();
    
    // Resource management
    public void close() throws SQLException;
}
```

## AbstractData

The `AbstractData` class provides a base class for object-relational mapping.

### Class Definition

```java
public abstract class AbstractData {
    // CRUD operations
    public void append() throws ApplicationException;
    public void update() throws ApplicationException;
    public void delete() throws ApplicationException;
    public void save() throws ApplicationException;
    
    // Query operations
    public void findOneById() throws ApplicationException;
    public <T extends AbstractData> List<T> findAll() throws ApplicationException;
    public <T extends AbstractData> List<T> findWhere(String condition, Object... parameters) throws ApplicationException;
    public <T extends AbstractData> T findOne(String condition, Object... parameters) throws ApplicationException;
    
    // Count operations
    public long count() throws ApplicationException;
    public long countWhere(String condition, Object... parameters) throws ApplicationException;
    
    // Utility methods
    public String getTableName();
    public String getIdentifierName();
    public Object getIdentifierValue();
    public void setIdentifierValue(Object value);
}
```

## Row Interface

The `Row` interface provides methods for accessing data from query results.

### Interface Definition

```java
public interface Row {
    // Get methods
    String getString(String columnName);
    int getInt(String columnName);
    long getLong(String columnName);
    double getDouble(String columnName);
    boolean getBoolean(String columnName);
    Date getDate(String columnName);
    Time getTime(String columnName);
    Timestamp getTimestamp(String columnName);
    Object getObject(String columnName);
    
    // Check methods
    boolean isNull(String columnName);
    boolean hasColumn(String columnName);
    
    // Column information
    Set<String> getColumnNames();
}
```

## Type Enum

The `Type` enum provides factory methods for creating repositories for different database types.

### Enum Definition

```java
public enum Type {
    MySQL,
    SQLite,
    H2,
    MSSQL,
    PostgreSQL,
    Oracle;
    
    public Repository createRepository();
}
```

## Example Usage

### Basic Query

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM users WHERE id = 1");
    
    if (results.next()) {
        String name = results.getString("name");
        String email = results.getString("email");
        System.out.println("User: " + name + " (" + email + ")");
    }
}
```

### Parameterized Query

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    PreparedStatement stmt = operator.preparedStatement(
        "SELECT * FROM users WHERE email = ?", 
        new Object[]{"john@example.com"}
    );
    
    ResultSet results = operator.executeQuery(stmt);
    
    while (results.next()) {
        int id = results.getInt("id");
        String name = results.getString("name");
        System.out.println("User ID: " + id + ", Name: " + name);
    }
}
```

### Transaction

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    
    try {
        operator.update("UPDATE accounts SET balance = balance - 100 WHERE id = 1");
        operator.update("UPDATE accounts SET balance = balance + 100 WHERE id = 2");
        
        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

### Object-Relational Mapping

```java
// Define a model class
public class User extends AbstractData {
    private int id;
    private String name;
    private String email;
    
    // Getters and setters
    // ...
}

// Create a new user
User user = new User();
user.setName("John Doe");
user.setEmail("john@example.com");
user.append();

// Find a user by ID
User foundUser = new User();
foundUser.setId(1);
foundUser.findOneById();

// Update a user
foundUser.setName("Jane Doe");
foundUser.update();

// Delete a user
foundUser.delete();

// Find all users
List<User> allUsers = new User().findAll();

// Find users with a condition
List<User> filteredUsers = new User().findWhere("name LIKE ?", "%Doe%");
```

## Best Practices

1. **Resource Management**: Always use try-with-resources to ensure proper closure of database resources.

2. **Parameterized Queries**: Use parameterized queries to prevent SQL injection.

3. **Transactions**: Use transactions for operations that require atomicity.

4. **Error Handling**: Implement proper error handling for database operations.

5. **Connection Pooling**: Configure appropriate connection pool settings for your application's needs.

## Related APIs

- [Configuration API](configuration.md)
- [Application API](application.md)
