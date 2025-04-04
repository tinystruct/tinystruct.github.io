# Best Practices for tinystruct

This guide provides recommended best practices for developing applications with the tinystruct framework.

## Project Structure

### Recommended Directory Layout

```
my-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── Application.java       # Main application class
│   │   │           ├── actions/               # Action classes
│   │   │           ├── models/                # Domain model classes
│   │   │           ├── services/              # Service classes
│   │   │           ├── repositories/          # Data access classes
│   │   │           ├── utils/                 # Utility classes
│   │   │           └── config/                # Configuration classes
│   │   └── resources/
│   │       ├── config.properties             # Main configuration
│   │       ├── config.dev.properties         # Development configuration
│   │       ├── config.prod.properties        # Production configuration
│   │       ├── messages/                     # Internationalization files
│   │       └── templates/                    # HTML templates
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   ├── actions/              # Action tests
│                   ├── services/             # Service tests
│                   └── repositories/         # Repository tests
├── bin/
│   └── dispatcher                           # tinystruct dispatcher script
└── pom.xml                                  # Maven configuration
```

### Package Organization

Organize your code into logical packages:

- **actions**: Contains all action classes that handle requests
- **models**: Contains domain model classes
- **services**: Contains business logic
- **repositories**: Contains data access code
- **utils**: Contains utility classes
- **config**: Contains configuration classes

## Coding Practices

### Action Classes

1. **Single Responsibility**: Each action class should focus on a specific area of functionality.

```java
// Good: Focused on user management
public class UserActions extends AbstractApplication {
    @Action("users")
    public JsonResponse getUsers() { ... }
    
    @Action("users/{id}")
    public JsonResponse getUser(Integer id) { ... }
    
    @Action("users/create")
    public JsonResponse createUser(Request request) { ... }
}

// Good: Focused on authentication
public class AuthActions extends AbstractApplication {
    @Action("login")
    public Response login(Request request) { ... }
    
    @Action("logout")
    public Response logout(Request request) { ... }
}
```

2. **Thin Actions**: Keep action methods thin by delegating business logic to service classes.

```java
// Good: Thin action method
@Action("users")
public JsonResponse getUsers() {
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}

// Bad: Action method with business logic
@Action("users")
public JsonResponse getUsers() {
    Repository repository = Type.MySQL.createRepository();
    repository.connect(getConfiguration());
    
    List<Row> rows = repository.query("SELECT * FROM users");
    List<User> users = new ArrayList<>();
    
    for (Row row : rows) {
        User user = new User();
        user.setId(row.getInt("id"));
        user.setName(row.getString("name"));
        user.setEmail(row.getString("email"));
        users.add(user);
    }
    
    return new JsonResponse(users);
}
```

3. **Input Validation**: Always validate input parameters.

```java
@Action("users/create")
public JsonResponse createUser(Request request) {
    String name = request.getParameter("name");
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    
    // Validate input
    List<String> errors = new ArrayList<>();
    
    if (name == null || name.trim().isEmpty()) {
        errors.add("Name is required");
    }
    
    if (email == null || !email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
        errors.add("Valid email is required");
    }
    
    if (password == null || password.length() < 8) {
        errors.add("Password must be at least 8 characters");
    }
    
    if (!errors.isEmpty()) {
        return new JsonResponse(Map.of("success", false, "errors", errors));
    }
    
    // Process valid input
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    User user = userService.createUser(name, email, password);
    
    return new JsonResponse(Map.of("success", true, "user", user));
}
```

### Service Layer

1. **Business Logic Encapsulation**: Encapsulate business logic in service classes.

```java
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    
    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    @Override
    public User createUser(String name, String email, String password) {
        // Check if email already exists
        if (userRepository.findByEmail(email) != null) {
            throw new ApplicationException("Email already in use");
        }
        
        // Hash password
        String hashedPassword = PasswordUtils.hashPassword(password);
        
        // Create user
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPassword(hashedPassword);
        user.setCreatedAt(new Date());
        
        // Save user
        return userRepository.save(user);
    }
}
```

2. **Transaction Management**: Handle transactions at the service layer.

```java
public class TransferServiceImpl implements TransferService {
    private final AccountRepository accountRepository;
    
    @Override
    public void transferFunds(int fromAccountId, int toAccountId, double amount) {
        Repository repository = accountRepository.getRepository();
        
        try {
            repository.setAutoCommit(false);
            
            Account fromAccount = accountRepository.findById(fromAccountId);
            Account toAccount = accountRepository.findById(toAccountId);
            
            if (fromAccount == null) {
                throw new ApplicationException("Source account not found");
            }
            
            if (toAccount == null) {
                throw new ApplicationException("Destination account not found");
            }
            
            if (fromAccount.getBalance() < amount) {
                throw new ApplicationException("Insufficient funds");
            }
            
            fromAccount.setBalance(fromAccount.getBalance() - amount);
            toAccount.setBalance(toAccount.getBalance() + amount);
            
            accountRepository.update(fromAccount);
            accountRepository.update(toAccount);
            
            // Log transaction
            TransactionLog log = new TransactionLog();
            log.setFromAccountId(fromAccountId);
            log.setToAccountId(toAccountId);
            log.setAmount(amount);
            log.setTimestamp(new Date());
            transactionLogRepository.save(log);
            
            repository.commit();
        } catch (Exception e) {
            repository.rollback();
            throw new ApplicationRuntimeException("Transfer failed: " + e.getMessage(), e);
        } finally {
            repository.setAutoCommit(true);
        }
    }
}
```

### Repository Layer

1. **Data Access Abstraction**: Abstract database access behind repository interfaces.

```java
public interface UserRepository {
    User findById(int id);
    User findByEmail(String email);
    List<User> findAll();
    User save(User user);
    void update(User user);
    void delete(int id);
}

public class MySQLUserRepository implements UserRepository {
    private final Repository repository;
    
    public MySQLUserRepository(Repository repository) {
        this.repository = repository;
    }
    
    @Override
    public User findById(int id) {
        List<Row> rows = repository.query("SELECT * FROM users WHERE id = ?", id);
        
        if (rows.isEmpty()) {
            return null;
        }
        
        return mapRowToUser(rows.get(0));
    }
    
    private User mapRowToUser(Row row) {
        User user = new User();
        user.setId(row.getInt("id"));
        user.setName(row.getString("name"));
        user.setEmail(row.getString("email"));
        user.setPassword(row.getString("password"));
        user.setCreatedAt(row.getTimestamp("created_at"));
        return user;
    }
}
```

2. **Connection Management**: Properly manage database connections.

```java
public class RepositoryFactory {
    private static final Repository repository;
    
    static {
        repository = Type.MySQL.createRepository();
        
        // Register shutdown hook to close connection
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                repository.close();
            } catch (Exception e) {
                System.err.println("Error closing repository: " + e.getMessage());
            }
        }));
    }
    
    public static Repository getRepository() {
        return repository;
    }
}
```

## Error Handling

1. **Consistent Error Handling**: Implement consistent error handling across your application.

```java
@Action("api/users/{id}")
public Response getUser(Integer id) {
    try {
        UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
        User user = userService.findById(id);
        
        if (user == null) {
            return new ErrorResponse(404, "User not found");
        }
        
        return new JsonResponse(user);
    } catch (Exception e) {
        logger.error("Error retrieving user", e);
        return new ErrorResponse(500, "Internal server error");
    }
}
```

2. **Custom Exception Classes**: Create custom exception classes for different error types.

```java
public class ResourceNotFoundException extends ApplicationException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}

public class ValidationException extends ApplicationException {
    private final List<String> errors;
    
    public ValidationException(List<String> errors) {
        super("Validation failed");
        this.errors = errors;
    }
    
    public List<String> getErrors() {
        return errors;
    }
}
```

3. **Global Error Handler**: Implement a global error handler for consistent error responses.

```java
public class ErrorHandlerInterceptor implements ActionInterceptor {
    private static final Logger logger = Logger.getLogger(ErrorHandlerInterceptor.class.getName());
    
    @Override
    public boolean before(Action action, Object[] args) {
        return true;
    }
    
    @Override
    public void after(Action action, Object result) {
        // No action needed
    }
    
    @Override
    public void onException(Action action, Exception e) {
        // Find request in arguments
        Request request = null;
        for (Object arg : action.getArguments()) {
            if (arg instanceof Request) {
                request = (Request) arg;
                break;
            }
        }
        
        if (request == null) {
            return;
        }
        
        Response response;
        
        if (e instanceof ResourceNotFoundException) {
            response = new ErrorResponse(404, e.getMessage());
        } else if (e instanceof ValidationException) {
            ValidationException ve = (ValidationException) e;
            response = new JsonResponse(Map.of(
                "success", false,
                "errors", ve.getErrors()
            ));
            ((JsonResponse) response).setStatus(400);
        } else if (e instanceof AuthenticationException) {
            response = new ErrorResponse(401, e.getMessage());
        } else if (e instanceof AuthorizationException) {
            response = new ErrorResponse(403, e.getMessage());
        } else {
            logger.log(Level.SEVERE, "Unhandled exception", e);
            response = new ErrorResponse(500, "Internal server error");
        }
        
        request.setAttribute("_response", response);
    }
}
```

## Security

1. **Password Hashing**: Always hash passwords before storing them.

```java
public class PasswordUtils {
    public static String hashPassword(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(12));
    }
    
    public static boolean verifyPassword(String password, String hashedPassword) {
        return BCrypt.checkpw(password, hashedPassword);
    }
}
```

2. **Input Sanitization**: Sanitize user input to prevent XSS attacks.

```java
public class SecurityUtils {
    public static String sanitizeHtml(String input) {
        if (input == null) {
            return null;
        }
        
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;")
            .replace("/", "&#x2F;");
    }
}
```

3. **CSRF Protection**: Implement CSRF protection for forms.

```java
public class CsrfUtils {
    public static String generateToken(Session session) {
        String token = UUID.randomUUID().toString();
        session.setAttribute("csrf_token", token);
        return token;
    }
    
    public static boolean validateToken(Session session, String token) {
        String storedToken = (String) session.getAttribute("csrf_token");
        return storedToken != null && storedToken.equals(token);
    }
}

@Action("form")
public Response showForm(Request request) {
    Session session = request.getSession(true);
    String csrfToken = CsrfUtils.generateToken(session);
    
    Map<String, Object> model = new HashMap<>();
    model.put("csrfToken", csrfToken);
    
    return new TemplateResponse("form.html", model);
}

@Action("submit")
public Response processForm(Request request) {
    Session session = request.getSession(false);
    String csrfToken = request.getParameter("csrf_token");
    
    if (session == null || !CsrfUtils.validateToken(session, csrfToken)) {
        return new ErrorResponse(403, "Invalid CSRF token");
    }
    
    // Process form
}
```

## Performance

1. **Caching**: Use caching for frequently accessed data.

```java
@Action("products")
public JsonResponse getProducts() {
    @SuppressWarnings("unchecked")
    List<Product> products = (List<Product>) CacheManager.get("all_products");
    
    if (products == null) {
        ProductService productService = ServiceRegistry.getInstance().getService(ProductService.class);
        products = productService.findAll();
        
        // Cache for 10 minutes
        CacheManager.put("all_products", products, 10 * 60 * 1000);
    }
    
    return new JsonResponse(products);
}
```

2. **Database Optimization**: Optimize database queries.

```java
// Good: Fetch only needed columns
List<Row> users = repository.query("SELECT id, name, email FROM users");

// Bad: Fetch all columns
List<Row> users = repository.query("SELECT * FROM users");

// Good: Use pagination
List<Row> users = repository.query(
    "SELECT id, name, email FROM users LIMIT ? OFFSET ?",
    pageSize, (pageNumber - 1) * pageSize
);
```

3. **Connection Pooling**: Configure appropriate connection pool settings.

```properties
# config.properties
database.connections.max=10
database.connections.idle.max=5
database.connections.idle.timeout=300000
```

## Testing

1. **Unit Testing**: Write unit tests for your services and repositories.

```java
public class UserServiceTest {
    private UserService userService;
    private UserRepository userRepository;
    
    @Before
    public void setUp() {
        userRepository = mock(UserRepository.class);
        userService = new UserServiceImpl(userRepository);
    }
    
    @Test
    public void testCreateUser() {
        // Arrange
        String name = "John Doe";
        String email = "john@example.com";
        String password = "password123";
        
        User savedUser = new User();
        savedUser.setId(1);
        savedUser.setName(name);
        savedUser.setEmail(email);
        
        when(userRepository.findByEmail(email)).thenReturn(null);
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        
        // Act
        User result = userService.createUser(name, email, password);
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals(name, result.getName());
        assertEquals(email, result.getEmail());
        
        verify(userRepository).findByEmail(email);
        verify(userRepository).save(any(User.class));
    }
    
    @Test(expected = ApplicationException.class)
    public void testCreateUser_EmailExists() {
        // Arrange
        String email = "john@example.com";
        
        User existingUser = new User();
        existingUser.setEmail(email);
        
        when(userRepository.findByEmail(email)).thenReturn(existingUser);
        
        // Act
        userService.createUser("John Doe", email, "password123");
        
        // Assert: expect ApplicationException
    }
}
```

2. **Integration Testing**: Write integration tests for your actions.

```java
public class UserActionsIntegrationTest {
    private static AbstractApplication application;
    private static Repository repository;
    
    @BeforeClass
    public static void setUpClass() {
        application = new TestApplication();
        application.init();
        
        repository = Type.H2.createRepository();
        repository.connect(application.getConfiguration());
        
        // Set up test database
        repository.execute("CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), email VARCHAR(100), password VARCHAR(100), created_at TIMESTAMP)");
    }
    
    @Before
    public void setUp() {
        // Clear test data
        repository.execute("DELETE FROM users");
        
        // Insert test data
        repository.execute("INSERT INTO users (name, email, password, created_at) VALUES (?, ?, ?, NOW())", "Test User", "test@example.com", "password");
    }
    
    @Test
    public void testGetUsers() {
        // Arrange
        MockRequest request = new MockRequest();
        
        // Act
        Object result = application.execute("users", request);
        
        // Assert
        assertTrue(result instanceof JsonResponse);
        JsonResponse response = (JsonResponse) result;
        
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> users = (List<Map<String, Object>>) response.getData();
        
        assertEquals(1, users.size());
        assertEquals("Test User", users.get(0).get("name"));
        assertEquals("test@example.com", users.get(0).get("email"));
    }
}
```

## Deployment

1. **Environment-Specific Configuration**: Use environment-specific configuration files.

```java
public class Application extends AbstractApplication {
    @Override
    public void init() {
        // Load base configuration
        getConfiguration().load("config.properties");
        
        // Load environment-specific configuration
        String env = System.getProperty("env", "dev");
        getConfiguration().load("config." + env + ".properties");
        
        System.out.println("Application initialized with " + env + " environment");
    }
}
```

2. **Logging Configuration**: Configure appropriate logging for each environment.

```properties
# config.dev.properties
logging.level=FINE
logging.console=true
logging.file=false

# config.prod.properties
logging.level=INFO
logging.console=false
logging.file=true
logging.file.path=/var/log/myapp.log
logging.file.max.size=10MB
logging.file.max.count=10
```

3. **Health Checks**: Implement health check endpoints.

```java
@Action("health")
public JsonResponse healthCheck() {
    Map<String, Object> status = new HashMap<>();
    status.put("status", "UP");
    status.put("timestamp", new Date());
    
    // Check database connection
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        repository.query("SELECT 1");
        status.put("database", "UP");
    } catch (Exception e) {
        status.put("database", "DOWN");
        status.put("database_error", e.getMessage());
        status.put("status", "DOWN");
    }
    
    // Check other dependencies
    // ...
    
    return new JsonResponse(status);
}
```

## Documentation

1. **Code Documentation**: Document your code with clear comments.

```java
/**
 * Transfers funds between two accounts.
 *
 * @param fromAccountId The source account ID
 * @param toAccountId The destination account ID
 * @param amount The amount to transfer
 * @throws ApplicationException If the transfer fails
 */
public void transferFunds(int fromAccountId, int toAccountId, double amount) {
    // Implementation
}
```

2. **API Documentation**: Document your API endpoints.

```java
/**
 * Retrieves a user by ID.
 *
 * @param id The user ID
 * @return JsonResponse containing the user data
 * @response 200 User found
 * @response 404 User not found
 * @response 500 Internal server error
 */
@Action("users/{id}")
public JsonResponse getUser(Integer id) {
    // Implementation
}
```

## Next Steps

- Explore the [API Reference](api/README.md)
- Check out [Advanced Features](advanced-features.md)
