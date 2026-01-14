# Dokku Instance Commands

This guide covers how to run commands on the SceneXtras Dokku instance.

## Connection Details

| Property | Value |
|----------|-------|
| **Host** | `dokku-scenextras.eastus.cloudapp.azure.com` |
| **App Name** | `scenextras` |
| **SSH Key** | `~/.ssh/dokku_azure` |
| **Dokku Version** | 0.35.15 |

## Running Commands

### Basic Command Format

```bash
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku <command>"
```

### Interactive Session

Use the provided script for an interactive SSH session:

```bash
./sceneXtras/api/bash_scripts/connect_instance.sh
```

### Run Commands Inside App Container

```bash
# One-off command (spins up new container, runs command, destroys container)
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku run scenextras <command>"

# Enter running container (for debugging live issues)
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku enter scenextras web"
```

## Common Commands

### App Management

```bash
# Check app status
dokku ps:report scenextras

# Restart app
dokku ps:restart scenextras

# Rebuild app
dokku ps:rebuild scenextras

# Stop app
dokku ps:stop scenextras
```

### Logs

```bash
# Tail application logs
dokku logs scenextras -t

# Nginx access logs
dokku nginx:access-logs scenextras

# Nginx error logs
dokku nginx:error-logs scenextras -t
```

### Configuration

```bash
# Show all environment variables
dokku config:show scenextras

# Set environment variable
dokku config:set scenextras KEY=VALUE

# Get specific config value
dokku config:get scenextras KEY
```

### Domain & SSL

```bash
# Check domain configuration
dokku domains:report scenextras

# Add domain
dokku domains:add scenextras backend.scenextras.com

# Enable Let's Encrypt SSL
dokku letsencrypt:enable scenextras

# Check SSL certificate status
dokku certs:report scenextras
```

### Nginx Configuration

```bash
# Set proxy timeouts
dokku nginx:set scenextras proxy-read-timeout 300s
dokku nginx:set scenextras proxy-send-timeout 300s
dokku nginx:set scenextras proxy-connect-timeout 60s

# Rebuild nginx config
dokku proxy:build-config scenextras

# Restart nginx
dokku nginx:restart
```

### Database (PostgreSQL)

```bash
# List postgres services
dokku postgres:list

# Show postgres service info
dokku postgres:info postgres_prod

# Link postgres to app
dokku postgres:link postgres_prod scenextras

# Unlink postgres from app
dokku postgres:unlink postgres_prod scenextras
```

### Redis

```bash
# Show redis service info
dokku redis:info redis_prod

# Link redis to app
dokku redis:link redis_prod scenextras

# Unlink redis from app
dokku redis:unlink redis_prod scenextras
```

### Docker Options

```bash
# Show docker options
dokku docker-options:report scenextras

# Clear all docker options
dokku docker-options:clear scenextras

# Add docker option
dokku docker-options:add scenextras deploy "option"
```

### Worker Configuration

```bash
# Set number of workers
dokku config:set scenextras WEB_CONCURRENCY=4

# Set max requests per worker
dokku config:set scenextras MAX_REQUESTS=1000

# Set worker timeout
dokku config:set scenextras TIMEOUT=120
```

## Shortcuts

For convenience, you can create a shell alias:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias dokku-sx='ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com'

# Usage
dokku-sx "dokku logs scenextras -t"
dokku-sx "dokku ps:report scenextras"
```

## Troubleshooting

### SSH Connection Issues

1. Verify SSH key exists and has correct permissions:
   ```bash
   ls -la ~/.ssh/dokku_azure
   chmod 600 ~/.ssh/dokku_azure
   ```

2. Test SSH connection:
   ```bash
   ssh -i ~/.ssh/dokku_azure -o ConnectTimeout=10 dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku version"
   ```

### App Not Starting

1. Check logs for errors:
   ```bash
   dokku logs scenextras -t
   ```

2. Verify environment variables:
   ```bash
   dokku config:show scenextras
   ```

3. Check process status:
   ```bash
   dokku ps:report scenextras
   ```

## Related Documentation

- [Deployment Guide](./DEPLOYMENT.md)
- [Dokku Commands Reference](../../sceneXtras/dokku_commands.sh)
