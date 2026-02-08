# Action API 参考

## @Action 注解

`@Action` 注解用于定义 tinystruct 应用程序中的路由和命令。

### 参数

| 参数 | 类型 | 描述 |
|-----------|------|-------------|
| value | String | URL模式或命令名称 |
| description | String | 动作描述（可选） |
| options | Argument[] | 命令行参数（可选） |
| mode | Action.Mode | 执行模式（All、CLI 或 HTTP_GET 等） |

### HTTP 方法模式

- `Mode.HTTP_GET` - 仅 GET 请求
- `Mode.HTTP_POST` - 仅 POST 请求
- `Mode.HTTP_PUT` - 仅 PUT 请求
- `Mode.HTTP_DELETE` - 仅 DELETE 请求
- `Mode.HTTP_PATCH` - 仅 PATCH 请求
- `Mode.HTTP_HEAD` - 仅 HEAD 请求
- `Mode.HTTP_OPTIONS` - 仅 OPTIONS 请求


### 示例

```java
@Action(
    value = "users",
    description = "根据ID获取用户",
    mode = Action.Mode.HTTP_GET
)
public User getUser(Integer id) {
    return userService.findById(id);
}
```

请注意，Tinystruct 会根据参数自动将像 `/users/123` 这样的请求路由到适当的方法。无需在 @Action 注解中定义像 `{id}` 这样的路径变量。

## Action 类

### 方法

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| getPathRule() | String | 获取URL模式 |
| getPattern() | Pattern | 获取编译后的正则表达式模式 |
| getMode() | Action.Mode | 获取动作模式 |
| getPriority() | int | 获取动作优先级 |
| execute() | Object | 执行动作 |