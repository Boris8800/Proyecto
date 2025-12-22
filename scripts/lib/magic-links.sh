#!/bin/bash
################################################################################
# MAGIC LINKS MODULE - Passwordless Authentication System
# Handles magic link generation, validation, and expiration
################################################################################

# Configuration
MAGIC_LINKS_DB="${MAGIC_LINKS_DB:-/root/magic_links.db}"
MAGIC_LINKS_EXPIRY="${MAGIC_LINKS_EXPIRY:-3}"  # Default: 3 days (1-5 configurable)
MAGIC_LINKS_TOKEN_LENGTH=32

################################################################################
# Initialize Magic Links Database
################################################################################
init_magic_links_db() {
    log_info "Initializing Magic Links database..."
    
    # Create SQLite database for magic links
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
CREATE TABLE IF NOT EXISTS magic_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    token TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    used_at DATETIME,
    used BOOLEAN DEFAULT 0,
    ip_address TEXT,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_token ON magic_links(token);
CREATE INDEX IF NOT EXISTS idx_email ON magic_links(email);
CREATE INDEX IF NOT EXISTS idx_expires_at ON magic_links(expires_at);

CREATE TABLE IF NOT EXISTS magic_links_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    session_token TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_session_token ON magic_links_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_session_email ON magic_links_sessions(email);
EOF

    if [ -f "$MAGIC_LINKS_DB" ]; then
        log_ok "Magic Links database initialized"
        return 0
    else
        log_error "Failed to create Magic Links database"
        return 1
    fi
}

################################################################################
# Generate Magic Link Token
################################################################################
generate_magic_token() {
    local email="$1"
    local role="$2"
    local days="${3:-3}"
    
    # Validate inputs
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi
    
    # Validate role (prevent SQL injection)
    if [[ ! "$role" =~ ^(admin|driver|customer|user)$ ]]; then
        log_error "Invalid role: $role"
        return 1
    fi
    
    if ! [[ "$days" =~ ^[1-5]$ ]]; then
        log_warn "Invalid expiry days: $days (must be 1-5), using default (3)"
        days=3
    fi
    
    # Generate secure random token
    local token
    token=$(openssl rand -hex $((MAGIC_LINKS_TOKEN_LENGTH / 2)))
    
    # Calculate expiration time
    local expires_at
    expires_at=$(date -d "+$days days" '+%Y-%m-%d %H:%M:%S')
    
    # Sanitize user-provided inputs (escape single quotes for SQL)
    local safe_ip="${REMOTE_ADDR//\'/\'\'}"
    local safe_ua="${HTTP_USER_AGENT//\'/\'\'}"
    
    # Store in database using parameterized-style insertion
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
INSERT INTO magic_links (email, token, role, expires_at, ip_address, user_agent)
VALUES ('$email', '$token', '$role', '$expires_at', '$safe_ip', '$safe_ua');
EOF
    
    if [ $? -eq 0 ]; then
        echo "$token"
        log_info "Magic link generated for: $email (expires: $expires_at)"
        return 0
    else
        log_error "Failed to generate magic token for: $email"
        return 1
    fi
}

################################################################################
# Validate Magic Link Token
################################################################################
validate_magic_token() {
    local token="$1"
    
    if [ -z "$token" ]; then
        log_error "Empty token provided"
        return 1
    fi
    
    # Check token exists and is not expired
    local result
    result=$(sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
SELECT email, role FROM magic_links
WHERE token = '$token'
  AND used = 0
  AND expires_at > datetime('now');
EOF
    )
    
    if [ -z "$result" ]; then
        log_error "Invalid or expired magic link: $token"
        return 1
    fi
    
    # Mark token as used
    sqlite3 "$MAGIC_LINKS_DB" "UPDATE magic_links SET used = 1, used_at = CURRENT_TIMESTAMP WHERE token = '$token';" 2>/dev/null
    
    echo "$result"
    log_ok "Magic token validated: $token"
    return 0
}

################################################################################
# Get Magic Link Info
################################################################################
get_magic_link_info() {
    local token="$1"
    
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
SELECT 
    email,
    role,
    created_at,
    expires_at,
    used,
    used_at
FROM magic_links
WHERE token = '$token';
EOF
}

################################################################################
# Create Session from Magic Link
################################################################################
create_session_from_magic_link() {
    local email="$1"
    local role="$2"
    local session_days="${3:-7}"  # Session valid for 7 days by default
    
    # Generate session token
    local session_token
    session_token=$(openssl rand -hex $((MAGIC_LINKS_TOKEN_LENGTH / 2)))
    
    # Calculate expiration
    local expires_at
    expires_at=$(date -d "+$session_days days" '+%Y-%m-%d %H:%M:%S')
    
    # Store session
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
INSERT INTO magic_links_sessions (email, session_token, role, expires_at)
VALUES ('$email', '$session_token', '$role', '$expires_at');
EOF
    
    if [ $? -eq 0 ]; then
        echo "$session_token"
        log_ok "Session created for: $email"
        return 0
    else
        log_error "Failed to create session for: $email"
        return 1
    fi
}

################################################################################
# Validate Session Token
################################################################################
validate_session_token() {
    local session_token="$1"
    
    if [ -z "$session_token" ]; then
        return 1
    fi
    
    local result
    result=$(sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
SELECT email, role FROM magic_links_sessions
WHERE session_token = '$session_token'
  AND expires_at > datetime('now');
EOF
    )
    
    if [ -z "$result" ]; then
        return 1
    fi
    
    # Update last activity
    sqlite3 "$MAGIC_LINKS_DB" "UPDATE magic_links_sessions SET last_activity = CURRENT_TIMESTAMP WHERE session_token = '$session_token';" 2>/dev/null
    
    echo "$result"
    return 0
}

################################################################################
# Clean Up Expired Tokens
################################################################################
cleanup_expired_tokens() {
    log_info "Cleaning up expired magic links..."
    
    local deleted
    deleted=$(sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
DELETE FROM magic_links WHERE expires_at < datetime('now');
SELECT changes();
EOF
    )
    
    local sessions_deleted
    sessions_deleted=$(sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
DELETE FROM magic_links_sessions WHERE expires_at < datetime('now');
SELECT changes();
EOF
    )
    
    log_ok "Cleanup completed: $deleted expired links, $sessions_deleted expired sessions"
}

################################################################################
# Revoke Magic Link
################################################################################
revoke_magic_link() {
    local token="$1"
    
    sqlite3 "$MAGIC_LINKS_DB" "UPDATE magic_links SET used = 1 WHERE token = '$token';" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_ok "Magic link revoked: $token"
        return 0
    else
        log_error "Failed to revoke magic link: $token"
        return 1
    fi
}

################################################################################
# Revoke Session
################################################################################
revoke_session() {
    local session_token="$1"
    
    sqlite3 "$MAGIC_LINKS_DB" "DELETE FROM magic_links_sessions WHERE session_token = '$session_token';" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_ok "Session revoked: $session_token"
        return 0
    else
        log_error "Failed to revoke session: $session_token"
        return 1
    fi
}

################################################################################
# Get Active Sessions Count
################################################################################
get_active_sessions_count() {
    local email="$1"
    
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
SELECT COUNT(*) FROM magic_links_sessions
WHERE email = '$email'
  AND expires_at > datetime('now');
EOF
}

################################################################################
# Get Magic Links Statistics
################################################################################
get_magic_links_stats() {
    log_info "Magic Links Statistics:"
    
    sqlite3 "$MAGIC_LINKS_DB" << EOF 2>/dev/null
SELECT 'Total Links Generated' as stat, COUNT(*) as count FROM magic_links
UNION ALL
SELECT 'Links Used', COUNT(*) FROM magic_links WHERE used = 1
UNION ALL
SELECT 'Links Expired', COUNT(*) FROM magic_links WHERE expires_at < datetime('now')
UNION ALL
SELECT 'Active Links', COUNT(*) FROM magic_links WHERE used = 0 AND expires_at > datetime('now')
UNION ALL
SELECT 'Active Sessions', COUNT(*) FROM magic_links_sessions WHERE expires_at > datetime('now');
EOF
}

################################################################################
# Export Magic Links Module Functions
################################################################################
export -f init_magic_links_db
export -f generate_magic_token
export -f validate_magic_token
export -f get_magic_link_info
export -f create_session_from_magic_link
export -f validate_session_token
export -f cleanup_expired_tokens
export -f revoke_magic_link
export -f revoke_session
export -f get_active_sessions_count
export -f get_magic_links_stats
