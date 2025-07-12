# Example: Container App Job with Secrets

This example demonstrates how to create a Container App Job with secrets configured. It shows how to:

1. Define secrets for the container app job
2. Reference secrets in environment variables
3. Mix secret references with plain environment variables

## Features Demonstrated

- **Secret Definition**: How to define secrets using the `secrets` variable
- **Environment Variable Mapping**: How to reference secrets in container environment variables using `secret_name`
- **Mixed Variables**: How to use both secret references and plain values in environment variables

## Usage

This example creates:
- A container app environment
- A container app job with two secrets (`my-secret` and `database-password`)
- Environment variables that reference the secrets
- A container that outputs "Hello, World!"

## Secret Configuration

Secrets are defined using the `secrets` variable:

```hcl
secrets = [
  {
    name  = "my-secret"
    value = "secret-value"
  },
  {
    name  = "database-password"
    value = "supersecretpassword"
  }
]
```

These secrets can then be referenced in environment variables:

```hcl
env = [
  {
    name        = "SECRET_VALUE"
    secret_name = "my-secret"
  },
  {
    name        = "DB_PASSWORD"
    secret_name = "database-password"
  }
]
```

## Important Notes

- When using Azure Key Vault secrets, you must also specify the `identity` and `key_vault_secret_id` properties
- Secret values should be handled carefully and not exposed in logs or output
- Consider using Azure Key Vault for production workloads instead of plain text values