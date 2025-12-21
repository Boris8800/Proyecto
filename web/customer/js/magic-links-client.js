/**
 * Magic Links Authentication Client
 * Lightweight client-side library for magic links integration
 */

class MagicLinksAuth {
    constructor(options = {}) {
        this.apiUrl = options.apiUrl || 'http://localhost:3333/api/magic-links';
        this.sessionTokenKey = options.sessionTokenKey || 'session_token';
        this.redirectPath = options.redirectPath || '/dashboard/';
        this.loginPath = options.loginPath || '/auth/';
    }

    /**
     * Check if user is authenticated
     */
    async isAuthenticated() {
        try {
            const response = await fetch(`${this.apiUrl}/verify-session`, {
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            return response.ok;
        } catch (error) {
            console.error('Auth check failed:', error);
            return false;
        }
    }

    /**
     * Get current user info
     */
    async getCurrentUser() {
        try {
            const response = await fetch(`${this.apiUrl}/verify-session`, {
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                return await response.json();
            }
            return null;
        } catch (error) {
            console.error('Failed to get user:', error);
            return null;
        }
    }

    /**
     * Logout user
     */
    async logout() {
        try {
            await fetch(`${this.apiUrl}/logout`, {
                method: 'POST',
                credentials: 'include'
            });

            localStorage.removeItem(this.sessionTokenKey);
            window.location.href = this.loginPath;
        } catch (error) {
            console.error('Logout failed:', error);
        }
    }

    /**
     * Redirect to login if not authenticated
     */
    async requireAuth() {
        const isAuth = await this.isAuthenticated();
        if (!isAuth) {
            window.location.href = this.loginPath;
            return false;
        }
        return true;
    }

    /**
     * Initialize auth on page load
     */
    async init() {
        const isAuth = await this.isAuthenticated();
        
        if (!isAuth && !window.location.pathname.includes('/auth')) {
            window.location.href = this.loginPath;
        }

        return isAuth;
    }

    /**
     * Display user info in DOM element
     */
    async displayUserInfo(elementId) {
        const user = await this.getCurrentUser();
        
        if (user && user.email) {
            const element = document.getElementById(elementId);
            if (element) {
                element.innerHTML = `
                    <span class="user-email">${user.email}</span>
                    <span class="user-role">${user.role}</span>
                `;
            }
        }
    }

    /**
     * Setup logout button
     */
    setupLogoutButton(buttonId) {
        const button = document.getElementById(buttonId);
        if (button) {
            button.addEventListener('click', () => this.logout());
        }
    }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MagicLinksAuth;
}
