# Database API Reference

## Repository Interface

The `Repository` interface provides methods for executing database operations at a low level.

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

The `DatabaseOperator` class provides a convenient way to perform raw SQL database operations and manage transactions.

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

The `AbstractData` class is the foundation for Object-Relational Mapping (ORM) in Tinystruct.

### Class Definition

```java
public abstract class AbstractData {
    // Field Registration Methods (must be called in setters)
    protected String setFieldAsString(String fieldName, String value);
    protected int setFieldAsInt(String fieldName, int value);
    protected Date setFieldAsDate(String fieldName, Date value);
    protected boolean setFieldAsBoolean(String fieldName, boolean value);
    protected LocalDateTime setFieldAsLocalDateTime(String fieldName, LocalDateTime value);

    // CRUD operations
    public void append() throws ApplicationException;
    public void update() throws ApplicationException;
    public void delete() throws ApplicationException;
    
    // Query operations
    public void findOneById() throws ApplicationException;
    public <T extends AbstractData> Table findAll() throws ApplicationException;
    public <T extends AbstractData> Table findWith(String condition, Object[] parameters) throws ApplicationException;
    
    // Aggregation & Configuration
    public AbstractData setRequestFields(String fields);
    public void setTableName(String tableName);
    
    // Identifier management
    public Object getId();
    public void setId(Object id);
    
    // Data mapping (must be implemented)
    public abstract void setData(Row row);
}
```

## Table and Row Interfaces

Querying with `AbstractData` returns a `Table`, which acts as a list of `Row` objects containing the result data.

### Interface Definitions

```java
public interface Table extends Iterable<Row> {
    int size();
    boolean isEmpty();
    Row get(int index);
    Iterator<Row> iterator();
}

public interface Row extends Iterable<Field> {
    // Get raw field info
    Field getFieldInfo(String columnName);
    
    // Check methods
    boolean hasColumn(String columnName);
    
    // Column information
    Set<String> getColumnNames();
}

public interface Field {
    String name();
    Object value();
    
    // Typed getters
    String stringValue();
    int intValue();
    long longValue();
    double doubleValue();
    boolean booleanValue();
    Date dateValue();
    LocalDateTime localDateTimeValue();
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

### Basic Query (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM User LIMIT 1");
    
    if (results.next()) {
        String username = results.getString("username");
        String email = results.getString("email");
        System.out.println("User: " + username + " (" + email + ")");
    }
}
```

### Parameterized Query (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    PreparedStatement stmt = operator.preparedStatement(
        "SELECT id, username, email FROM User WHERE email = ?", 
        new Object[]{"james@example.com"}
    );
    
    ResultSet results = operator.executeQuery(stmt);
    
    while (results.next()) {
        String id = results.getString("id");
        String name = results.getString("username");
        System.out.println("User ID: " + id + ", Username: " + name);
    }
}
```

### Transaction (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    
    try {
        PreparedStatement s1 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?",
            new Object[]{100.0, "source-uuid"}
        );
        operator.executeUpdate(s1);
        
        PreparedStatement s2 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            new Object[]{100.0, "target-uuid"}
        );
        operator.executeUpdate(s2);
        
        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

### Object-Relational Mapping (`AbstractData`)

```java
// 1. Define a model class
public class User extends AbstractData {
    private String username;
    private String email;
    
    public String getId() {
        return String.valueOf(this.Id);
    }
    
    // Setters must register the field
    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    
    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
    }
}

// 2. Create a new user (UUID generated automatically via mapping)
User user = new User();
user.setUsername("james");
user.setEmail("james@example.com");
user.append();
System.out.println("New ID: " + user.getId());

// 3. Find a user by ID
User foundUser = new User();
foundUser.setId(user.getId());
foundUser.findOneById();

// 4. Update a user
foundUser.setUsername("james_updated");
foundUser.update();

// 5. Delete a user
foundUser.delete();

// 6. Find all users
Table allUsersTable = new User().findAll();

// 7. Find users with a condition
Table filteredTable = new User().findWith("WHERE username LIKE ?", new Object[]{"%james%"});
if (!filteredTable.isEmpty()) {
    User firstMatch = new User();
    firstMatch.setData(filteredTable.get(0));
}
```

## Best Practices

1. **Resource Management**: Always use `try-with-resources` when using `DatabaseOperator` to ensure proper closure of database resources and connection pooling.
2. **Field Registration**: When extending `AbstractData`, always call the appropriate `setFieldAs*` method in your setters.
3. **Parameterized Queries**: Pass values through the `Object[]` parameter in `findWith()` or `preparedStatement()` to prevent SQL injection.
4. **Aggregate Queries**: Use `setRequestFields()` to modify the SELECT projection before calling `findWith()`.
5. **Transactions**: Use transactions for operations that span multiple tables or require atomicity.

## Related APIs

- [Configuration API](configuration.md)
- [Application API](application.md)
