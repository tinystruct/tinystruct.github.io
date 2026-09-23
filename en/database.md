# Database Integration in Tinystruct

This guide explains how to integrate and work with databases in Tinystruct applications,
using the [bible-online](https://github.com/m0ver/bible-online) project as a real-world reference.

## Supported Databases

Tinystruct provides built-in support for multiple database systems:

- SQLite
- MySQL
- PostgreSQL
- H2
- Microsoft SQL Server
- Redis

## Configuration

### Database Properties

Configure your database connection in `application.properties`:

```properties
# SQLite Configuration (used by bible-online)
driver=org.sqlite.JDBC
database.url=jdbc:sqlite:src/main/resources/bible.db
database.user=
database.password=
database.connections.max=1

# MySQL Configuration
# driver=com.mysql.cj.jdbc.Driver
# database.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
# database.user=root
# database.password=password
# database.connections.max=10

# PostgreSQL Configuration (New in v1.7.30)
# driver=org.postgresql.Driver
# database.url=jdbc:postgresql://localhost:5432/mydb
# database.user=postgres
# database.password=password
# database.connections.max=10

# H2 Configuration
# driver=org.h2.Driver
# database.url=jdbc:h2:~/test
# database.user=sa
# database.password=
# database.connections.max=10
```

> **Tip:** `database.connections.max=1` is correct for an embedded SQLite file. For shared servers like MySQL, set it to `10` or higher.

You can also define a named database profile by wrapping settings in a section header:

```properties
[database]
driver=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://localhost:3306/mydb
database.user=root
database.password=secret
database.connections.max=10
```

---

## Database Access Approaches

Tinystruct offers two complementary approaches:

1. **Object Mapping (`AbstractData`)** - The primary ORM-style approach. Define a model class, an XML mapping file, and call built-in CRUD methods.
2. **`DatabaseOperator`** - A lower-level utility for raw SQL, aggregations, or operations spanning multiple tables.

---

## Object Mapping Approach

This is the **recommended approach** for working with database entities. It combines a Java POJO with an XML mapping file to provide transparent CRUD operations.

### 1. Define a Model Class

Extend `AbstractData` and use `setFieldAs*` helper methods in every setter. These helpers register the field with the ORM so `append()`, `update()`, and `delete()` know what to persist.

```java
package custom.objects;

import java.util.Date;
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;

public class User extends AbstractData {
    private String email;
    private String username;
    private String password;
    private String nickname;
    private int gender;
    private String firstName;
    private String lastName;
    private String country;
    private String city;
    private Date lastloginTime;
    private Date registrationTime;
    private boolean status;

    // Returns the auto-generated UUID string
    public String getId() {
        return String.valueOf(this.Id);
    }

    // Setters MUST call setFieldAs* to register the value with the ORM
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    public String getEmail() { return this.email; }

    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    public String getUsername() { return this.username; }

    public void setPassword(String password) {
        this.password = this.setFieldAsString("password", password);
    }
    public String getPassword() { return this.password; }

    public void setNickname(String nickname) {
        this.nickname = this.setFieldAsString("nickname", nickname);
    }
    public String getNickname() { return this.nickname; }

    public void setGender(int gender) {
        this.gender = this.setFieldAsInt("gender", gender);
    }
    public int getGender() { return this.gender; }

    public void setFirstName(String firstName) {
        this.firstName = this.setFieldAsString("firstName", firstName);
    }
    public String getFirstName() { return this.firstName; }

    public void setLastName(String lastName) {
        this.lastName = this.setFieldAsString("lastName", lastName);
    }
    public String getLastName() { return this.lastName; }

    public void setCountry(String country) {
        this.country = this.setFieldAsString("country", country);
    }
    public String getCountry() { return this.country; }

    public void setCity(String city) {
        this.city = this.setFieldAsString("city", city);
    }
    public String getCity() { return this.city; }

    public void setLastloginTime(Date lastloginTime) {
        this.lastloginTime = this.setFieldAsDate("lastloginTime", lastloginTime);
    }
    public Date getLastloginTime() { return this.lastloginTime; }

    public void setRegistrationTime(Date registrationTime) {
        this.registrationTime = this.setFieldAsDate("registrationTime", registrationTime);
    }
    public Date getRegistrationTime() { return this.registrationTime; }

    public void setStatus(boolean status) {
        this.status = this.setFieldAsBoolean("status", status);
    }
    public boolean getStatus() { return this.status; }

    // setData() maps database column names (snake_case) to Java fields
    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("password") != null)
            this.setPassword(row.getFieldInfo("password").stringValue());
        if (row.getFieldInfo("nickname") != null)
            this.setNickname(row.getFieldInfo("nickname").stringValue());
        if (row.getFieldInfo("gender") != null)
            this.setGender(row.getFieldInfo("gender").intValue());
        if (row.getFieldInfo("first_name") != null)
            this.setFirstName(row.getFieldInfo("first_name").stringValue());
        if (row.getFieldInfo("last_name") != null)
            this.setLastName(row.getFieldInfo("last_name").stringValue());
        if (row.getFieldInfo("country") != null)
            this.setCountry(row.getFieldInfo("country").stringValue());
        if (row.getFieldInfo("city") != null)
            this.setCity(row.getFieldInfo("city").stringValue());
        if (row.getFieldInfo("lastlogin_time") != null)
            this.setLastloginTime(row.getFieldInfo("lastlogin_time").dateValue());
        if (row.getFieldInfo("registration_time") != null)
            this.setRegistrationTime(row.getFieldInfo("registration_time").dateValue());
        if (row.getFieldInfo("status") != null)
            this.setStatus(row.getFieldInfo("status").booleanValue());
    }

    @Override
    public String toString() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("{");
        buffer.append("\"Id\":\"" + this.getId() + "\"");
        buffer.append(",\"email\":\"" + this.getEmail() + "\"");
        buffer.append(",\"username\":\"" + this.getUsername() + "\"");
        buffer.append(",\"nickname\":\"" + this.getNickname() + "\"");
        buffer.append(",\"gender\":" + this.getGender());
        buffer.append(",\"firstName\":\"" + this.getFirstName() + "\"");
        buffer.append(",\"lastName\":\"" + this.getLastName() + "\"");
        buffer.append(",\"country\":\"" + this.getCountry() + "\"");
        buffer.append(",\"city\":\"" + this.getCity() + "\"");
        buffer.append(",\"lastloginTime\":\"" + this.getLastloginTime() + "\"");
        buffer.append(",\"registrationTime\":\"" + this.getRegistrationTime() + "\"");
        buffer.append(",\"status\":" + this.getStatus());
        buffer.append("}");
        return buffer.toString();
    }
}
```

#### Available `setFieldAs*` Methods

| Method | Java Type | XML `type` |
|---|---|---|
| `setFieldAsString(name, value)` | `String` | `varchar`, `longtext` |
| `setFieldAsInt(name, value)` | `int` | `int` |
| `setFieldAsDate(name, value)` | `java.util.Date` | `datetime` |
| `setFieldAsBoolean(name, value)` | `boolean` | `bit` |
| `setFieldAsLocalDateTime(name, value)` | `LocalDateTime` | `DATETIME` |

### 2. Create an XML Mapping File

Place the file in `src/main/resources` under a path mirroring your Java package. For `custom.objects.User` the file goes at:

```
src/main/resources/custom/objects/User.map.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="User" table="User">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="email"            column="email"             length="50"  type="varchar"/>
  <property name="username"         column="username"          length="50"  type="varchar"/>
  <property name="password"         column="password"          length="15"  type="varchar"/>
  <property name="nickname"         column="nickname"          length="50"  type="varchar"/>
  <property name="gender"           column="gender"            length="4"   type="int"/>
  <property name="firstName"        column="first_name"        length="10"  type="varchar"/>
  <property name="lastName"         column="last_name"         length="10"  type="varchar"/>
  <property name="country"          column="country"           length="50"  type="varchar"/>
  <property name="city"             column="city"              length="50"  type="varchar"/>
  <property name="lastloginTime"    column="lastlogin_time"    length="0"   type="datetime"/>
  <property name="registrationTime" column="registration_time" length="0"   type="datetime"/>
  <property name="status"           column="status"            length="1"   type="bit"/>
 </class>
</mapping>
```

#### XML Mapping Key Attributes

| Attribute | Meaning |
|---|---|
| `name` on `<class>` | Simple class name only (no package prefix) |
| `table` | Database table name |
| `name` on `<property>` | Java property name (camelCase) |
| `column` | Database column name (typically snake_case) |
| `type` | SQL column type (`varchar`, `int`, `datetime`, `bit`, `longtext`, ...) |
| `length` | Column length; use `0` for variable-length types (`datetime`, `longtext`) |
| `increment="false"` on `<id>` | ID is not a numeric auto-increment |
| `generate="true"` on `<id>` | Framework auto-generates a UUID on `append()` |

> **UUID IDs**: bible-online uses `generate="true"` with `type="varchar"` for all entities. You never set the ID before calling `append()` - the framework generates a UUID automatically, and you can read it back immediately via `getId()`.

Here are two shorter mapping examples from the project:

**`bible.map.xml`** (verse table):
```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="bible" table="bible">
  <id name="Id" column="id" increment="false" generate="true" length="48" type="varchar"/>
  <property name="bookId"    column="book_id"    length="4" type="int"/>
  <property name="chapterId" column="chapter_id" length="4" type="int"/>
  <property name="partId"    column="part_id"    length="4" type="int"/>
  <property name="content"   column="content"    length="0" type="longtext"/>
 </class>
</mapping>
```

**`book.map.xml`**:
```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="book" table="book">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="bookId"   column="book_id"   length="4"   type="int"/>
  <property name="bookName" column="book_name" length="255" type="varchar"/>
  <property name="language" column="language"  length="10"  type="varchar"/>
 </class>
</mapping>
```

### 3. Alternative: Annotation-Driven Mapping *(New in v1.7.34)*

Starting from v1.7.34, the XML mapping file is **optional**. You can declare the full table-to-class mapping using Java annotations directly on your POJO:

| Annotation | Target | Purpose |
|---|---|---|
| `@Table` | Class | Maps the class to a named database table |
| `@Id` | Field | Marks the primary key field |
| `@Column` | Field | Maps a field to a specific column with name, type, and length |

#### Example: Annotation-mapped POJO

```java
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;
import org.tinystruct.data.component.Table;
import org.tinystruct.system.annotation.Column;
import org.tinystruct.system.annotation.Id;

@Table(name = "users")
public class User extends AbstractData {

    @Id
    @Column(name = "id", type = "VARCHAR", length = 50, autoGenerated = true)
    private String id;

    @Column(name = "email", type = "VARCHAR", length = 100)
    private String email;

    @Column(name = "username", type = "VARCHAR", length = 50)
    private String username;

    @Column(name = "status", type = "BIT", length = 1)
    private boolean status;

    // Setters must still call setFieldAs* to register values with the ORM
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    public String getEmail() { return this.email; }

    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    public String getUsername() { return this.username; }

    public void setStatus(boolean status) {
        this.status = this.setFieldAsBoolean("status", status);
    }
    public boolean getStatus() { return this.status; }

    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("status") != null)
            this.setStatus(row.getFieldInfo("status").booleanValue());
    }
}
```

No `User.map.xml` file is required — the framework reads the annotations at runtime.

> **Note:** The `setFieldAs*` calls in your setters are still required. Annotations only replace the XML file; the ORM's internal field registry still relies on those calls to know which fields to include in SQL statements.

#### Opt-In Table Auto-Creation

Add `autoCreate = true` to `@Table` and the framework will issue a `CREATE TABLE IF NOT EXISTS` statement the first time the entity is used. This is useful during development and testing:

```java
@Table(name = "sessions", autoCreate = true)
public class Session extends AbstractData {

    @Id
    @Column(name = "id", type = "VARCHAR", length = 64, autoGenerated = true)
    private String id;

    @Column(name = "user_id", type = "VARCHAR", length = 50)
    private String userId;

    @Column(name = "expires_at", type = "TIMESTAMP", length = 0)
    private java.time.LocalDateTime expiresAt;

    // setters, getters, setData() ...
}
```

> **Caution:** Auto-creation is disabled by default. It is intended for development and test environments only. Do not use it in production where schema changes are managed through migrations.

#### Choosing Between XML and Annotation Mapping

| | XML Mapping | Annotation Mapping |
|---|---|---|
| Available since | v1.0 | v1.7.34 |
| Config location | Separate `.map.xml` file | Inline on the POJO class |
| Auto-create table | Not supported | Supported via `autoCreate = true` |
| Runtime overhead | File I/O on first load | Reflection on first load |
| Recommended for | Legacy / complex mappings | New code, quick prototypes |

Both approaches are fully supported and can coexist in the same project.

---

### 4. CRUD Operations

#### Create - `append()`

```java
User user = new User();
user.setNickname(request.getParameter("nickname"));
user.setEmail(request.getParameter("email"));
user.setPassword(new Security(user.getEmail())
        .encodePassword(request.getParameter("password")));
user.setFirstName(request.getParameter("first-name"));
user.setLastName(request.getParameter("last-name"));
user.setGender(Integer.parseInt(request.getParameter("gender")));
user.setCountry(request.getParameter("country"));
user.setCity(request.getParameter("city"));
user.setLastloginTime(new Date());
user.setRegistrationTime(new Date());
user.append();  // INSERT; user.getId() now holds the generated UUID
```

#### Read - `findOneById()`

```java
User user = new User();
user.setId(someId);   // UUID string
user.findOneById();   // SELECT ... WHERE id = ?
System.out.println(user.getEmail());
```

#### Find with Conditions - `findWith()`

`findWith` is the primary query method. It accepts a parameterized WHERE / ORDER BY clause and a values array, and returns a `Table` (list of `Row` objects).

```java
// Find by username
User u = new User();
Table list = u.findWith("WHERE username=? AND status='1'",
        new Object[]{"james"});

if (list.size() > 0) {
    u.setData(list.get(0));  // hydrate the object from the first row
}
```

```java
// Find books for a specific locale
book b = new book();
Table table = b.findWith("WHERE book_id=? AND language=?",
        new Object[]{bookId, "en_US"});

if (!table.isEmpty()) {
    b.setData(table.get(0));
}
```

#### Find All - `findAll()`

```java
book b = new book();
Table list = b.findAll();

Iterator<Row> iter = list.iterator();
while (iter.hasNext()) {
    b.setData(iter.next());
    System.out.println(b.getBookName() + " (" + b.getLanguage() + ")");
}
```

#### Count / Aggregate - `setRequestFields()`

Use `setRequestFields()` to override the SELECT projection before calling `findWith()`. This is how bible-online checks for duplicate emails and retrieves chapter counts:

```java
// Guard against duplicate email during registration
int count = user
    .setRequestFields("count(*) as p")
    .findWith("WHERE email=?", new Object[]{email})
    .get(0).getFieldInfo("p").intValue();

if (count > 0) {
    throw new ApplicationException("Email already registered.");
}
```

```java
// Get the highest chapter number for a book
bible bible = new bible();
int maxChapter = bible
    .setRequestFields("max(chapter_id) as max_chapter")
    .findWith("WHERE book_id=?", new Object[]{bookId})
    .get(0).get(0).get("max_chapter").intValue();
```

#### Dynamic Table Switching - `setTableName()`

When one model maps to multiple structurally identical tables (e.g., different Bible translation versions), call `setTableName()` to switch the target at runtime:

```java
bible bible = new bible();
bible.setTableName("zh_CN");   // default: Chinese Simplified

if (request.getParameter("version") != null) {
    switch (request.getParameter("version")) {
        case "NIV": bible.setTableName("NIV"); break;
        case "ESV": bible.setTableName("ESV"); break;
        case "KJV": bible.setTableName("KJV"); break;
    }
}

// Query the selected version
Table verses = bible
    .setRequestFields("*")
    .findWith("WHERE book_id=? AND chapter_id=? ORDER BY part_id",
              new Object[]{bookId, chapterId});
```

This pattern lets you maintain separate translation tables (`NIV`, `ESV`, `KJV`, `zh_CN`, `zh_TW`, ...) while sharing a single model class and mapping file.

#### Update - `update()`

```java
// Record the login timestamp after successful authentication
user.setLastloginTime(new Date());
user.update();   // UPDATE ... WHERE id = ?
```

#### Delete - `delete()`

```java
user.delete();   // DELETE FROM ... WHERE id = ?
```

#### Upsert Pattern (check-then-write)

A common pattern in bible-online is to check for an existing record before deciding to insert or update:

```java
Log log = new Log();
Table logs = log.findWith("WHERE user_id=?",
        new Object[]{currentUser.getId()});

if (!logs.isEmpty()) {
    log.setData(logs.get(0));
    log.setDate(new Date());
    log.update();              // record exists - update it
} else {
    log.setUserId(currentUser.getId());
    log.setAction("Login Successful");
    log.setActionType(0);
    log.setDate(new Date());
    log.append();              // no record yet - insert it
}
```

### 4. Working with `Table` and `Row`

`findWith()` and `findAll()` return a `Table`, an indexed list of `Row` objects. A `Row` maps column names to `Field` values.

```java
Table table = bible.findWith(
    "WHERE book_id=? AND chapter_id=? ORDER BY part_id",
    new Object[]{bookId, chapterId});

for (int i = 0; i < table.size(); i++) {
    Row row = table.get(i);
    bible.setData(row);
    System.out.println(bible.getContent());
}
```

You can also read `Field` values directly without hydrating a model object:

```java
Row row = table.get(0);
int     maxChapter = row.getFieldInfo("max_chapter").intValue();
String  email      = row.getFieldInfo("email").stringValue();
Date    created    = row.getFieldInfo("registration_time").dateValue();
boolean active     = row.getFieldInfo("status").booleanValue();
```

### 6. Multi-Entity Workflow (User Registration)

The following example, drawn from bible-online's `register` application, shows how multiple `AbstractData` objects collaborate in a single workflow:

```java
public boolean append(Request request) throws ApplicationException {
    // 1. Build the User object from request parameters
    User user = new User();
    user.setNickname(request.getParameter("nickname"));
    user.setEmail(request.getParameter("email"));
    user.setPassword(new Security(user.getEmail())
            .encodePassword(request.getParameter("password")));
    user.setFirstName(request.getParameter("first-name"));
    user.setLastName(request.getParameter("last-name"));
    user.setGender(Integer.parseInt(request.getParameter("gender")));
    user.setCountry(request.getParameter("country"));
    user.setCity(request.getParameter("city"));
    user.setLastloginTime(new Date());
    user.setRegistrationTime(new Date());

    // 2. Guard against duplicate emails
    int count = user
        .setRequestFields("count(*) as p")
        .findWith("WHERE email=?", new Object[]{user.getEmail()})
        .get(0).getFieldInfo("p").intValue();

    if (count > 0) {
        throw new ApplicationException("Email already registered.");
    }

    // 3. Insert the user record (UUID is generated automatically)
    user.append();

    // 4. Assign the new user to the default member group
    Member member = new Member();
    member.setUserId(user.getId());  // user.getId() returns the new UUID
    member.setGroupId("386e27c2-5db6-4f63-b28d-68a4adec2fd6");
    member.append();

    return true;
}
```

---

## In-Memory Caching with `Cache`

For read-heavy, rarely-changing data (book metadata, chapter counts), bible-online uses tinystruct's built-in `Cache` singleton to avoid repeated database queries:

```java
private static final Cache data = Cache.getInstance();

// Try cache before hitting the database
String cacheKey = "book:" + bookId + ":lang:" + lang;
book book;

if (data.get(cacheKey) != null) {
    book = (book) data.get(cacheKey);
} else {
    book = new book();
    Table table = book.findWith("WHERE book_id=? AND language=?",
            new Object[]{bookId, lang});
    if (!table.isEmpty()) {
        book.setData(table.get(0));
    }
    data.set(cacheKey, book);  // warm the cache for subsequent requests
}
```

The same pattern applies to aggregate results:

```java
String maxChapterKey = "book:" + bookId + ":max_chapter";
int maxChapter;

if (data.get(maxChapterKey) != null) {
    maxChapter = (int) data.get(maxChapterKey);
} else {
    maxChapter = bible
        .setRequestFields("max(chapter_id) as max_chapter")
        .findWith("WHERE book_id=?", new Object[]{bookId})
        .get(0).get(0).get("max_chapter").intValue();
    data.set(maxChapterKey, maxChapter);
}
```

Use `Cache` for data that:
- Is read very frequently
- Changes rarely within a process lifecycle
- Is small enough to live safely in heap memory

---

## DatabaseOperator

For raw SQL, multi-table joins, or anything not covered by the object-mapping API, use `DatabaseOperator`.

### Creating a DatabaseOperator

```java
// Default - borrows a connection from the ConnectionManager pool
DatabaseOperator operator = new DatabaseOperator();

// Named profile (matches a [section] in application.properties)
DatabaseOperator operator = new DatabaseOperator("myDatabase");

// From an existing connection
DatabaseOperator operator = new DatabaseOperator(connection);
```

### Executing Queries

```java
// Parameterized query (always preferred over string concatenation)
PreparedStatement stmt = operator.preparedStatement(
    "SELECT id, username, email FROM User WHERE id = ?",
    new Object[]{userId}
);
ResultSet results = operator.executeQuery(stmt);

while (results.next()) {
    String email = results.getString("email");
}
```

### Executing Updates

```java
PreparedStatement stmt = operator.preparedStatement(
    "INSERT INTO User (username, email) VALUES (?, ?)",
    new Object[]{"james", "james@example.com"}
);
int rowsAffected = operator.executeUpdate(stmt);
```

### Resource Management

Always use try-with-resources so the connection is returned to the pool:

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM User");
    // process results
} // closes ResultSet, PreparedStatement, and releases the connection
```

### SQL Injection Protection

`DatabaseOperator` checks for injection patterns by default. Disable only for trusted internal tools:

```java
operator.disableSafeCheck();
```

### Transactions

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    try {
        PreparedStatement s1 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?",
            new Object[]{amount, fromId}
        );
        operator.executeUpdate(s1);

        PreparedStatement s2 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            new Object[]{amount, toId}
        );
        operator.executeUpdate(s2);

        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

#### Transaction Methods

| Method | Description |
|---|---|
| `beginTransaction()` | Start a new transaction |
| `commitTransaction()` | Commit the current transaction |
| `rollbackTransaction()` | Roll back the entire transaction |
| `rollbackTransaction(Savepoint)` | Roll back to a specific savepoint |
| `createSavepoint(String)` | Create a named savepoint |
| `releaseSavepoint(Savepoint)` | Release a savepoint |
| `isInTransaction()` | Returns `true` if a transaction is active |

> If a `DatabaseOperator` is closed while a transaction is active, the transaction is **automatically rolled back** to protect data integrity.

---

## Built-in POJO Generator

Tinystruct includes a code generator that produces model classes and XML mapping files directly from your database schema. Supports **MySQL**, **MSSQL**, **SQLite**, and **H2**.

### Running the Generator

```bash
# Interactive mode
bin/dispatcher generate

# Non-interactive - single table
bin/dispatcher generate --tables users

# Multiple tables (semicolon-delimited)
bin/dispatcher generate --tables "users;orders;products"
```

### Automatic Type Mappings

| SQL Column Type | Java Type | `setFieldAs*` Method |
|---|---|---|
| `VARCHAR`, `CHAR`, `TEXT` | `String` | `setFieldAsString` |
| `INT`, `SMALLINT`, `TINYINT` | `int` | `setFieldAsInt` |
| `BIGINT` | `long` | *(raw field)* |
| `FLOAT` | `float` | *(raw field)* |
| `DOUBLE` | `double` | *(raw field)* |
| `DATETIME`, `TIMESTAMP` | `LocalDateTime` | `setFieldAsLocalDateTime` |
| `DATE` | `java.util.Date` | `setFieldAsDate` |
| `BIT`, `BOOLEAN` | `boolean` | `setFieldAsBoolean` |
| `BLOB`, `BINARY`, `VARBINARY` | `byte[]` | *(raw field)* |

The generator produces two files per table:

1. **Java POJO** - e.g. `src/main/java/custom/objects/User.java`
2. **XML Mapping** - e.g. `src/main/resources/custom/objects/User.map.xml`

---

## Best Practices

1. **Always call `setFieldAs*` in every setter.** Without it, the ORM does not know the field needs persisting, and `append()` / `update()` will silently skip it.

2. **Use database column names in `setData()`.** `row.getFieldInfo()` keys must be actual database column names (snake_case), not Java property names.

3. **Always use parameterized queries.** Pass values through the `Object[]` parameter of `findWith()` or `preparedStatement()`. Never concatenate user input into SQL strings.

4. **Cache stable reference data.** Use `Cache.getInstance()` to avoid repeated lookups for rarely-changing data (book lists, chapter counts, locale metadata).

5. **Use `setTableName()` for versioned tables.** When one model covers multiple structurally identical tables (e.g. Bible translation versions), switch at runtime with `setTableName()`.

6. **Use `setRequestFields()` for aggregate queries.** Override the SELECT projection (e.g. `"count(*) as n"`, `"max(chapter_id) as max_chapter"`) before calling `findWith()`.

7. **UUID IDs are generated automatically.** When `generate="true"` is in the XML mapping, `append()` writes a new UUID into the table and `getId()` returns it immediately. Never set the ID yourself before inserting.

8. **Wrap `DatabaseOperator` in try-with-resources.** This guarantees the connection is returned to the pool even if an exception is thrown.

9. **Match the mapping file path to the Java package.** A class `custom.objects.User` requires its mapping at `custom/objects/User.map.xml` on the classpath root.

---

## Next Steps

- Learn about [Advanced Features](advanced-features.md)
- Explore [Best Practices](best-practices.md)
- Check out the [Database API Reference](api/database.md)
