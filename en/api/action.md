# Action API Reference

## @Action Annotation

The `@Action` annotation is used to define routes and commands in Tinystruct applications.

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
    value = "users/{id}", 
    description = "Get user by ID",
    mode = Action.Mode.Web
)
public User getUser(Integer id) {
    return userService.findById(id);
}
```

## Action Class

### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| getPathRule() | String | Get the URL pattern |
| getPattern() | Pattern | Get the compiled regex pattern |
| getMode() | Action.Mode | Get the action mode |
| getPriority() | int | Get the action priority |
| execute() | Object | Execute the action |