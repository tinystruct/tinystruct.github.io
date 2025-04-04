# tinystruct 最佳实践

本指南提供了使用 tinystruct 框架开发应用程序的推荐最佳实践。

## 项目结构

### 推荐目录布局

```
my-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── Application.java       # 主应用程序类
│   │   │           ├── actions/               # 动作类
│   │   │           ├── models/                # 领域模型类
│   │   │           ├── services/              # 服务类
│   │   │           ├── repositories/          # 数据访问类
│   │   │           ├── utils/                 # 实用工具类
│   │   │           └── config/                # 配置类
│   │   └── resources/
│   │       ├── config.properties             # 主配置
│   │       ├── config.dev.properties         # 开发配置
│   │       ├── config.prod.properties        # 生产配置
│   │       ├── messages/                     # 国际化文件
│   │       └── templates/                    # HTML 模板
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   ├── actions/              # 动作测试
│                   ├── services/             # 服务测试
│                   └── repositories/         # 仓库测试
├── bin/
│   └── dispatcher                           # tinystruct 调度器脚本
└── pom.xml                                  # Maven 配置
```

### 包组织

将代码组织成逻辑包：

- **actions**：包含处理请求的所有动作类
- **models**：包含领域模型类
- **services**：包含业务逻辑
- **repositories**：包含数据访问代码
- **utils**：包含实用工具类
- **config**：包含配置类

## 编码实践

### 动作类

1. **单一职责**：每个动作类应专注于特定的功能领域。

```java
// 好：专注于用户管理
public class UserActions extends AbstractApplication {
    @Action("users")
    public JsonResponse getUsers() { ... }
    
    @Action("users/{id}")
    public JsonResponse getUser(Integer id) { ... }
    
    @Action("users/create")
    public JsonResponse createUser(Request request) { ... }
}

// 好：专注于身份验证
public class AuthActions extends AbstractApplication {
    @Action("login")
    public Response login(Request request) { ... }
    
    @Action("logout")
    public Response logout(Request request) { ... }
}
```

2. **精简动作**：通过将业务逻辑委托给服务类来保持动作方法精简。

```java
// 好：精简的动作方法
@Action("users")
public JsonResponse getUsers() {
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}

// 坏：包含业务逻辑的动作方法
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

3. **输入验证**：始终验证输入参数。

```java
@Action("users/create")
public JsonResponse createUser(Request request) {
    String name = request.getParameter("name");
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    
    // 验证输入
    List<String> errors = new ArrayList<>();
    
    if (name == null || name.trim().isEmpty()) {
        errors.add("名称是必需的");
    }
    
    if (email == null || !email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
        errors.add("需要有效的电子邮件");
    }
    
    if (password == null || password.length() < 8) {
        errors.add("密码必须至少为 8 个字符");
    }
    
    if (!errors.isEmpty()) {
        return new JsonResponse(Map.of("success", false, "errors", errors));
    }
    
    // 处理有效输入
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    User user = userService.createUser(name, email, password);
    
    return new JsonResponse(Map.of("success", true, "user", user));
}
```

### 服务层

1. **业务逻辑封装**：在服务类中封装业务逻辑。

```java
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    
    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    @Override
    public User createUser(String name, String email, String password) {
        // 检查电子邮件是否已存在
        if (userRepository.findByEmail(email) != null) {
            throw new ApplicationException("电子邮件已被使用");
        }
        
        // 哈希密码
        String hashedPassword = PasswordUtils.hashPassword(password);
        
        // 创建用户
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPassword(hashedPassword);
        user.setCreatedAt(new Date());
        
        // 保存用户
        return userRepository.save(user);
    }
}
```

2. **事务管理**：在服务层处理事务。

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
                throw new ApplicationException("未找到源账户");
            }
            
            if (toAccount == null) {
                throw new ApplicationException("未找到目标账户");
            }
            
            if (fromAccount.getBalance() < amount) {
                throw new ApplicationException("资金不足");
            }
            
            fromAccount.setBalance(fromAccount.getBalance() - amount);
            toAccount.setBalance(toAccount.getBalance() + amount);
            
            accountRepository.update(fromAccount);
            accountRepository.update(toAccount);
            
            // 记录交易
            TransactionLog log = new TransactionLog();
            log.setFromAccountId(fromAccountId);
            log.setToAccountId(toAccountId);
            log.setAmount(amount);
            log.setTimestamp(new Date());
            transactionLogRepository.save(log);
            
            repository.commit();
        } catch (Exception e) {
            repository.rollback();
            throw new ApplicationRuntimeException("转账失败：" + e.getMessage(), e);
        } finally {
            repository.setAutoCommit(true);
        }
    }
}
```

### 仓库层

1. **数据访问抽象**：在仓库接口后面抽象数据库访问。

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

2. **连接管理**：正确管理数据库连接。

```java
public class RepositoryFactory {
    private static final Repository repository;
    
    static {
        repository = Type.MySQL.createRepository();
        
        // 注册关闭钩子以关闭连接
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                repository.close();
            } catch (Exception e) {
                System.err.println("关闭仓库时出错：" + e.getMessage());
            }
        }));
    }
    
    public static Repository getRepository() {
        return repository;
    }
}
```

## 错误处理

1. **一致的错误处理**：在整个应用程序中实现一致的错误处理。

```java
@Action("api/users/{id}")
public Response getUser(Integer id) {
    try {
        UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
        User user = userService.findById(id);
        
        if (user == null) {
            return new ErrorResponse(404, "未找到用户");
        }
        
        return new JsonResponse(user);
    } catch (Exception e) {
        logger.error("检索用户时出错", e);
        return new ErrorResponse(500, "内部服务器错误");
    }
}
```

2. **自定义异常类**：为不同的错误类型创建自定义异常类。

```java
public class ResourceNotFoundException extends ApplicationException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}

public class ValidationException extends ApplicationException {
    private final List<String> errors;
    
    public ValidationException(List<String> errors) {
        super("验证失败");
        this.errors = errors;
    }
    
    public List<String> getErrors() {
        return errors;
    }
}
```

3. **全局错误处理程序**：实现全局错误处理程序以获得一致的错误响应。

```java
public class ErrorHandlerInterceptor implements ActionInterceptor {
    private static final Logger logger = Logger.getLogger(ErrorHandlerInterceptor.class.getName());
    
    @Override
    public boolean before(Action action, Object[] args) {
        return true;
    }
    
    @Override
    public void after(Action action, Object result) {
        // 不需要操作
    }
    
    @Override
    public void onException(Action action, Exception e) {
        // 在参数中查找请求
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
            logger.log(Level.SEVERE, "未处理的异常", e);
            response = new ErrorResponse(500, "内部服务器错误");
        }
        
        request.setAttribute("_response", response);
    }
}
```

## 安全性

1. **密码哈希**：在存储密码之前始终对其进行哈希处理。

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

2. **输入净化**：净化用户输入以防止 XSS 攻击。

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

3. **CSRF 保护**：为表单实现 CSRF 保护。

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
        return new ErrorResponse(403, "无效的 CSRF 令牌");
    }
    
    // 处理表单
}
```

## 性能

1. **缓存**：对频繁访问的数据使用缓存。

```java
@Action("products")
public JsonResponse getProducts() {
    @SuppressWarnings("unchecked")
    List<Product> products = (List<Product>) CacheManager.get("all_products");
    
    if (products == null) {
        ProductService productService = ServiceRegistry.getInstance().getService(ProductService.class);
        products = productService.findAll();
        
        // 缓存 10 分钟
        CacheManager.put("all_products", products, 10 * 60 * 1000);
    }
    
    return new JsonResponse(products);
}
```

2. **数据库优化**：优化数据库查询。

```java
// 好：仅获取所需列
List<Row> users = repository.query("SELECT id, name, email FROM users");

// 坏：获取所有列
List<Row> users = repository.query("SELECT * FROM users");

// 好：使用分页
List<Row> users = repository.query(
    "SELECT id, name, email FROM users LIMIT ? OFFSET ?",
    pageSize, (pageNumber - 1) * pageSize
);
```

3. **连接池**：配置适当的连接池设置。

```properties
# config.properties
database.connections.max=10
database.connections.idle.max=5
database.connections.idle.timeout=300000
```

## 测试

1. **单元测试**：为您的服务和仓库编写单元测试。

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
        // 安排
        String name = "张三";
        String email = "zhangsan@example.com";
        String password = "password123";
        
        User savedUser = new User();
        savedUser.setId(1);
        savedUser.setName(name);
        savedUser.setEmail(email);
        
        when(userRepository.findByEmail(email)).thenReturn(null);
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        
        // 行动
        User result = userService.createUser(name, email, password);
        
        // 断言
        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals(name, result.getName());
        assertEquals(email, result.getEmail());
        
        verify(userRepository).findByEmail(email);
        verify(userRepository).save(any(User.class));
    }
    
    @Test(expected = ApplicationException.class)
    public void testCreateUser_EmailExists() {
        // 安排
        String email = "zhangsan@example.com";
        
        User existingUser = new User();
        existingUser.setEmail(email);
        
        when(userRepository.findByEmail(email)).thenReturn(existingUser);
        
        // 行动
        userService.createUser("张三", email, "password123");
        
        // 断言：期望 ApplicationException
    }
}
```

2. **集成测试**：为您的动作编写集成测试。

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
        
        // 设置测试数据库
        repository.execute("CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), email VARCHAR(100), password VARCHAR(100), created_at TIMESTAMP)");
    }
    
    @Before
    public void setUp() {
        // 清除测试数据
        repository.execute("DELETE FROM users");
        
        // 插入测试数据
        repository.execute("INSERT INTO users (name, email, password, created_at) VALUES (?, ?, ?, NOW())", "测试用户", "test@example.com", "password");
    }
    
    @Test
    public void testGetUsers() {
        // 安排
        MockRequest request = new MockRequest();
        
        // 行动
        Object result = application.execute("users", request);
        
        // 断言
        assertTrue(result instanceof JsonResponse);
        JsonResponse response = (JsonResponse) result;
        
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> users = (List<Map<String, Object>>) response.getData();
        
        assertEquals(1, users.size());
        assertEquals("测试用户", users.get(0).get("name"));
        assertEquals("test@example.com", users.get(0).get("email"));
    }
}
```

## 部署

1. **环境特定配置**：使用环境特定的配置文件。

```java
public class Application extends AbstractApplication {
    @Override
    public void init() {
        // 加载基本配置
        getConfiguration().load("config.properties");
        
        // 加载环境特定配置
        String env = System.getProperty("env", "dev");
        getConfiguration().load("config." + env + ".properties");
        
        System.out.println("应用程序已使用 " + env + " 环境初始化");
    }
}
```

2. **日志配置**：为每个环境配置适当的日志记录。

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

3. **健康检查**：实现健康检查端点。

```java
@Action("health")
public JsonResponse healthCheck() {
    Map<String, Object> status = new HashMap<>();
    status.put("status", "UP");
    status.put("timestamp", new Date());
    
    // 检查数据库连接
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
    
    // 检查其他依赖项
    // ...
    
    return new JsonResponse(status);
}
```

## 文档

1. **代码文档**：使用清晰的注释记录您的代码。

```java
/**
 * 在两个账户之间转账。
 *
 * @param fromAccountId 源账户 ID
 * @param toAccountId 目标账户 ID
 * @param amount 要转账的金额
 * @throws ApplicationException 如果转账失败
 */
public void transferFunds(int fromAccountId, int toAccountId, double amount) {
    // 实现
}
```

2. **API 文档**：记录您的 API 端点。

```java
/**
 * 通过 ID 检索用户。
 *
 * @param id 用户 ID
 * @return 包含用户数据的 JsonResponse
 * @response 200 找到用户
 * @response 404 未找到用户
 * @response 500 内部服务器错误
 */
@Action("users/{id}")
public JsonResponse getUser(Integer id) {
    // 实现
}
```

## 下一步

- 探索 [API 参考](api/README.md)
- 查看[高级特性](advanced-features.md)
