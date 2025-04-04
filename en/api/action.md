# Action API Reference

## @Action Annotation

The `@Action` annotation is used to define routes and commands in tinystruct applications.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| value | String | The URL pattern or command name |
| description | String | Description of the action (optional) |
| options | Argument[] | Command line arguments (optional) |
| mode | Action.Mode | Execution mode (All, CLI, or Web) |

### Example

```java
@Action(
    value = "users",
    description = "Get user by ID",
    mode = Action.Mode.Web
)
public User getUser(Integer id) {
    return userService.findById(id);
}
```

Note that Tinystruct automatically routes requests like `/users/123` to the appropriate method based on the parameters. There's no need to define path variables like `{id}` in the @Action annotation.

## Action Class

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| getPathRule() | String | Get the URL pattern |
| getPattern() | Pattern | Get the compiled regex pattern |
| getMode() | Action.Mode | Get the action mode |
| getPriority() | int | Get the action priority |
| execute() | Object | Execute the action |