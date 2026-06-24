#!/usr/bin/env bash
# English language file
# All user-visible string translations

# ═══════════════════════════════════════════
# General
# ═══════════════════════════════════════════

MSG_WELCOME="Welcome to Linux Server Security Hardening Script"
MSG_VERSION="Version"
MSG_DESCRIPTION="This script will help you quickly configure server security options"
MSG_PRESS_ENTER="Press Enter to continue..."
MSG_YES="Yes"
MSG_NO="No"
MSG_CONFIRM="Confirm"
MSG_CANCEL="Cancel"
MSG_SKIP="Skip"
MSG_CONTINUE="Continue"
MSG_BACK="Back"
MSG_EXIT="Exit"

# ═══════════════════════════════════════════
# System Detection
# ═══════════════════════════════════════════

MSG_DETECT_START="Detecting system environment..."
MSG_DETECT_OS="Operating System"
MSG_DETECT_VERSION="System Version"
MSG_DETECT_ARCH="System Architecture"
MSG_DETECT_USER="Current User"
MSG_DETECT_ROOT="root user"
MSG_DETECT_NORMAL_USER="normal user"
MSG_DETECT_PKG_MANAGER="Package Manager"
MSG_DETECT_NETWORK="Network Connection"
MSG_DETECT_NETWORK_OK="OK"
MSG_DETECT_NETWORK_FAIL="Failed"
MSG_DETECT_COMPLETE="System detection complete"

MSG_ERROR_NOT_ROOT="Error: Please run this script as root user"
MSG_ERROR_UNSUPPORTED_OS="Error: Unsupported operating system"
MSG_ERROR_NO_NETWORK="Error: Cannot connect to network, please check network settings"

# ═══════════════════════════════════════════
# Menu
# ═══════════════════════════════════════════

MSG_MENU_TITLE="Please select hardening mode"
MSG_MENU_BASIC="[1] Basic Hardening (Recommended for beginners)"
MSG_MENU_STANDARD="[2] Standard Hardening (Recommended)"
MSG_MENU_ADVANCED="[3] Advanced Hardening (For experienced users)"
MSG_MENU_CUSTOM="[4] Custom (Select items one by one)"
MSG_MENU_CHOICE="Enter option number"
MSG_MENU_INVALID="Invalid option, please try again"

MSG_MODE_BASIC="Basic Hardening"
MSG_MODE_STANDARD="Standard Hardening"
MSG_MODE_ADVANCED="Advanced Hardening"
MSG_MODE_CUSTOM="Custom"

# ═══════════════════════════════════════════
# Main Menu
# ═══════════════════════════════════════════

MSG_MAIN_MENU_TITLE="Main Menu"
MSG_MAIN_MENU_STATUS="[1] System Status Check"
MSG_MAIN_MENU_STATUS_DESC="View current system security status (no changes)"
MSG_MAIN_MENU_SSH="[2] SSH Security Hardening"
MSG_MAIN_MENU_SSH_DESC="Port change, key auth, disable root/password login"
MSG_MAIN_MENU_FIREWALL="[3] Firewall Configuration"
MSG_MAIN_MENU_FIREWALL_DESC="UFW/firewalld rule configuration"
MSG_MAIN_MENU_FAIL2BAN="[4] Fail2Ban Intrusion Prevention"
MSG_MAIN_MENU_FAIL2BAN_DESC="Auto-ban malicious login attempts"
MSG_MAIN_MENU_AUDIT="[5] Audit Logging"
MSG_MAIN_MENU_AUDIT_DESC="Configure auditd system auditing, monitor security events"
MSG_MAIN_MENU_USERS="[6] User Management"
MSG_MAIN_MENU_USERS_DESC="Create user, configure password, SSH key, sudo privileges"
MSG_MAIN_MENU_KERNEL="[7] Kernel Security Hardening"
MSG_MAIN_MENU_KERNEL_DESC="sysctl security parameters, kernel module restrictions"
MSG_MAIN_MENU_FILESYSTEM="[8] Filesystem Security"
MSG_MAIN_MENU_FILESYSTEM_DESC="Permission check, SUID audit, orphan file check"
MSG_MAIN_MENU_QUICK="[9] Full Security Wizard"
MSG_MAIN_MENU_QUICK_DESC="Step-by-step guided configuration, choose at each step"
MSG_MAIN_MENU_REPORT="[10] View Last Report"
MSG_MAIN_MENU_REPORT_DESC="View detailed report from last security hardening"
MSG_MAIN_MENU_EXIT="[0] Exit"
MSG_MAIN_MENU_PROMPT="Enter option"
MSG_MAIN_MENU_CHOICE="Please select an action"
MSG_MAIN_MENU_SYSTEM_INFO="System"

# SSH Submenu
MSG_SSH_MENU_TITLE="SSH Security Hardening"
MSG_SSH_MENU_PORT="[1] Change SSH Port"
MSG_SSH_MENU_KEY="[2] Generate SSH Key Pair"
MSG_SSH_MENU_ROOT="[3] Disable Root Remote Login"
MSG_SSH_MENU_PASSWD="[4] Disable Password Login"
MSG_SSH_MENU_PARAMS="[5] Configure SSH Security Parameters"
MSG_SSH_MENU_ALL="[6] Run All Above"
MSG_SSH_MENU_BACK="[0] Back to Main Menu"

# Firewall Submenu
MSG_FIREWALL_MENU_TITLE="Firewall Configuration"
MSG_FIREWALL_MENU_ENABLE="[1] Enable Firewall with Basic Rules"
MSG_FIREWALL_MENU_HTTP="[2] Open HTTP/HTTPS Ports"
MSG_FIREWALL_MENU_ICMP="[3] Allow ICMP Ping"
MSG_FIREWALL_MENU_BACK="[0] Back to Main Menu"

# System Status
MSG_STATUS_TITLE="System Security Status"
MSG_STATUS_SSH_PORT="SSH Port"
MSG_STATUS_SSH_ROOT="Root Remote Login"
MSG_STATUS_SSH_PASSWD="Password Authentication"
MSG_STATUS_SSH_KEY="Key Authentication"
MSG_STATUS_FIREWALL="Firewall"
MSG_STATUS_FAIL2BAN="Fail2Ban"
MSG_STATUS_AUDIT="Audit Logging"
MSG_STATUS_ENABLED="Enabled"
MSG_STATUS_DISABLED="Disabled"
MSG_STATUS_INSTALLED="Installed"
MSG_STATUS_NOT_INSTALLED="Not Installed"
MSG_STATUS_ALLOWED="Allowed"
MSG_STATUS_NOT_ALLOWED="Disabled"
MSG_STATUS_DEFAULT_PORT="Default port, consider changing"
MSG_STATUS_CONFIGURED="Configured"
MSG_DETECTION_SUMMARY="System Detection Summary:"

# Report
MSG_REPORT_NOT_FOUND="No hardening report found. Please run hardening first."

# Confirmation prompts
MSG_CONFIRM_SSH_PORT="Confirm changing SSH port?"
MSG_CONFIRM_SSH_KEY="Confirm generating SSH key pair?"
MSG_CONFIRM_SSH_ROOT="Confirm disabling root remote login?"
MSG_CONFIRM_SSH_PASSWD="Confirm disabling password login?"
MSG_CONFIRM_SSH_PARAMS="Confirm configuring SSH security parameters?"
MSG_CONFIRM_SSH_ALL="Confirm running all SSH hardening?"
MSG_CONFIRM_FIREWALL_ENABLE="Confirm enabling firewall?"
MSG_CONFIRM_FIREWALL_HTTP="Confirm opening HTTP/HTTPS ports?"
MSG_CONFIRM_FIREWALL_ICMP="Confirm allowing ICMP ping?"
MSG_CONFIRM_FAIL2BAN="Confirm installing and configuring Fail2Ban?"

# Quick Hardening
MSG_QUICK_TITLE="Quick Hardening"

# ═══════════════════════════════════════════
# Task Descriptions
# ═══════════════════════════════════════════

MSG_TASK_SSH="SSH Security Hardening"
MSG_TASK_FIREWALL="Firewall Configuration"
MSG_TASK_FAIL2BAN="Fail2Ban Intrusion Prevention"
MSG_TASK_USER_MGMT="User Management"
MSG_TASK_KERNEL="Kernel Security Hardening"
MSG_TASK_FILESYSTEM="Filesystem Security"
MSG_TASK_AUDIT="Audit Log Configuration"
MSG_TASK_SERVICES="Service Management"
MSG_TASK_DEV_COMING_SOON="Coming soon..."

MSG_TASK_SSH_DESC="Configure SSH security options including port change, key authentication, disable root login, etc."
MSG_TASK_FIREWALL_DESC="Configure firewall rules to restrict unnecessary network access"
MSG_TASK_FAIL2BAN_DESC="Install and configure Fail2Ban to prevent brute force attacks"

# ═══════════════════════════════════════════
# SSH Security
# ═══════════════════════════════════════════

MSG_SSH_START="Starting SSH security hardening..."
MSG_SSH_BACKUP="Backing up SSH configuration file"
MSG_SSH_BACKUP_SUCCESS="Backup successful"
MSG_SSH_BACKUP_FAIL="Backup failed"

# SSH Port
MSG_SSH_PORT_TITLE="Change SSH Port"
MSG_SSH_PORT_CURRENT="Current SSH port"
MSG_SSH_PORT_PROMPT="Enter new SSH port number"
MSG_SSH_PORT_DEFAULT="Default"
MSG_SSH_PORT_INVALID="Invalid port number, please enter a number between 1-65535"
MSG_SSH_PORT_IN_USE="Port is already in use, please choose another port"
MSG_SSH_PORT_SUCCESS="SSH port has been changed"
MSG_SSH_PORT_HINT="Use the following command to connect: ssh -p {port} user@your-server-ip"

# SSH Port Interactive Options
MSG_SSH_PORT_OPTION_TITLE="Choose SSH port configuration method"
MSG_SSH_PORT_OPTION_CUSTOM="[1] Enter custom port (default: 2222)"
MSG_SSH_PORT_OPTION_RANDOM="[2] Generate random high port (1024-65535)"
MSG_SSH_PORT_OPTION_KEEP="[3] Keep current port (skip)"
MSG_SSH_PORT_OPTION_PROMPT="Enter option [1-3]"
MSG_SSH_PORT_RANDOM_GEN="Random port generated: "
MSG_SSH_PORT_RANDOM_ACCEPT="Use this port? (y=yes / n=regenerate / enter number=custom)"
MSG_SSH_PORT_CONFIRM="Confirm changing SSH port from {current} to {new}?"
MSG_SSH_PORT_SKIP="Skipping SSH port change"

# SSH Parameter Customization
MSG_SSH_PARAMS_CUSTOM_TITLE="SSH Security Parameter Configuration"
MSG_SSH_PARAMS_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_SSH_PARAMS_MAXAUTHTRIES="Max authentication attempts (MaxAuthTries)"
MSG_SSH_PARAMS_LOGINGRACETIME="Login grace time in seconds (LoginGraceTime)"
MSG_SSH_PARAMS_CLIENTALIVEINTERVAL="Client alive interval in seconds (ClientAliveInterval)"
MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX="Max client alive count (ClientAliveCountMax)"
MSG_SSH_PARAMS_MAXSESSIONS="Max concurrent sessions (MaxSessions)"

# Fail2Ban Custom Parameters
MSG_FAIL2BAN_CUSTOM_TITLE="Fail2Ban Parameter Configuration"
MSG_FAIL2BAN_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_FAIL2BAN_BANTIME_PROMPT="Ban duration in seconds (bantime)"
MSG_FAIL2BAN_FINDTIME_PROMPT="Detection window in seconds (findtime)"
MSG_FAIL2BAN_MAXRETRY_PROMPT="Max failure attempts (maxretry)"

# Full Wizard
MSG_WIZARD_TITLE="Full Security Configuration Wizard"
MSG_WIZARD_DESC="This wizard will guide you through all security configurations step by step. Each step: confirm / modify / skip."
MSG_WIZARD_STEP_INIT="[0/9] System Initialization"
MSG_WIZARD_STEP_SSH="[1/9] SSH Security Hardening"
MSG_WIZARD_STEP_FIREWALL="[2/9] Firewall Configuration"
MSG_WIZARD_STEP_FAIL2BAN="[3/9] Fail2Ban Intrusion Prevention"
MSG_WIZARD_STEP_AUDIT="[4/9] Audit Logging Configuration"
MSG_WIZARD_STEP_USERS="[5/9] User Management"
MSG_WIZARD_STEP_KERNEL="[6/9] Kernel Security Hardening"
MSG_WIZARD_STEP_FILESYSTEM="[7/9] Filesystem Security"
MSG_WIZARD_STEP_SUMMARY="[9/9] Change Summary & Confirmation"
MSG_WIZARD_SKIP_STEP="Skip this step? (y/N)"
MSG_WIZARD_COMPLETE="Wizard complete"
MSG_WIZARD_SKIPPED="Skipped"
MSG_WIZARD_SKIPPED_INIT="Skipping system initialization"
MSG_WIZARD_ERR_INIT="System initialization had errors"
MSG_WIZARD_SKIPPED_SSH="Skipping SSH hardening"
MSG_WIZARD_ERR_SSH="SSH hardening had errors, continuing"
MSG_WIZARD_SKIPPED_FIREWALL="Skipping firewall configuration"
MSG_WIZARD_ERR_FIREWALL="Firewall configuration had errors"
MSG_WIZARD_SKIPPED_FAIL2BAN="Skipping Fail2Ban configuration"
MSG_WIZARD_ERR_FAIL2BAN="Fail2Ban configuration had errors"
MSG_WIZARD_SKIPPED_AUDIT="Skipping audit logging configuration"
MSG_WIZARD_ERR_AUDIT="Audit logging configuration had errors"
MSG_WIZARD_SKIPPED_USERS="Skipping user management"
MSG_WIZARD_ERR_USERS="User management had errors"
MSG_WIZARD_SKIPPED_KERNEL="Skipping kernel hardening"
MSG_WIZARD_ERR_KERNEL="Kernel hardening had errors"
MSG_WIZARD_SKIPPED_FILESYSTEM="Skipping filesystem check"
MSG_WIZARD_ERR_FILESYSTEM="Filesystem check had errors"
MSG_WIZARD_ERR_HINT="(some steps had errors, check logs)"

# SSH Key
MSG_SSH_KEY_TITLE="Generate SSH Key Pair"
MSG_SSH_KEY_TYPE="Key type"
MSG_SSH_KEY_ED25519="Ed25519 (Recommended)"
MSG_SSH_KEY_PROMPT_PATH="Enter key save path"
MSG_SSH_KEY_PROMPT_PASSPHRASE="Enter key passphrase (leave empty for no passphrase)"
MSG_SSH_KEY_SUCCESS="SSH key has been generated"
MSG_SSH_KEY_AUTHORIZED="Public key added to authorized_keys"
MSG_SSH_KEY_PERMS="Correct file permissions set"

# Root Login
MSG_SSH_ROOT_TITLE="Disable Root Remote Login"
MSG_SSH_ROOT_DESC="Disable root user from logging in via SSH for improved security"
MSG_SSH_ROOT_NO_USER="Warning: No other login users available"
MSG_SSH_ROOT_CREATE_USER="Please create a normal user with sudo privileges first"
MSG_SSH_ROOT_RISK="Risk: After disabling, root cannot login via SSH"
MSG_SSH_ROOT_CONFIRM="Confirm disable root remote login?"
MSG_SSH_ROOT_SUCCESS="Root remote login has been disabled"

# Password Login
MSG_SSH_PASSWD_TITLE="Disable Password Login"
MSG_SSH_PASSWD_DESC="Disable password authentication, allow key authentication only"
MSG_SSH_PASSWD_NO_KEY="Warning: No valid SSH keys detected"
MSG_SSH_PASSWD_RISK="Risk: After disabling password login, you must use key authentication"
MSG_SSH_PASSWD_CONFIRM="Confirm disable password login?"
MSG_SSH_PASSWD_SUCCESS="Password login disabled, key authentication only"

# Other Security Parameters
MSG_SSH_PARAMS_TITLE="Configure Other SSH Security Parameters"
MSG_SSH_PARAMS_SUCCESS="SSH security parameters configured"

# Validation
MSG_SSH_VALIDATE="Validating SSH configuration..."
MSG_SSH_VALIDATE_SUCCESS="SSH configuration validation passed"
MSG_SSH_VALIDATE_FAIL="SSH configuration validation failed"
MSG_SSH_RESTART="Restarting SSH service..."
MSG_SSH_RESTART_SUCCESS="SSH service restarted"
MSG_SSH_RESTART_FAIL="SSH service restart failed"

# Rollback Protection
MSG_SSH_ROLLBACK_TIMER="Setting SSH rollback protection timer (5 minutes)"
MSG_SSH_ROLLBACK_HINT="If unable to connect with new config within 5 minutes, will auto-rollback"
MSG_SSH_ROLLBACK_CANCEL="New connection detected, cancelling rollback timer"
MSG_SSH_ROLLBACK_EXEC="No new connections within 5 minutes, rolling back SSH configuration..."
MSG_SSH_ROLLBACK_SUCCESS="SSH configuration rolled back to original state"
MSG_SSH_ROLLBACK_CRON="Rollback scheduled task set"

MSG_SSH_COMPLETE="SSH security hardening complete"

# ═══════════════════════════════════════════
# Firewall
# ═══════════════════════════════════════════

MSG_FIREWALL_TITLE="Firewall Configuration"
MSG_FIREWALL_INSTALL="Installing firewall tool..."
MSG_FIREWALL_INSTALL_DONE="Firewall tool installed"
MSG_FIREWALL_ALREADY_INSTALLED="Firewall tool already installed"
MSG_FIREWALL_UNSUPPORTED_OS="Unsupported operating system, skipping firewall configuration"
MSG_FIREWALL_RESET="Resetting firewall rules..."
MSG_FIREWALL_RESET_DONE="Firewall rules reset"
MSG_FIREWALL_DEFAULT_POLICY="Configuring default policy: deny incoming, allow outgoing..."
MSG_FIREWALL_DEFAULT_POLICY_DONE="Default policy configured"
MSG_FIREWALL_CONFIG_SSH="Opening SSH port..."
MSG_FIREWALL_PORT_OPENED="Port opened"
MSG_FIREWALL_PORT_CLOSED="Port closed"
MSG_FIREWALL_HTTP_PROMPT="Do you need to open HTTP/HTTPS ports?"
MSG_FIREWALL_HTTP_CONFIRM="Open HTTP (80) and HTTPS (443) ports"
MSG_FIREWALL_ICMP_PROMPT="Allow ping (ICMP)?"
MSG_FIREWALL_ICMP_CONFIRM="Allow ICMP ping requests"
MSG_FIREWALL_ICMP_DEFAULT="UFW allows ICMP by default"
MSG_FIREWALL_ICMP_ALLOWED="ICMP allowed"
MSG_FIREWALL_ICMP_DENIED="ICMP denied"
MSG_FIREWALL_ICMP_UFW_NOTE="UFW requires manual edit of /etc/ufw/before.rules to disable ICMP"
MSG_FIREWALL_ENABLE="Enabling firewall..."
MSG_FIREWALL_ENABLE_DONE="Firewall enabled"
MSG_FIREWALL_STATUS="Firewall Status"
MSG_FIREWALL_DONE="Firewall configuration complete"
MSG_FIREWALL_SSH_PORT22="Safety: Port 22 kept open (prevents SSH lockout after port change)"
MSG_FIREWALL_SSH_PORT22_WARN="⚠ After confirming the new SSH port works, manually close port 22:"
MSG_FIREWALL_SSH_PORT22_CLOSE="   sudo ufw deny 22/tcp"
MSG_FIREWALL_CUSTOM_PORTS="Need to open other ports? (Enter port number, empty to finish)"
MSG_FIREWALL_INVALID_PORT="Invalid port number, please enter a number between 1-65535"

MSG_FIREWALL_TIPS_TITLE="Firewall management commands:"
MSG_FIREWALL_TIPS_UFW_1="Check status: sudo ufw status verbose"
MSG_FIREWALL_TIPS_UFW_2="Open port: sudo ufw allow <port>"
MSG_FIREWALL_TIPS_UFW_3="Close port: sudo ufw deny <port>"
MSG_FIREWALL_TIPS_UFW_4="Disable firewall: sudo ufw disable"

MSG_FIREWALL_TIPS_FIREWALLD_1="Check status: firewall-cmd --list-all"
MSG_FIREWALL_TIPS_FIREWALLD_2="Open port: firewall-cmd --permanent --add-port=<port>/tcp"
MSG_FIREWALL_TIPS_FIREWALLD_3="Close port: firewall-cmd --permanent --remove-port=<port>/tcp"
MSG_FIREWALL_TIPS_FIREWALLD_4="Reload: firewall-cmd --reload"

# ═══════════════════════════════════════════
# Fail2Ban
# ═══════════════════════════════════════════

MSG_FAIL2BAN_TITLE="Fail2Ban Intrusion Prevention"
MSG_FAIL2BAN_INSTALL="Installing Fail2Ban..."
MSG_FAIL2BAN_INSTALL_DONE="Fail2Ban installed"
MSG_FAIL2BAN_ALREADY_INSTALLED="Fail2Ban already installed"
MSG_FAIL2BAN_UNSUPPORTED_OS="Unsupported operating system, skipping Fail2Ban configuration"
MSG_FAIL2BAN_CONFIGURE="Configuring Fail2Ban jail..."
MSG_FAIL2BAN_CONFIGURE_DONE="Fail2Ban jail configured"
MSG_FAIL2BAN_CONFIG_INFO="Fail2Ban configuration info:"
MSG_FAIL2BAN_ENABLE="Starting Fail2Ban service..."
MSG_FAIL2BAN_ENABLE_DONE="Fail2Ban service started"
MSG_FAIL2BAN_ENABLE_FAILED="Fail2Ban service failed to start"
MSG_FAIL2BAN_STATUS="Fail2Ban Status"
MSG_FAIL2BAN_SERVICE_STATUS="Service Status:"
MSG_FAIL2BAN_JAIL_STATUS="Jail Status:"
MSG_FAIL2BAN_BANNED_LIST="Banned IPs:"
MSG_FAIL2BAN_JAIL_NOT_FOUND="Jail not found"
MSG_FAIL2BAN_NOT_INSTALLED="Fail2Ban not installed"
MSG_FAIL2BAN_IP_BANNED="IP banned"
MSG_FAIL2BAN_IP_UNBANNED="IP unbanned"
MSG_FAIL2BAN_DONE="Fail2Ban configuration complete"

MSG_FAIL2BAN_TIPS_TITLE="Fail2Ban management commands:"
MSG_FAIL2BAN_TIPS_1="Check status: fail2ban-client status"
MSG_FAIL2BAN_TIPS_2="Check jail: fail2ban-client status sshd"
MSG_FAIL2BAN_TIPS_3="Ban IP: fail2ban-client set sshd banip <ip>"
MSG_FAIL2BAN_TIPS_4="Unban IP: fail2ban-client set sshd unbanip <ip>"
MSG_FAIL2BAN_TIPS_5="Restart service: systemctl restart fail2ban"

# ═══════════════════════════════════════════
# Audit Logging
# ═══════════════════════════════════════════

MSG_AUDIT_TITLE="Audit Logging Configuration"
MSG_AUDIT_INSTALL="Installing auditd..."
MSG_AUDIT_INSTALL_DONE="auditd installed"
MSG_AUDIT_INSTALL_FAILED="auditd installation failed"
MSG_AUDIT_ALREADY_INSTALLED="auditd already installed"
MSG_AUDIT_UNSUPPORTED_OS="Unsupported operating system, skipping audit configuration"
MSG_AUDIT_BACKUP_RULES="Backing up audit rules file"
MSG_AUDIT_BACKUP_CONF="Backing up auditd configuration file"
MSG_AUDIT_CONFIGURE_RULES="Generating audit rules..."
MSG_AUDIT_CONFIGURE_RULES_DONE="Audit rules generated"
MSG_AUDIT_CONFIGURE_CONF="Configuring auditd..."
MSG_AUDIT_CONFIGURE_CONF_DONE="auditd configured"
MSG_AUDIT_LOAD_RULES="Loading audit rules..."
MSG_AUDIT_LOAD_RULES_DONE="Audit rules loaded"
MSG_AUDIT_LOAD_RULES_WARN="Some rules failed to load (may be incompatible with kernel version)"
MSG_AUDIT_ENABLE="Enabling auditd service..."
MSG_AUDIT_ENABLE_DONE="auditd service enabled"
MSG_AUDIT_ENABLE_FAILED="auditd service failed to enable"
MSG_AUDIT_STATUS="Audit Status"
MSG_AUDIT_SERVICE_STATUS="Service Status:"
MSG_AUDIT_RULES_COUNT="Rules Count:"
MSG_AUDIT_LOG_INFO="Log File:"
MSG_AUDIT_LOG_NOT_FOUND="Not yet generated"
MSG_AUDIT_CONFIG_INFO="Current audit configuration:"
MSG_AUDIT_DONE="Audit logging configuration complete!"
MSG_AUDIT_NOT_INSTALLED="auditd not installed"

# Audit Wizard - Rule Level
MSG_AUDIT_RULES_LEVEL_TITLE="Select audit rule level"
MSG_AUDIT_RULES_BASIC="[1] Basic - Identity, SSH, sudo monitoring"
MSG_AUDIT_RULES_STANDARD="[2] Standard - Basic + network, cron, log tampering (Recommended)"
MSG_AUDIT_RULES_FULL="[3] Full - All security event monitoring"
MSG_AUDIT_RULES_LEVEL_PROMPT="Select rule level"

# Audit Wizard - Custom Parameters
MSG_AUDIT_CUSTOM_TITLE="auditd Parameter Configuration"
MSG_AUDIT_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_AUDIT_LOG_SIZE_PROMPT="Max log file size (MB)"
MSG_AUDIT_LOG_COUNT_PROMPT="Number of log files to keep"
MSG_AUDIT_INVALID_CHOICE="Invalid option, using default (standard rules)"
MSG_AUDIT_INVALID_NUMBER="Please enter a valid positive integer"

# Audit Search/Report
MSG_AUDIT_SEARCH="Searching audit log (key={key})..."
MSG_AUDIT_REPORT="Generating audit report..."
MSG_AUDIT_REPORT_SUMMARY="Audit Report Summary:"
MSG_AUDIT_REPORT_AUTH="Authentication Audit Summary:"

# Audit Tips
MSG_AUDIT_TIPS_TITLE="Audit log management commands:"
MSG_AUDIT_TIPS_1="View rules: auditctl -l"
MSG_AUDIT_TIPS_2="Search log: ausearch -k <key> -i"
MSG_AUDIT_TIPS_3="Audit report: aureport --summary"
MSG_AUDIT_TIPS_4="Live log: tail -f /var/log/audit/audit.log"
MSG_AUDIT_TIPS_5="Service status: systemctl status auditd"

# ═══════════════════════════════════════════
# User Management
# ═══════════════════════════════════════════

MSG_USERS_WIZARD_TITLE="User Management Wizard"
MSG_USERS_WIZARD_DESC="Create admin user, configure password, SSH key, sudo privileges"
MSG_USERS_WIZARD_START="Start user management configuration?"
MSG_USERS_WIZARD_SKIPPED="Skipping user management"
MSG_USERS_WIZARD_DONE="User management complete"

MSG_USERS_CREATE_TITLE="Create Admin User"
MSG_USERS_ENTER_USERNAME="Enter username"
MSG_USERS_ENTER_USERNAME_PASS="Enter username to set password"
MSG_USERS_ENTER_USERNAME_SSH="Enter username to configure SSH key"
MSG_USERS_ENTER_USERNAME_SUDO="Enter username to configure sudo"
MSG_USERS_NAME_EMPTY="Username cannot be empty"
MSG_USERS_NAME_TOO_SHORT="Username must be 3-32 characters"
MSG_USERS_NAME_INVALID="Invalid username (start with letter/underscore, alphanumeric/underscore/hyphen only)"
MSG_USERS_ALREADY_EXISTS="User already exists"
MSG_USERS_NOT_FOUND="User not found"
MSG_USERS_CREATING="Creating user"
MSG_USERS_CREATE_DONE="User created successfully"
MSG_USERS_CREATE_FAILED="Failed to create user"
MSG_USERS_CREATE_SKIPPED="Skipping user creation"
MSG_USERS_CONFIRM_CREATE="Confirm creating this user and adding to sudo group?"
MSG_USERS_WILL_CREATE="Will create user"

MSG_USERS_SET_PASS_TITLE="Set User Password"
MSG_USERS_ENTER_PASS="Enter password"
MSG_USERS_CONFIRM_PASS="Confirm password"
MSG_USERS_PASS_TOO_SHORT="Password must be at least 8 characters"
MSG_USERS_PASS_MISMATCH="Passwords do not match"
MSG_USERS_SETTING_PASS="Setting password"
MSG_USERS_PASS_SET_DONE="Password set successfully"
MSG_USERS_PASS_SET_FAILED="Failed to set password"

MSG_USERS_SSH_KEY_TITLE="Configure SSH Key"
MSG_USERS_SSH_KEY_EXISTS="SSH key already exists"
MSG_USERS_SSH_KEY_OVERWRITE="Overwrite existing key?"
MSG_USERS_SSH_KEY_SKIPPED="Skipping SSH key configuration"
MSG_USERS_SSH_KEY_GENERATING="Generating Ed25519 key pair"
MSG_USERS_SSH_KEY_FAILED="SSH key generation failed"
MSG_USERS_SSH_KEY_DONE="SSH key generated"
MSG_USERS_SSH_KEY_HINT="Please download the private key to local storage. WARNING: The key has no passphrase — protect it carefully."

MSG_USERS_SUDO_TITLE="Configure sudo NOPASSWD"
MSG_USERS_SUDO_SECURITY_HINT="Security: NOPASSWD allows sudo without password, use with caution"
MSG_USERS_SUDO_CONFIGURING="Configuring sudo NOPASSWD"
MSG_USERS_SUDO_ALREADY_CONFIGURED="sudo NOPASSWD already configured"
MSG_USERS_SUDO_SYNTAX_ERROR="sudoers file syntax error, rolled back"
MSG_USERS_SUDO_DONE="sudo NOPASSWD configured"
MSG_USERS_NOT_IN_SUDO="User not in sudo group"
MSG_USERS_ADD_TO_SUDO="Add user to sudo group?"
MSG_USERS_ADDED_TO_SUDO="Added to sudo group"
MSG_USERS_SUDO_ADD_FAILED="Failed to add to sudo group"

MSG_USERS_STEP_CREATE="[1/4] Create Admin User"
MSG_USERS_STEP_CREATE_CONFIRM="Create a new admin user?"
MSG_USERS_STEP_PASS="[2/4] Set User Password"
MSG_USERS_STEP_PASS_CONFIRM="Set password for user?"
MSG_USERS_STEP_SSH="[3/4] Configure SSH Key"
MSG_USERS_STEP_SSH_CONFIRM="Generate SSH key for user?"
MSG_USERS_STEP_SUDO="[4/4] Configure sudo NOPASSWD"
MSG_USERS_STEP_SUDO_CONFIRM="Configure sudo NOPASSWD? (default: skip)"
MSG_USERS_STEP_SKIPPED="Skipping this step"

MSG_USERS_SUMMARY="User Management Summary"
MSG_USERS_SUMMARY_USER="Username"
MSG_USERS_SUMMARY_GROUP="sudo group"
MSG_USERS_SUMMARY_HOME="Home directory"
MSG_USERS_SUMMARY_NONE="No new user created"

# ═══════════════════════════════════════════
# Kernel Hardening
# ═══════════════════════════════════════════

MSG_KERNEL_WIZARD_TITLE="Kernel Security Hardening Wizard"
MSG_KERNEL_WIZARD_DESC="Configure sysctl security parameters, disable unnecessary kernel modules"
MSG_KERNEL_WIZARD_START="Start kernel security hardening?"
MSG_KERNEL_WIZARD_SKIPPED="Skipping kernel hardening"
MSG_KERNEL_WIZARD_DONE="Kernel hardening complete"

MSG_KERNEL_SYSCTL_TITLE="sysctl Security Parameters"
MSG_KERNEL_SYSCTL_APPLYING="Applying sysctl security parameters"
MSG_KERNEL_SYSCTL_DONE="sysctl security parameters applied"
MSG_KERNEL_SYSCTL_PARTIAL="Some sysctl parameters failed to apply"
MSG_KERNEL_TEMPLATE_NOT_FOUND="sysctl template not found, using built-in config"
MSG_KERNEL_BACKUP_CONF="Backing up sysctl security config"

MSG_KERNEL_VERIFYING="Verifying sysctl parameters"
MSG_KERNEL_VERIFY_DONE="sysctl parameters verified"
MSG_KERNEL_VERIFY_FAILED="Parameter verification failed"
MSG_KERNEL_VERIFY_PARTIAL="Some parameters failed verification"
MSG_KERNEL_VERIFY_PARAMS_FAILED="parameters"

MSG_KERNEL_MODULES_TITLE="Kernel Module Restrictions"
MSG_KERNEL_MODULE_DISABLE="Disabling module"
MSG_KERNEL_MODULE_DISABLED="Disabled"
MSG_KERNEL_MODULE_CANNOT_DISABLE="Cannot disable"
MSG_KERNEL_MODULE_NOT_LOADED="Module not loaded, skipped"
MSG_KERNEL_MODULES_DONE="Kernel module processing complete"
MSG_KERNEL_MODULES_DISABLED="disabled"
MSG_KERNEL_MODULES_SKIPPED="skipped"

MSG_KERNEL_RESTORE_TITLE="Restore sysctl Configuration"
MSG_KERNEL_RESTORE_CONF="Restoring sysctl config file"
MSG_KERNEL_RESTORE_DONE="sysctl configuration restored"
MSG_KERNEL_RESTORE_FAILED="sysctl restore failed"
MSG_KERNEL_NO_CONF_TO_RESTORE="No sysctl config to restore"
MSG_KERNEL_NO_BACKUP_FOUND="No backup found, removing hardening config"

MSG_KERNEL_STEP_SYSCTL="[1/2] sysctl Security Parameters"
MSG_KERNEL_STEP_SYSCTL_CONFIRM="Apply sysctl security parameters?"
MSG_KERNEL_STEP_MODULES="[2/2] Kernel Module Restrictions"
MSG_KERNEL_STEP_MODULES_CONFIRM="Disable unnecessary kernel modules?"
MSG_KERNEL_STEP_SKIPPED="Skipping this step"

MSG_KERNEL_SYSCTL_SUMMARY_TITLE="sysctl parameters to be set"
MSG_KERNEL_SYSCTL_SUMMARY_SYN="SYN Flood protection (tcp_syncookies)"
MSG_KERNEL_SYSCTL_SUMMARY_REDIRECT="Disable ICMP redirects"
MSG_KERNEL_SYSCTL_SUMMARY_ROUTE="Disable source routing"
MSG_KERNEL_SYSCTL_SUMMARY_FORWARD="Disable IP forwarding"
MSG_KERNEL_SYSCTL_SUMMARY_ASLR="ASLR address randomization"

MSG_KERNEL_MODULES_SUMMARY_TITLE="Kernel modules to be disabled"

MSG_KERNEL_SUMMARY="Kernel Hardening Summary"
MSG_KERNEL_SUMMARY_CONF="Config file"
MSG_KERNEL_SUMMARY_PARAMS="Parameter count"
MSG_KERNEL_SUMMARY_NO_CONF="No config file generated"

# ═══════════════════════════════════════════
# Filesystem Security
# ═══════════════════════════════════════════

MSG_FS_WIZARD_TITLE="Filesystem Security Wizard"
MSG_FS_WIZARD_DESC="Check critical permissions, SUID/SGID audit, orphan file check"
MSG_FS_WIZARD_START="Start filesystem security check?"
MSG_FS_WIZARD_SKIPPED="Skipping filesystem check"
MSG_FS_WIZARD_DONE="Filesystem security check complete"

MSG_FS_PERM_TITLE="Critical Permission Check"
MSG_FS_PERM_NOT_FOUND="File not found"
MSG_FS_PERM_MISMATCH="Permission mismatch"
MSG_FS_PERM_OK="Permission OK"
MSG_FS_PERM_ALL_OK="All permissions passed"
MSG_FS_PERM_CHECKED="files checked"
MSG_FS_PERM_ISSUES="Permission issues found"

MSG_FS_PERM_FIX_TITLE="Fix Critical Permissions"
MSG_FS_PERM_FIXING="Fixing permission"
MSG_FS_PERM_FIXED="Fixed"
MSG_FS_PERM_FIX_FAILED="Permission fix failed"
MSG_FS_PERM_FIX_DONE="Permission fix complete"
MSG_FS_PERM_FIX_SKIPPED="Skipped fix"
MSG_FS_PERM_FIX_SKIPPED_COUNT="skipped"
MSG_FS_PERM_CONFIRM_FIX="Fix this file permission?"
MSG_FS_PERM_CURRENT="Current"
MSG_FS_PERM_EXPECTED="Expected"
MSG_FS_PERM_ALREADY_OK="Already correct"
MSG_FS_PERM_ISSUES_FOUND="Permission issues found, fix one by one?"

MSG_FS_SUID_TITLE="SUID/SGID Audit"
MSG_FS_SUID_SCANNING="Scanning SUID/SGID files..."
MSG_FS_SUID_RESULTS_TITLE="SUID/SGID Scan Results"
MSG_FS_SUID_SUSPICIOUS="suspicious"
MSG_FS_SUID_SUMMARY_TITLE="Scan Summary"
MSG_FS_SUID_TOTAL="SUID files"
MSG_FS_SGID_TOTAL="SGID files"
MSG_FS_SUID_SUSPICIOUS_COUNT="Suspicious files"
MSG_FS_SUID_SUSPICIOUS_HINT="Suspicious SUID files found, consider removing unnecessary SUID bits"
MSG_FS_SUID_REMOVE_CMD="Command to remove SUID bit:"
MSG_FS_SUID_ALL_KNOWN="All SUID files are known standard files"

MSG_FS_ORPHAN_TITLE="Orphan File Check"
MSG_FS_ORPHAN_SCANNING="Scanning orphan files..."
MSG_FS_ORPHAN_NONE="No orphan files found"
MSG_FS_ORPHAN_RESULTS_TITLE="Orphan File List"
MSG_FS_ORPHAN_FOUND="orphan files"
MSG_FS_ORPHAN_TRUNCATED="Showing first 50 results — more orphan files may exist"
MSG_FS_ORPHAN_HINT="Orphan files found"
MSG_FS_ORPHAN_FIX_CMD="Fix suggestion: sudo chown root:root <file>"

MSG_FS_STEP_PERM="[1/3] Critical Permission Check"
MSG_FS_STEP_SUID="[2/3] SUID/SGID Audit"
MSG_FS_STEP_SUID_CONFIRM="Run SUID/SGID audit?"
MSG_FS_STEP_ORPHAN="[3/3] Orphan File Check"
MSG_FS_STEP_ORPHAN_CONFIRM="Check for orphan files?"
MSG_FS_STEP_SKIPPED="Skipping this step"

MSG_FS_SUMMARY="Filesystem Security Summary"
MSG_FS_SUMMARY_PERM_CHECK="Permission check"
MSG_FS_SUMMARY_SUID_CHECK="SUID audit"
MSG_FS_SUMMARY_ORPHAN_CHECK="Orphan file check"
MSG_FS_SUMMARY_DONE="Done"

# ═══════════════════════════════════════════
# Report
# ═══════════════════════════════════════════

MSG_REPORT_TITLE="Security Hardening Completion Report"
MSG_REPORT_SYSTEM="System Information"
MSG_REPORT_TASKS="Completed Tasks"
MSG_REPORT_CONFIGS="Modified Configuration Files"
MSG_REPORT_WARNINGS="Important Reminders"
MSG_REPORT_SAVED="Report saved to"
MSG_REPORT_WARN_SSH_PORT22="Firewall kept port 22 open. After confirming new SSH port works, close it: sudo ufw deny 22/tcp"
MSG_REPORT_WARN_FIREWALL="Firewall enabled. Ensure all required ports are properly opened."
MSG_REPORT_WARN_FAIL2BAN="Check Fail2Ban logs regularly: sudo tail -f /var/log/fail2ban.log"
MSG_REPORT_WARN_AUDIT="Check audit logs regularly: sudo aureport --summary or sudo ausearch -k identity"
MSG_REPORT_WARN_FS="Filesystem permissions changed, verify critical services still work"
MSG_STATUS_FS_SUID="SUID files"

# ═══════════════════════════════════════════
# Log
# ═══════════════════════════════════════════

MSG_LOG_START="Execution started"
MSG_LOG_COMPLETE="Execution completed"
MSG_LOG_ERROR="Execution error"
MSG_LOG_BACKUP="Backing up file"
MSG_LOG_RESTORE="Restoring file"

# ═══════════════════════════════════════════
# Errors and Warnings
# ═══════════════════════════════════════════

MSG_ERROR_SCRIPT_NOT_ROOT="This script must be run with root privileges"
MSG_ERROR_COMMAND_FAILED="Command execution failed"
MSG_ERROR_FILE_NOT_FOUND="File not found"
MSG_ERROR_BACKUP_FAILED="Backup failed"
MSG_ERROR_RESTORE_FAILED="Restore failed"

MSG_WARN_CONNECTION="Please test new configuration before closing current session"
MSG_WARN_SAVE_KEY="Please make sure you have saved your SSH private key file"
MSG_WARN_TEST_FIRST="Please test new configuration before closing current session"

# ═══════════════════════════════════════════
# Completion
# ═══════════════════════════════════════════

MSG_FINISH="Security hardening script execution complete"
MSG_FINISH_HINT="Thank you for using, please check log files if you have any questions"
MSG_GOODBYE="Goodbye!"
