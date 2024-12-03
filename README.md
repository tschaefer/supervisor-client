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

Or install from source:

```bash
git clone https://github.com/tschaefer/supervisor-client
cd supervisor-client
rake install
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
Supervisore.stack_last_log_entry(stack_uuid)    # Retrieves the last log entry for a stack
Supervisor.stack_logs(stack_uuid) { block }     # Retrieves logs for a stack (Server-sent events)
Supervisor.health_check                         # Checks the health of the service
```

## CLI Usage

The `supervisor` CLI provides easy command-line access to Supervisor API
actions.

### Configuration

Before using the CLI, configure the Supervisor base URI and API token by
creating a configuration file at `~/.supervisor`:

```yaml
---
api:
    uri: https://supervisor.example.com
    token: 8db7fde4-6a11-462e-ba27-6897b7c9281b
```

### Command Reference

```bash
supervisor <command> [options]
```

### Health Check

```bash
supervisor is-healthy
```

Checks the health of the Supervisor service.

### Deployment Management

The command `deploy` installs and sets up a containerized Supervisor service
on a vanilla Linux machine by provisioning the docker service and
deploying the application proxy [Traefik](https://traefik.io/).

#### Default Traefik docker command

```bash
docker run \
    --detach --restart always --name traefik \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /var/lib/traefik:/etc/traefik \
    --network supervisor \
    --publish 80:80 --publish 443:443 \
    traefik:v3.2.1 \
    --providers.docker.exposedbydefault="false" \
    --entrypoints.web.address=":80" \
    --entrypoints.websecure.address=":443" \
    --certificatesresolvers.letsencrypt.acme.email="acme@supervisor.example" \
    --certificatesresolvers.letsencrypt.acme.storage="/etc/traefik/certs.d/acme.json" \
    --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint="web"
```

#### Default Supervisor docker command

```bash
docker run \
    --detach --restart always --name supervisor \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /var/lib/supervisor:/rails/storage \
    --network supervisor \
    --label traefik.enable="true" \
    --label traefik.http.routers.supervisor.tls="true" \
    --label traefik.http.routers.supervisor.tls.certresolver="letsencrypt" \
    --label traefik.http.routers.supervisor.rule="Host(\"supervisor.example.com\")" \
    --label traefik.http.routers.supervisor.entrypoints="websecure" \
    --env SECRET_KEY_BASE="601f72235d8ea11db69e678f9...1a" \
    --env SUPERVISOR_API_KEY="8db7fde4-6a11-462e-ba27-6897b7c9281b" \
    ghcr.io/tschaefer/supervisor:main
```

Prerequisites are super-user privileges, a valid DNS record for the
Supervisor service and the above mentioned configuration file.

While setup the necessary certificate is requested from
[Let's Encrypt](https://letsencrypt.org/) via HTTP-challenge.


```bash
supervisor deploy --host root@machine.example.com
```

The provisioning of docker can be skipped wit the option `--skip-docker` as
well as the installation of Traefik with the option `--skip-traefik`. For a
more informative output use `--verbose` - beware, sensible information will be
exposed.

The deployment is customizable by configuration in the root under `deploy`.

```yaml
deploy:
    # Traefik settings
    #
    traefik:
        # Arguments
        #
        # Additional arguments to pass to the Traefik container
        args:
            configfile: /etc/traefik/traefik.yml
        # Environment variables
        #
        # Additional environment variables to pass to the Traefik container
        env:
            CF_API_EMAIL: cloudflare@example.com
            CF_DNS_API_TOKEN: YSsfAH-d1q57j2D7T41ptAfM
    # Supervisor settings
    #
    supervisor:
        # Labels
        #
        # Additional labels to apply to the Supervisor container
        labels:
            traefik.http.routers.supervisor.tls.certresolver: cloudflare
        # Environment variables
        #
        # Additional environment variables to pass to the Supervisor container
        env: {}
```

Custom `hooks` scripts can be run before and after certain deployment steps.

* post-docker-setup
* pre-traefik-deploy
* post-traefik-deploy
* pre-supervisor-deploy
* post-supervisor-deploy

**Example**:

```bash
#!/usr/bin/env sh

# pre-traefik-deploy hook script

cat <<EOF> /var/lib/traefik/traefik.yml
---
certificatesresolvers:
  cloudflare:
    acme:
      email: acme@example.com
      storage: /etc/traefik/certs.d/cloudflare.json
      dnschallenge:
        provider: cloudflare
EOF
```

The hook filename must be the hook name without any extension. The path to the
hooks directory can be configured in the root under `hooks`.

```yaml
hooks: /path/to/hooks
```

The Supervisor service can be redeployed with the command `redeploy`.

```bash
supervisor redeploy --host machine.example.com
```

Optionally, Traefik can be redeployed with the option `--with-traefik`.

### Stack Management

The `stacks` commands provide a variety of operations for managing stacks.

#### Available Stack Commands

| Subcommand  | Description                                           |
|-------------|-------------------------------------------------------|
| `create`    | Creates a new stack using a YAML manifest file.       |
| `update`    | Updates an existing stack with a new manifest file.   |
| `control`   | Controls (start, stop) a stack.                       |
| `delete`    | Deletes a specified stack.                            |
| `show`      | Shows details of a specified stack.                   |
| `stats`     | Retrieves statistics for a stack.                     |
| `list`      | Lists all stacks in Supervisor.                       |
| `control`   | Controls (start, stop, rest) a stack.                 |
| `log`       | Retrieves log for a stack.                            |

#### Command Options

- **`create` and `update`**: Both require the `--manifest-file FILE` option to
  specify a YAML manifest file describing the stack. The optional `--decrypt`
  option uses [`sops`](https://github.com/getsops/sops) to decrypt inline
  attributes in the YAML file.
  - **Example**:
    ```bash
    supervisor create --manifest-file stack.yaml --decrypt
    ```

- **`update`**: In addition to `--manifest-file FILE`, `update` requires the
  parameter `STACK-UUID` for the stack to update.
  - **Example**:
    ```bash
    supervisor update --manifest-file stack.yaml STACK-UUID
    ```

- **`show`, `stats`, `delete`**: Each of these subcommands requires
  the parameter `STACK-UUID` for the stack to operate on.
  - **Example**:
    ```bash
    supervisor show STACK-UUID
    supervisor stats STACK-UUID
    supervisor delete STACK-UUID
    ```

- **`show`**: By default, sensitive data in the output is filtered. Use the
  `--unfiltered` option to disable filtering.
  - **Example**:
    ```bash
    supervisor show STACK-UUID --unfiltered
    ```

- **`show`, `stats`, `list`**: These subcommands output information in a table
  format by default. Use the `--json` option to output data in JSON format.
  - **Example**:
    ```bash
    supervisor list --json
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
