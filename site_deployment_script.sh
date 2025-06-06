#!/bin/bash

# Complete Self-Hosted Site Deployment Script
# Creates a full HTML site with Hello World and Home page
# No external dependencies - all self-contained

set -e  # Exit on any error

# Configuration
SITE_NAME="AdDevSelfHostedSite"
DOMAIN="www.addevselfhostedsited.com"
SITE_DIR="/var/www/addevselfhostedsited"
NGINX_CONF="/etc/nginx/sites-available/addevselfhostedsited"
NGINX_ENABLED="/etc/nginx/sites-enabled/addevselfhostedsited"
LOG_FILE="/var/log/site_deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Detect OS and package manager
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
            PKG_MANAGER="apt"
        elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "fedora" ]]; then
            PKG_MANAGER="yum"
        else
            warning "Unknown OS, attempting with apt..."
            PKG_MANAGER="apt"
        fi
    else
        warning "Cannot detect OS, attempting with apt..."
        PKG_MANAGER="apt"
    fi
    log "Detected OS: $OS, Package Manager: $PKG_MANAGER"
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        apt update
        apt install -y nginx ufw curl wget
    elif [[ "$PKG_MANAGER" == "yum" ]]; then
        yum update -y
        yum install -y nginx firewalld curl wget
    fi
    
    success "Packages installed successfully"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    mkdir -p "$SITE_DIR"
    mkdir -p "$SITE_DIR/css"
    mkdir -p "$SITE_DIR/js"
    mkdir -p "$SITE_DIR/images"
    mkdir -p "$SITE_DIR/assets"
    
    success "Directory structure created"
}

# Generate CSS file
generate_css() {
    log "Generating CSS files..."
    
    cat > "$SITE_DIR/css/style.css" << 'EOF'
/* AdDevSelfHostedSite - Main Stylesheet */

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Header */
header {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    padding: 1rem 0;
    position: fixed;
    width: 100%;
    top: 0;
    z-index: 1000;
    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: white;
    text-decoration: none;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    color: white;
    text-decoration: none;
    transition: color 0.3s ease;
}

.nav-links a:hover {
    color: #ffd700;
}

/* Main Content */
main {
    margin-top: 80px;
    padding: 2rem 0;
}

.hero {
    text-align: center;
    padding: 4rem 0;
    color: white;
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
}

.hero p {
    font-size: 1.2rem;
    margin-bottom: 2rem;
    opacity: 0.9;
}

.btn {
    display: inline-block;
    padding: 12px 30px;
    background: rgba(255, 255, 255, 0.2);
    color: white;
    text-decoration: none;
    border-radius: 25px;
    transition: all 0.3s ease;
    border: 2px solid rgba(255, 255, 255, 0.3);
}

.btn:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
}

/* Content Sections */
.section {
    padding: 3rem 0;
    background: rgba(255, 255, 255, 0.1);
    margin: 2rem 0;
    border-radius: 15px;
    backdrop-filter: blur(10px);
}

.section h2 {
    text-align: center;
    color: white;
    margin-bottom: 2rem;
    font-size: 2rem;
}

.features {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    margin-top: 2rem;
}

.feature {
    background: rgba(255, 255, 255, 0.1);
    padding: 2rem;
    border-radius: 10px;
    text-align: center;
    color: white;
    transition: transform 0.3s ease;
}

.feature:hover {
    transform: translateY(-5px);
}

.feature h3 {
    margin-bottom: 1rem;
    color: #ffd700;
}

/* Footer */
footer {
    background: rgba(0, 0, 0, 0.3);
    color: white;
    text-align: center;
    padding: 2rem 0;
    margin-top: 3rem;
}

/* Responsive Design */
@media (max-width: 768px) {
    .hero h1 {
        font-size: 2rem;
    }
    
    .nav-links {
        gap: 1rem;
    }
    
    .features {
        grid-template-columns: 1fr;
    }
}

/* Animation Classes */
.fade-in {
    animation: fadeIn 1s ease-in;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
}
EOF

    success "CSS files generated"
}

# Generate JavaScript file
generate_javascript() {
    log "Generating JavaScript files..."
    
    cat > "$SITE_DIR/js/main.js" << 'EOF'
// AdDevSelfHostedSite - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Add fade-in animation to elements
    const elements = document.querySelectorAll('.hero, .section, .feature');
    elements.forEach(el => {
        el.classList.add('fade-in');
    });

    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('a[href^="#"]');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });

    // Add dynamic time display
    updateTime();
    setInterval(updateTime, 1000);

    // Console welcome message
    console.log('🚀 Welcome to AdDevSelfHostedSite!');
    console.log('📅 Site deployed on:', new Date().toISOString());
    console.log('💻 Fully self-contained deployment');
});

function updateTime() {
    const timeElement = document.getElementById('current-time');
    if (timeElement) {
        const now = new Date();
        timeElement.textContent = now.toLocaleString();
    }
}

// Hello World function
function sayHello() {
    alert('Hello World from AdDevSelfHostedSite! 🌍');
}

// Interactive feature
function toggleInfo() {
    const infoDiv = document.getElementById('extra-info');
    if (infoDiv) {
        infoDiv.style.display = infoDiv.style.display === 'none' ? 'block' : 'none';
    }
}
EOF

    success "JavaScript files generated"
}

# Generate Hello World page
generate_hello_page() {
    log "Generating Hello World page..."
    
    cat > "$SITE_DIR/hello.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World - AdDevSelfHostedSite</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav class="container">
            <a href="/" class="logo">AdDevSelfHostedSite</a>
            <ul class="nav-links">
                <li><a href="/home">Home</a></li>
                <li><a href="/hello.html">Hello World</a></li>
            </ul>
        </nav>
    </header>

    <main class="container">
        <div class="hero">
            <h1>🌍 Hello World!</h1>
            <p>Welcome to your self-hosted website deployment</p>
            <button onclick="sayHello()" class="btn">Say Hello!</button>
        </div>

        <div class="section">
            <h2>Deployment Information</h2>
            <div class="features">
                <div class="feature">
                    <h3>🚀 Status</h3>
                    <p>Site successfully deployed and running!</p>
                </div>
                <div class="feature">
                    <h3>⏰ Current Time</h3>
                    <p id="current-time">Loading...</p>
                </div>
                <div class="feature">
                    <h3>🎯 Domain</h3>
                    <p>www.addevselfhostedsited.com</p>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>Technical Details</h2>
            <div style="color: white; text-align: center;">
                <p>✅ Self-contained deployment script</p>
                <p>✅ No external dependencies</p>
                <p>✅ Complete HTML/CSS/JS stack</p>
                <p>✅ Nginx web server configured</p>
                <p>✅ Responsive design</p>
            </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2025 AdDevSelfHostedSite - Deployed with ❤️</p>
        </div>
    </footer>

    <script src="/js/main.js"></script>
</body>
</html>
EOF

    success "Hello World page generated"
}

# Generate Home page
generate_home_page() {
    log "Generating Home page..."
    
    cat > "$SITE_DIR/home.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home - AdDevSelfHostedSite</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav class="container">
            <a href="/" class="logo">AdDevSelfHostedSite</a>
            <ul class="nav-links">
                <li><a href="/home">Home</a></li>
                <li><a href="/hello.html">Hello World</a></li>
            </ul>
        </nav>
    </header>

    <main class="container">
        <div class="hero">
            <h1>🏠 Welcome Home</h1>
            <p>Your complete self-hosted website solution</p>
            <a href="/hello.html" class="btn">Try Hello World</a>
        </div>

        <div class="section">
            <h2>Features</h2>
            <div class="features">
                <div class="feature">
                    <h3>🔧 Self-Contained</h3>
                    <p>Complete deployment in a single script with no external dependencies</p>
                </div>
                <div class="feature">
                    <h3>⚡ Fast Setup</h3>
                    <p>Automated installation and configuration of web server and site files</p>
                </div>
                <div class="feature">
                    <h3>📱 Responsive</h3>
                    <p>Mobile-friendly design that works on all devices</p>
                </div>
                <div class="feature">
                    <h3>🎨 Modern Design</h3>
                    <p>Beautiful gradient backgrounds with glassmorphism effects</p>
                </div>
                <div class="feature">
                    <h3>🔒 Secure</h3>
                    <p>Properly configured with firewall and security best practices</p>
                </div>
                <div class="feature">
                    <h3>📊 Production Ready</h3>
                    <p>Nginx web server with optimized configuration</p>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>Quick Actions</h2>
            <div style="text-align: center; color: white;">
                <button onclick="toggleInfo()" class="btn" style="margin: 10px;">Toggle Info</button>
                <button onclick="sayHello()" class="btn" style="margin: 10px;">Say Hello</button>
                <div id="extra-info" style="display: none; margin-top: 20px; padding: 20px; background: rgba(255,255,255,0.1); border-radius: 10px;">
                    <h3>🎉 Congratulations!</h3>
                    <p>You have successfully deployed a complete website using our self-contained script.</p>
                    <p>This site includes modern web technologies and is ready for production use.</p>
                </div>
            </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2025 AdDevSelfHostedSite - Fully Self-Hosted Solution</p>
        </div>
    </footer>

    <script src="/js/main.js"></script>
</body>
</html>
EOF

    success "Home page generated"
}

# Generate index page
generate_index_page() {
    log "Generating index page..."
    
    cat > "$SITE_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AdDevSelfHostedSite - Complete Self-Hosted Solution</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav class="container">
            <a href="/" class="logo">AdDevSelfHostedSite</a>
            <ul class="nav-links">
                <li><a href="/home">Home</a></li>
                <li><a href="/hello.html">Hello World</a></li>
            </ul>
        </nav>
    </header>

    <main class="container">
        <div class="hero">
            <h1>🚀 AdDevSelfHostedSite</h1>
            <p>Complete Self-Hosted Website Deployment Solution</p>
            <div style="margin-top: 2rem;">
                <a href="/home" class="btn" style="margin: 10px;">Go to Home</a>
                <a href="/hello.html" class="btn" style="margin: 10px;">Hello World</a>
            </div>
        </div>

        <div class="section">
            <h2>Deployment Success!</h2>
            <div class="features">
                <div class="feature">
                    <h3>✅ Website Active</h3>
                    <p>Your self-hosted website is now live and running</p>
                </div>
                <div class="feature">
                    <h3>🌐 Domain Ready</h3>
                    <p>Configured for www.addevselfhostedsited.com</p>
                </div>
                <div class="feature">
                    <h3>🔧 Fully Configured</h3>
                    <p>Nginx, firewall, and all components properly set up</p>
                </div>
            </div>
        </div>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2025 AdDevSelfHostedSite - One-Script Deployment Challenge Complete!</p>
        </div>
    </footer>

    <script src="/js/main.js"></script>
</body>
</html>
EOF

    success "Index page generated"
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN localhost;
    
    root $SITE_DIR;
    index index.html home.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Main locations
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location /home {
        try_files /home.html =404;
    }
    
    # Static files with caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF

    # Create symbolic link to enable site
    ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
    
    # Remove default site if it exists
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        rm -f "/etc/nginx/sites-enabled/default"
    fi
    
    success "Nginx configured"
}

# Generate error pages
generate_error_pages() {
    log "Generating error pages..."
    
    cat > "$SITE_DIR/404.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <div class="hero">
            <h1>404</h1>
            <p>Page not found</p>
            <a href="/" class="btn">Go Home</a>
        </div>
    </div>
</body>
</html>
EOF
    
    success "Error pages generated"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow ssh
        ufw allow 'Nginx Full'
        success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        success "Firewalld configured"
    else
        warning "No firewall tool found, skipping firewall configuration"
    fi
}

# Set proper permissions
set_permissions() {
    log "Setting proper permissions..."
    
    chown -R www-data:www-data "$SITE_DIR"
    chmod -R 755 "$SITE_DIR"
    chmod 644 "$SITE_DIR"/*.html
    chmod 644 "$SITE_DIR"/css/*.css
    chmod 644 "$SITE_DIR"/js/*.js
    
    success "Permissions set"
}

# Start services
start_services() {
    log "Starting services..."
    
    # Test Nginx configuration
    nginx -t || error "Nginx configuration test failed"
    
    # Enable and start Nginx
    systemctl enable nginx
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        success "Nginx started successfully"
    else
        error "Failed to start Nginx"
    fi
}

# Generate deployment report
generate_report() {
    log "Generating deployment report..."
    
    cat > "$SITE_DIR/deployment-report.txt" << EOF
=== AdDevSelfHostedSite Deployment Report ===
Deployment Date: $(date)
Site Directory: $SITE_DIR
Domain: $DOMAIN
Status: ACTIVE

Files Created:
- index.html (Landing page)
- home.html (Home page at /home)
- hello.html (Hello World page)
- css/style.css (Main stylesheet)
- js/main.js (Interactive JavaScript)
- 404.html (Error page)

Services Configured:
- Nginx web server
- Firewall (UFW/Firewalld)

Access URLs:
- http://$DOMAIN/
- http://$DOMAIN/home
- http://$DOMAIN/hello.html

Local Access:
- http://localhost/
- http://localhost/home
- http://localhost/hello.html

Log File: $LOG_FILE

=== Deployment Complete! ===
EOF

    success "Deployment report generated at $SITE_DIR/deployment-report.txt"
}

# Main deployment function
main() {
    clear
    echo "=============================================="
    echo "🚀 AdDevSelfHostedSite Deployment Script"
    echo "=============================================="
    echo
    
    check_root
    detect_os
    install_packages
    create_directories
    generate_css
    generate_javascript
    generate_hello_page
    generate_home_page
    generate_index_page
    generate_error_pages
    configure_nginx
    configure_firewall
    set_permissions
    start_services
    generate_report
    
    echo
    echo "=============================================="
    success "🎉 DEPLOYMENT COMPLETE!"
    echo "=============================================="
    echo
    echo "Your website is now live at:"
    echo "  • http://localhost/"
    echo "  • http://localhost/home"
    echo "  • http://localhost/hello.html"
    echo
    echo "For domain access, configure DNS to point"
    echo "$DOMAIN to this server's IP address"
    echo
    echo "Deployment report: $SITE_DIR/deployment-report.txt"
    echo "Log file: $LOG_FILE"
    echo
    echo "=============================================="
}

# Run main function
main "$@"