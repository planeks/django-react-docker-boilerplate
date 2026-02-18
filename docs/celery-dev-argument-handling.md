# Celery-dev Argument Handling

This document explains how the `celery-dev` command in the Django entrypoint handles arguments when using `watchfiles` for auto-reloading.

## Overview

The entrypoint script uses `watchfiles` (which replaced `watchgod`) to automatically restart Celery processes when code changes are detected. The `--args` parameter of `watchfiles` expects a single quoted string containing all arguments separated by spaces.

## Implementation

```bash
celery-dev)
    wait_for_postgres
    if [ "$2" = "worker" ]; then
        exec gosu appuser poetry run watchfiles celery.__main__.main --args "-A config worker ${*:3}"
    elif [ "$2" = "beat" ]; then
        exec gosu appuser poetry run watchfiles celery.__main__.main --args "-A config beat ${*:3}"
    else
        exec gosu appuser poetry run watchfiles celery.__main__.main --args "-A config ${*:2}"
    fi
;;
```

### Key Points

1. **watchfiles --args syntax**: The `--args` parameter takes a single quoted string
2. **Parameter expansion**: `${*:3}` expands all arguments from position 3 onwards into a single space-separated string
3. **Argument splitting**: `watchfiles` splits the args string on spaces and sets them on `sys.argv` before calling the target function

## Examples

### Example 1: Basic worker with log level
```bash
docker-compose run django celery-dev worker -l INFO
```

**Expands to:**
```bash
watchfiles celery.__main__.main --args "-A config worker -l INFO"
```

**Results in sys.argv:**
```python
['-A', 'config', 'worker', '-l', 'INFO']
```

### Example 2: Worker with pool option
```bash
docker-compose run django celery-dev worker -l DEBUG -P solo
```

**Expands to:**
```bash
watchfiles celery.__main__.main --args "-A config worker -l DEBUG -P solo"
```

**Results in sys.argv:**
```python
['-A', 'config', 'worker', '-l', 'DEBUG', '-P', 'solo']
```

### Example 3: Beat scheduler
```bash
docker-compose run django celery-dev beat -l INFO
```

**Expands to:**
```bash
watchfiles celery.__main__.main --args "-A config beat -l INFO"
```

**Results in sys.argv:**
```python
['-A', 'config', 'beat', '-l', 'INFO']
```

### Example 4: Custom Celery command
```bash
docker-compose run django celery-dev inspect active
```

**Expands to:**
```bash
watchfiles celery.__main__.main --args "-A config inspect active"
```

**Results in sys.argv:**
```python
['-A', 'config', 'inspect', 'active']
```

### Example 5: Worker with complex options
```bash
docker-compose run django celery-dev worker --loglevel=info --concurrency=4 --autoscale=10,3
```

**Expands to:**
```bash
watchfiles celery.__main__.main --args "-A config worker --loglevel=info --concurrency=4 --autoscale=10,3"
```

**Results in sys.argv:**
```python
['-A', 'config', 'worker', '--loglevel=info', '--concurrency=4', '--autoscale=10,3']
```

## Migration from watchgod

The previous implementation used `watchgod` which had a different syntax:

```bash
# Old (watchgod)
watchgod celery.__main__.main --args -A config worker "${@:3}"

# New (watchfiles)
watchfiles celery.__main__.main --args "-A config worker ${*:3}"
```

**Key differences:**
- **watchgod**: Multiple separate arguments after `--args`
- **watchfiles**: Single quoted string after `--args` that gets split on spaces

Both approaches correctly pass arguments to the Celery process, but `watchfiles` requires the arguments to be in a single quoted string.

## Verification

All standard Celery worker options are correctly passed through:
- `--loglevel` / `-l`: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- `-P` / `--pool`: Pool implementation (prefork, solo, eventlet, gevent)
- `--concurrency`: Number of worker processes
- `--autoscale`: Autoscaling settings
- Any other Celery worker options

The implementation preserves argument order and properly handles both short (`-l`) and long (`--loglevel`) option formats, as well as both space-separated (`-l INFO`) and equals-separated (`--loglevel=info`) value assignments.
