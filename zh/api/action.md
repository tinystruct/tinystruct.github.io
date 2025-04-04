# Action API 参考

## @Action 注解

`@Action` 注解用于定义 Tinystruct 应用程序中的路由和命令。

### 参数

| 参数 | 类型 | 描述 |
|-----------|------|-------------|
| value | String | URL模式或命令名称 |
| description | String | 动作描述（可选） |
| options | Argument[] | 命令行参数（可选） |
| mode | Action.Mode | 执行模式（All、CLI或Web） |

### 示例

```java
@Action(
    value = "users/{id}", 
    description = "根据ID获取用户",
    mode = Action.Mode.Web
)
public User getUser(Integer id) {
    return userService.findById(id);
}
```

## Action 类

### 方法

| 方法 | 返回类型 | 描述 |
|--------|-------------|-------------|
| getPathRule() | String | 获取URL模式 |
| getPattern() | Pattern | 获取编译后的正则表达式模式 |
| getMode() | Action.Mode | 获取动作模式 |
| getPriority() | int | 获取动作优先级 |
| execute() | Object | 执行动作 |