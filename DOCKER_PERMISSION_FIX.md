# Docker Permission Detection & Interactive Recovery

## Overview

The `taxi-complete-install.sh` script includes automatic Docker permission detection and interactive error recovery to handle the common issue:

```
error: permission denied while trying to connect to the Docker daemon socket
```

## Problem Solved

When running `docker-compose` as the `taxi` user during installation, the Docker daemon socket is not accessible unless the user is added to the `docker` group. Previously, this would cause the installer to fail silently or with cryptic errors.

## Solution Implementation

### 1. **check_docker_permissions()** Function

Tests if the specified user can access the Docker daemon and provides interactive options if permission is denied:

```bash
check_docker_permissions "taxi"
```

**Options presented:**
- **Option 1 (Recommended):** Auto-fix by adding user to docker group
- **Option 2:** Skip Docker permission fix and continue
- **Option 3:** Exit and debug

### 2. **run_docker_compose()** Wrapper Function

Wraps all `docker-compose` calls with automatic permission checking and error handling:

```bash
run_docker_compose "taxi" "/home/taxi/app" "--env-file .env up -d"
```

**Features:**
- Automatically calls `check_docker_permissions()` before execution
- Retries if permission error is detected (exit codes 126, 127)
- Clear error messages with log file locations
- Proper error propagation for parent scripts

## Changes Made

### taxi-complete-install.sh (8 docker-compose related sections)
- Line 340: Main installer docker-compose startup
- Line 472: Alternative installer path
- Line 4683: Service start with error handling
- Line 4847: Rollback recovery
- Line 5546: Standalone docker service startup
- Line 5757: Quick installer variant
- Plus integrated check_docker_permissions() throughout

## Usage Examples

### Running the Enhanced Installer

When the installer reaches a Docker permission issue, it will:

1. **Detect the problem:**
   ```
   [WARN] Docker permission issue detected for user: taxi
   ```

2. **Present interactive menu:**
   ```
   Options:
     1) Auto-fix: Add taxi to docker group (RECOMMENDED)
     2) Skip: Continue without fixing (may fail later)
     3) Exit: Stop installation
   
   Choose option (1/2/3):
   ```

3. **Auto-fix (Option 1):**
   - Adds the `taxi` user to the `docker` group
   - Retries the docker-compose command
   - Displays confirmation message

4. **Continue with installation** after permission is fixed

### Manual One-Liner Fix (if needed)

```bash
sudo usermod -aG docker taxi && newgrp docker && \
cd /home/taxi/app && \
sudo -u taxi docker-compose --env-file .env up -d
```

## Technical Details

### What Happens When Docker Permission Issue Occurs:

1. `run_docker_compose()` attempts to execute `docker-compose` as the `taxi` user
2. Command fails with permission error (exit code 126/127)
3. `check_docker_permissions()` is called to verify the issue
4. User sees interactive menu with options
5. If Option 1 selected: `sudo usermod -aG docker taxi` is executed
6. Retry logic automatically reruns the docker-compose command
7. Installation continues normally

### Docker Group Membership

After selecting Option 1 (auto-fix):
- User `taxi` is added to group `docker`
- Message: *"Changes will take effect after logout/login."*
- The script retries immediately to verify access
- If still not accessible, user is prompted to continue or exit

### Error Handling

- **Exit Code 126:** Permission denied
- **Exit Code 127:** Command not found
- Both trigger the permission check dialog
- All failures logged to `/var/log/install-taxi.log`

## Backward Compatibility

- All changes are **non-breaking**
- Existing environment variables and configuration unchanged
- Functions have sensible defaults:
  - Docker user defaults to `taxi`
  - Working directory defaults to current directory (`.`)
- Error handling is enhanced but behavior is same on success

## Testing

All scripts pass bash syntax validation:

```bash
$ bash -n taxi-complete-install.sh
# (no output = success)
```

## Files Modified

- `/workspaces/Proyecto/taxi-complete-install.sh` - Main production installer with Docker permission helpers

## GitHub Commit

```
Commit: 9e1bb64
Message: Add Docker permission detection and interactive recovery to installers
```

## Next Steps

1. **Re-run installer on Ubuntu server:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)
   ```

2. **When prompted about Docker permissions:**
   - Select Option 1 to auto-fix
   - Or manually add user: `sudo usermod -aG docker taxi`

3. **Docker stack should start successfully:**
   - PostgreSQL 15 container
   - Redis 7 container
   - API container (Node.js)
   - Admin panel (Nginx)

## Support

If issues persist after running the enhanced installer:

1. Check if `taxi` user is in docker group: `id taxi`
2. Verify Docker is running: `sudo systemctl status docker`
3. Manual fix: `sudo usermod -aG docker taxi && newgrp docker`
4. View logs: `tail -f /var/log/install-taxi.log`

---

**Last Updated:** 2024 - Enhanced with interactive Docker permission detection
