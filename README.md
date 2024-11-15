# Supervisor Client

The Supervisor Client is a Ruby library and CLI tool that provides easy access
to the [Supervisor - The Docker GitOps service](https://github.com/tschaefer/supervisor),
enabling you to manage stacks with GitOps strategies. This library wraps the
Supervisor API and allows to create, update, control, and query stacks directly
from Ruby applications or the command line.

## Installation

To install the Supervisor Client, add this line to your application's Gemfile:

```ruby
gem 'supervisor'
```

Then, execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install supervisor
```

## Configuration

Before using the library, configure the `base_url` and `api_key`:

```ruby
require 'supervisor'

Supervisor.configure do |config|
  config.base_url = 'https://supervisor.example.com'
  config.api_key = '8db7fde4-6a11-462e-ba27-6897b7c9281b'
end
```

After configuration, you can call any of the provided API methods directly.

## Usage

Once configured, interact with the Supervisor API using the following methods:

```ruby
Supervisor.create_stack(params)                 # Creates a new stack
Supervisor.list_stacks                          # Lists all stacks
Supervisor.show_stack(stack_uuid)               # Shows details of a specific stack
Supervisor.stack_stats(stack_uuid)              # Retrieves statistics for a stack
Supervisor.update_stack(stack_uuid, params)     # Updates an existing stack
Supervisor.delete_stack(stack_uuid)             # Deletes a specified stack
Supervisor.control_stack(stack_uuid, command)   # Controls (start, stop) a stack
Supervisor.health_check                         # Checks the health of the service
```

## CLI Usage

The `supervisor` CLI provides easy command-line access to Supervisor API
actions. The CLI has two main subcommands: `health` and `stacks`.

### Configuration

Before using the CLI, configure the Supervisor base URL and API key by
creating a configuration file at `~/.supervisor`:

```yaml
---
base_url: https://supervisor.example.com
api_key: 8db7fde4-6a11-462e-ba27-6897b7c9281b
```

### Command Reference

```bash
supervisor <command> [options]
```

### Health Check

```bash
supervisor health
```

Checks the health of the Supervisor service.

### Stack Management

The `stacks` subcommand provides a variety of operations for managing stacks.

```bash
supervisor stacks <subcommand> [options]
```

#### Available Stack Subcommands

| Subcommand  | Description                                           |
|-------------|-------------------------------------------------------|
| `create`    | Creates a new stack using a YAML manifest file.       |
| `update`    | Updates an existing stack with a new manifest file.   |
| `control`   | Controls (start, stop) a stack.                       |
| `delete`    | Deletes a specified stack.                            |
| `show`      | Shows details of a specified stack.                   |
| `stats`     | Retrieves statistics for a stack.                     |
| `list`      | Lists all stacks in Supervisor.                       |

#### Subcommand Options

- **`create` and `update`**: Both require the `--manifest-file FILE` option to
  specify a YAML manifest file describing the stack. The optional `--decrypt`
  option uses [`sops`](https://github.com/getsops/sops) to decrypt inline
  attributes in the YAML file.
  - **Example**:
    ```bash
    supervisor stacks create --manifest-file stack.yaml --decrypt
    supervisor stacks update --manifest-file stack.yaml --decrypt STACK-UUID
    ```

- **`update`**: In addition to `--manifest-file FILE`, `update` requires the
  parameter `STACK-UUID` for the stack to update.

- **`show`, `stats`, `delete`**: Each of these subcommands requires
  the parameter `STACK-UUID` for the stack to operate on.
  - **Example**:
    ```bash
    supervisor stacks show STACK-UUID
    supervisor stacks stats STACK-UUID
    supervisor stacks delete STACK-UUID
    ```

- **`show`**: By default, sensitive data in the output is filtered. Use the
  `--unfiltered` option to disable filtering.
  - **Example**:
    ```bash
    supervisor stacks show STACK-UUID --unfiltered
    ```

- **`show`, `stats`, `list`**: These subcommands output information in a table
  format by default. Use the `--json` option to output data in JSON format.
  - **Example**:
    ```bash
    supervisor stacks list --json
    ```

### Bash Completion
The repository includes a bash completion script for the `supervisor` CLI. For
usage copy the `etc/bash/completion` file to your bash completion directory.

```bash
cp etc/bash/completion /etc/bash_completion.d/supervisor
```

## Manifest File

The manifest file, specified by `--manifest-file FILE`, is a YAML file that
defines a stack’s configuration. Here’s an example:

```yaml
name: whoami
git_repository: https://github.com/tschaefer/infrastructure
git_username: tschaefer
git_token: github_pat_...FFF
git_reference: refs/heads/main
compose_file: lib/stack/whoami/docker-compose.yml
compose_includes:
  - lib/stack/whoami/includes/traefik.yml
  - lib/stack/whoami/includes/network.yml
compose_variables:
  NETWORK_IPV4_WHOAMI: 172.18.100.111
  NETWORK_ID: core
strategy: polling
polling_interval: 300
signature_header: nil
signature_secret: nil
```

- **`name`**: Unique name for the stack.
- **`git_repository`**: URL to the git repository with the stack's `docker-compose.yml` file.
- **`git_username`** and **`git_token`**: (Optional) Authentication details for the repository.
- **`compose_file`**: Path to the primary `docker-compose.yml` file in the repository.
- **`compose_includes`**: List of additional Compose files to be included.
- **`compose_variables`**: Variables to be passed to the Compose file.
- **`strategy`**: GitOps strategy (`polling` or `webhook`).
- **`polling_interval`**: (For `polling` strategy) Interval, in seconds, for polling the repository.
- **`signature_header`** and **`signature_secret`**: (For `webhook` strategy) Signature details.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE)
file for details.
