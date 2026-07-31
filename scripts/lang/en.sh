#!/usr/bin/env bash
# English language file
# All user-visible string translations

# ═══════════════════════════════════════════
# General
# ═══════════════════════════════════════════

MSG_WELCOME="Welcome to Linux Server Security Hardening Script"
MSG_PRESS_ENTER="Press Enter to continue..."
MSG_CONFIRM="Confirm"
MSG_BACK="Back"

# ═══════════════════════════════════════════
# K3s (Lightweight Kubernetes)
# ═══════════════════════════════════════════

MSG_K3S_TITLE="K3s Lightweight Kubernetes"
MSG_K3S_INSTALLING="Installing K3s..."
MSG_K3S_DOWNLOADING="Downloading installation script from https://get.k3s.io..."
MSG_K3S_INSTALLED="K3s installation complete"
MSG_K3S_ALREADY="K3s already installed, skipping"
MSG_K3S_FAILED="K3s installation failed"
MSG_K3S_CANCELLED="K3s operation cancelled"
MSG_K3S_UNINSTALLING="Uninstalling K3s..."
MSG_K3S_UNINSTALLED="K3s has been uninstalled"
MSG_K3S_UNINSTALL_FAILED="K3s uninstall failed"
MSG_K3S_UNINSTALL_SCRIPT_NOT_FOUND="K3s uninstall script not found: /usr/local/bin/k3s-uninstall.sh"
MSG_K3S_STATUS_CHECKING="Checking K3s status..."
MSG_K3S_STATUS_RUNNING="K3s is running"
MSG_K3S_STATUS_NOT_RUNNING="K3s is not running"
MSG_K3S_CONFIRM="Confirm installing K3s?"
MSG_K3S_CONFIRM_UNINSTALL="Confirm uninstalling K3s? This will delete all K3s data and configuration."
MSG_K3S_CONFIGURING="Configuring K3s..."
MSG_K3S_KUBECONFIG="kubeconfig copied to ~/.kube/config"
MSG_K3S_KUBECONFIG_EXISTS="~/.kube/config already exists, skipping copy"
MSG_K3S_NODE_READY="Cluster node status:"
MSG_K3S_NODES_UNAVAILABLE="Unable to get node status (service may still be starting)"
MSG_K3S_DISABLE_TRAEFIK="Traefik disabled (--disable traefik)"
MSG_K3S_DISABLE_TRAEFIK_PROMPT="Disable the built-in Traefik Ingress Controller? (Recommended)"
MSG_K3S_VERSION="K3s Version"
MSG_K3S_BINARY="K3s Binary"
MSG_K3S_NOT_INSTALLED="K3s is not installed"
MSG_K3S_CURL_REQUIRED="K3s installation requires curl. Please install curl first."

# ═══════════════════════════════════════════
# System Detection
# ═══════════════════════════════════════════

MSG_DETECT_START="Detecting system environment..."
MSG_DETECT_OS="Operating System"
MSG_DETECT_ARCH="System Architecture"
MSG_DETECT_USER="Current User"
MSG_DETECT_ROOT="root user"
MSG_DETECT_NORMAL_USER="normal user"
MSG_DETECT_PKG_MANAGER="Package Manager"
MSG_DETECT_NETWORK="Network Connection"
MSG_DETECT_NETWORK_FAIL="Failed"
MSG_DETECT_COMPLETE="System detection complete"

MSG_ERROR_NOT_ROOT="Error: Please run this script as root user"
MSG_ERROR_UNSUPPORTED_OS="Error: Unsupported operating system"

# ═══════════════════════════════════════════
# Menu
# ═══════════════════════════════════════════

MSG_MENU_INVALID="Invalid option, please try again"
MSG_ERROR_NO_INPUT="No input detected. Use --status for non-interactive mode."


# ═══════════════════════════════════════════
# Main Menu
# ═══════════════════════════════════════════

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
MSG_MAIN_MENU_SERVICES="[9] Service Management"
MSG_MAIN_MENU_SERVICES_DESC="Audit running services, disable unnecessary services, scan open ports"
MSG_MAIN_MENU_QUICK="[11] Full Security Wizard"
MSG_MAIN_MENU_QUICK_DESC="Step-by-step guided configuration, choose at each step"
MSG_MAIN_MENU_REPORT="[12] View Last Report"
MSG_MAIN_MENU_REPORT_DESC="View detailed report from last security hardening"
MSG_MAIN_MENU_K3S="[13] K3s Lightweight Kubernetes"
MSG_MAIN_MENU_K3S_DESC="Install or uninstall lightweight Kubernetes (K3s)"
MSG_MAIN_MENU_AUTOUPDATE="[10] Auto Security Updates"
MSG_MAIN_MENU_AUTOUPDATE_DESC="Configure automatic security update installation"
MSG_MAIN_MENU_AIDE="[14] AIDE Intrusion Detection"
MSG_MAIN_MENU_AIDE_DESC="File integrity checking system, monitor critical file changes"
MSG_MAIN_MENU_CLAMAV="[15] ClamAV Virus Scanner"
MSG_MAIN_MENU_CLAMAV_DESC="Open-source antivirus, configure database update and scheduled scanning"
MSG_MAIN_MENU_ROOTKIT="[16] Rootkit Detection"
MSG_MAIN_MENU_ROOTKIT_DESC="rkhunter + chkrootkit to detect backdoors and rootkits"
MSG_MAIN_MENU_EXIT="[0] Exit"
MSG_MAIN_MENU_PROMPT="Enter option"
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

# K3s Submenu
MSG_K3S_MENU_TITLE="K3s Lightweight Kubernetes"
MSG_K3S_MENU_INSTALL="[1] Install K3s"
MSG_K3S_MENU_UNINSTALL="[2] Uninstall K3s"
MSG_K3S_MENU_STATUS="[3] Check K3s Status"
MSG_K3S_MENU_BACK="[0] Back to Main Menu"

# System Status
MSG_STATUS_TITLE="System Security Status"
MSG_STATUS_FIREWALL="Firewall"
MSG_STATUS_FAIL2BAN="Fail2Ban"
MSG_STATUS_AUDIT="Audit Logging"
MSG_STATUS_ENABLED="Enabled"
MSG_STATUS_DISABLED="Disabled"
MSG_STATUS_INSTALLED="Installed"
MSG_STATUS_NOT_INSTALLED="Not Installed"
MSG_DETECTION_SUMMARY="System Detection Summary:"

# Report

# Confirmation prompts
MSG_CONFIRM_FIREWALL_HTTP="Confirm opening HTTP/HTTPS ports?"

# Quick Hardening

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
MSG_SSH_PORT_INVALID="Invalid port number, please enter a number between 1-65535"
MSG_SSH_PORT_IN_USE="Port is already in use, please choose another port"
MSG_SSH_PORT_SUCCESS="SSH port has been changed"
MSG_SSH_PORT_HINT="Use the following command to connect: ssh -p %s user@your-server-ip"

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
MSG_WIZARD_STEP_INIT="[0/14] System Initialization"
MSG_WIZARD_STEP_SSH="[1/14] SSH Security Hardening"
MSG_WIZARD_STEP_FIREWALL="[2/14] Firewall Configuration"
MSG_WIZARD_STEP_FAIL2BAN="[3/14] Fail2Ban Intrusion Prevention"
MSG_WIZARD_STEP_AUDIT="[4/14] Audit Logging Configuration"
MSG_WIZARD_STEP_USERS="[5/14] User Management"
MSG_WIZARD_STEP_KERNEL="[6/14] Kernel Security Hardening"
MSG_WIZARD_STEP_FILESYSTEM="[7/14] Filesystem Security"
MSG_WIZARD_STEP_SERVICES="[8/14] Service Management"
MSG_WIZARD_STEP_AIDE="[10/14] AIDE Intrusion Detection"
MSG_WIZARD_STEP_CLAMAV="[11/14] ClamAV Virus Scanner"
MSG_WIZARD_STEP_ROOTKIT="[12/14] Rootkit Detection"
MSG_WIZARD_STEP_SUMMARY="[13/14] Change Summary & Confirmation"
MSG_WIZARD_SKIP_STEP="Skip this step? (y/N)"
MSG_WIZARD_COMPLETE="Wizard complete"
MSG_WIZARD_SKIPPED="Skipped"
MSG_WIZARD_SKIPPED_INIT="Skipping system initialization"
MSG_WIZARD_ERR_INIT="System initialization had errors"
MSG_WIZARD_ERR_INIT_DETAIL="System initialization failed. Subsequent steps (SSH, firewall, etc.) may not work correctly."
MSG_WIZARD_ERR_INIT_PROMPT="Continue anyway? (NOT recommended)"
MSG_WIZARD_ERR_INIT_ABORT="Aborting wizard due to initialization failure"
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
MSG_WIZARD_SKIPPED_SERVICES="Skipping service management"
MSG_WIZARD_ERR_SERVICES="Service management had errors"
MSG_WIZARD_SKIPPED_AUTOUPDATE="Skipping auto security update configuration"
MSG_WIZARD_ERR_AUTOUPDATE="Auto security update configuration had errors"
MSG_WIZARD_SKIPPED_AIDE="Skipping AIDE configuration"
MSG_WIZARD_ERR_AIDE="AIDE configuration had errors"
MSG_WIZARD_SKIPPED_CLAMAV="Skipping ClamAV configuration"
MSG_WIZARD_ERR_CLAMAV="ClamAV configuration had errors"
MSG_WIZARD_SKIPPED_ROOTKIT="Skipping Rootkit detection configuration"
MSG_WIZARD_ERR_ROOTKIT="Rootkit detection configuration had errors"
MSG_WIZARD_STEP_AUTOUPDATE="[9/14] Auto Security Updates"
MSG_WIZARD_ERR_HINT="(some steps had errors, check logs)"

# SSH Key
MSG_SSH_KEY_TITLE="Generate SSH Key Pair"
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

# SSH Port (continued)
MSG_SSH_PORT_UNCHANGED="Port unchanged, skipping"
MSG_SSH_PORT_CANCELLED="Cancelled"
MSG_SSH_PORT_FAIL="Failed to change SSH port"

# SSH Key (continued)
MSG_SSH_KEY_EXISTS="Key already exists: {path}"
MSG_SSH_KEY_OVERWRITE="Overwrite existing key?"
MSG_SSH_KEY_SKIP="Skipping key generation"
MSG_SSH_KEY_GENERATING="Generating Ed25519 key pair..."
MSG_SSH_KEY_ALREADY_AUTHORIZED="Key already in authorized_keys, skipping"
MSG_SSH_KEY_AUTHORIZED_FAIL="Failed to update authorized_keys"

# No SSH key warnings
MSG_SSH_USERS_NO_KEYS="The following users have NO SSH keys (may be locked out if password auth is disabled):"

# Root Login (continued)
MSG_SSH_ROOT_SKIP="Skipping root login disable"
MSG_SSH_ROOT_FAIL="Failed to disable root login"

# Password Login (continued)
MSG_SSH_PASSWD_CONFIGURE_KEYS="Please configure SSH keys first"
MSG_SSH_PASSWD_SKIP="Skipping password auth disable"
MSG_SSH_PASSWD_USERS_NO_KEYS="The following users have NO SSH keys and will be locked out if password auth is disabled:"
MSG_SSH_PASSWD_SETUP_KEYS_HINT="Please set up SSH keys for these users first, or they will be unable to log in."
MSG_SSH_PASSWD_CONTINUE_ANYWAY="Continue anyway? (NOT recommended)"
MSG_SSH_PASSWD_SET_FAIL="Failed to set {param}"

# SSH Params (continued)
MSG_SSH_PARAMS_INVALID="Invalid {param} value ({range}), using default {default}"
MSG_SSH_PARAMS_FAIL="Failed to set {count} SSH parameter(s)"

# Rollback (continued)
MSG_SSH_ROLLBACK_NO_BACKUP="No backup found for rollback"

# Wizard
MSG_SSH_WIZARD_EXTERNAL_MOD="External modification detected: %s"
MSG_SSH_WIZARD_ROLLBACK_OVERWRITE="Overwrite with backup? (y/n)"
MSG_SSH_RESTART_FAIL_ROLLBACK="SSH restart failed, rolling back changes"

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
MSG_FIREWALL_SSH_PORT22_CLOSE="   Close old SSH port 22/tcp: sudo ufw deny 22/tcp (Ubuntu/Debian) or firewall-cmd --remove-service=ssh (CentOS/RHEL)"

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

MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND="Auth log file not found: "
MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND_TAIL=", fail2ban may need journald backend"
MSG_FAIL2BAN_INFO_SSH_PORT="SSH Port: "
MSG_FAIL2BAN_INFO_AUTH_LOG="Auth Log: "
MSG_FAIL2BAN_INFO_CONFIG_FILE="Config File: "
MSG_FAIL2BAN_EPEL_FAILED="epel-release installation failed, continuing anyway..."

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
MSG_AUDIT_RULES_FILE="Rules file"
MSG_AUDIT_CONF_FILE="Config file"

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
MSG_USERS_SSH_KEY_AUTH_ADD_FAILED="Failed to add public key to authorized_keys"
MSG_USERS_SSH_KEY_PERM_FAILED="Failed to set permissions on {path}"
MSG_USERS_SSH_KEY_OWNER_FAILED="Failed to set ownership on {path}"

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
MSG_KERNEL_MODULE_BLACKLISTED="Blacklisted module"
MSG_KERNEL_MODULE_BLACKLIST_FAILED="Failed to blacklist module"
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
MSG_REPORT_WARN_KERNEL="Kernel parameters modified, may affect network/services"
MSG_REPORT_WARN_USERS="New user created, test login before closing current session"
MSG_REPORT_WARN_FS="Filesystem permissions changed, verify critical services still work"
MSG_REPORT_WARN_SERVICES="Some services disabled, verify required services are still running"

# ═══════════════════════════════════════════
# Log
# ═══════════════════════════════════════════

MSG_LOG_BACKUP="Backing up file"
MSG_LOG_RESTORE="Restoring file"
MSG_BACKUP_SUCCESS="Backup successful: %s"
MSG_BACKUP_FAIL="Backup failed: %s"
MSG_RESTORE_SUCCESS="Restored: %s"

# ═══════════════════════════════════════════
# Services Management
# ═══════════════════════════════════════════

MSG_SERVICES_WIZARD_TITLE="Service Management Wizard"
MSG_SERVICES_WIZARD_DESC="Audit running services, disable unnecessary services, scan open ports"

# Service descriptions
MSG_SERVICES_DESC_TELNET="telnet — unencrypted remote access, insecure"
MSG_SERVICES_DESC_RSH="rsh — unencrypted remote access, insecure"
MSG_SERVICES_DESC_RLOGIN="rlogin — unencrypted remote access, insecure"
MSG_SERVICES_DESC_VSFTPD="FTP — unencrypted file transfer, disable unless needed"
MSG_SERVICES_DESC_AVAHI="mDNS/DNS-SD — usually not needed on servers"
MSG_SERVICES_DESC_CUPS="printing service — usually not needed on servers"
MSG_SERVICES_DESC_RPCBIND="RPC port mapper — disable if not needed"

# Wizard steps
MSG_SERVICES_STEP_AUDIT="Step 1: Audit running services"
MSG_SERVICES_STEP_AUDIT_CONFIRM="Show all currently running services?"
MSG_SERVICES_STEP_DISABLE="Step 2: Disable unnecessary services"
MSG_SERVICES_STEP_DISABLE_CONFIRM="Detect and disable unnecessary services?"
MSG_SERVICES_STEP_PORTS="Step 3: Scan open ports"
MSG_SERVICES_STEP_PORTS_CONFIRM="Scan all currently listening ports?"
MSG_SERVICES_STEP_SKIPPED="Skipped this step"

# Audit
MSG_SERVICES_AUDIT_TITLE="Service Audit"
MSG_SERVICES_RUNNING_TITLE="Running services:"
MSG_SERVICES_RUNNING_TOTAL="Total running services"

# Disable services
MSG_SERVICES_UNNECESSARY_TITLE="Unnecessary Service Detection"
MSG_SERVICES_UNNECESSARY_DESC="The following unnecessary services are running:"
MSG_SERVICES_CONFIRM_DISABLE="Confirm disable"
MSG_SERVICES_DISABLING="Disabling service"
MSG_SERVICES_STOP_FAILED="Failed to stop service"
MSG_SERVICES_DISABLE_FAILED="Failed to disable service auto-start"
MSG_SERVICES_DISABLED="Disabled service"
MSG_SERVICES_DISABLE_ERROR="Failed to disable service"
MSG_SERVICES_SKIPPED="Skipped service"
MSG_SERVICES_ALL_CLEAR="No unnecessary running services detected"
MSG_SERVICES_DISABLED_COUNT="Services disabled"

# Port scanning
MSG_SERVICES_PORTS_TITLE="Open Port Scan"
MSG_SERVICES_PORTS_DESC="Currently listening ports:"
MSG_SERVICES_PORTS_TOTAL="Total listening ports"
MSG_SERVICES_PORTS_WARNING="Non-standard ports found"
MSG_SERVICES_PORTS_UNKNOWN="ports need verification"
MSG_SERVICES_PORT_STANDARD="standard port"
MSG_SERVICES_PORT_NONSTANDARD="non-standard port, verify if needed"

# Check list
MSG_SERVICES_CHECK_LIST_TITLE="Checking the following services"

# Summary
MSG_SERVICES_SUMMARY="Service Management Summary"
MSG_SERVICES_SUMMARY_RUNNING="Running services"
MSG_SERVICES_SUMMARY_UNNECESSARY="Remaining unnecessary services"
MSG_SERVICES_WIZARD_DONE="Service management configuration complete"

# ═══════════════════════════════════════════
# NTP Time Sync
# ═══════════════════════════════════════════

MSG_NTP_TITLE="NTP Time Sync"
MSG_NTP_SETTING="Configuring NTP time sync..."
MSG_NTP_DETECTING="Detecting NTP service..."
MSG_NTP_INSTALL_CHRONY="Installing chrony..."
MSG_NTP_INSTALL_NTPD="Installing ntpd..."
MSG_NTP_INSTALL_DONE="NTP service installed"
MSG_NTP_ALREADY_SYNCED="NTP time already synced, skipping installation"
MSG_NTP_CONFIG="Configuring NTP servers..."
MSG_NTP_CONFIG_DONE="NTP configuration complete"
MSG_NTP_SERVICE_START="Starting NTP service..."
MSG_NTP_SERVICE_DONE="NTP service started"
MSG_NTP_STATUS="NTP Time Sync"
MSG_NTP_STATUS_SYNCED="Synced"
MSG_NTP_STATUS_UNSYNCED="Not synced"
MSG_NTP_BACKUP_CONF="Backing up NTP configuration file"
MSG_NTP_TZ_PROMPT="Enter timezone (leave empty for Asia/Shanghai)"
MSG_NTP_TZ_INVALID="Invalid timezone, please re-enter"
MSG_NTP_SYNC_NOW="Syncing time..."
MSG_NTP_SYNC_DONE="Time sync complete"
MSG_NTP_SYNC_FAIL="Time sync failed"

# ═══════════════════════════════════════════
# Swap Configuration
# ═══════════════════════════════════════════

MSG_SWAP_TITLE="Swap Configuration"
MSG_SWAP_CHECKING="Checking swap status..."
MSG_SWAP_EXISTS="Swap already exists"
MSG_SWAP_SIZE="Swap size"
MSG_SWAP_NO_SWAP="No swap configured"
MSG_SWAP_RECOMMENDED="Recommended swap size"
MSG_SWAP_CREATING="Creating swap file..."
MSG_SWAP_CREATE_DONE="Swap file created"
MSG_SWAP_CREATE_FAIL="Swap file creation failed"
MSG_SWAP_ENABLING="Enabling swap..."
MSG_SWAP_ENABLE_DONE="Swap enabled"
MSG_SWAP_ENABLE_FAIL="Swap enable failed"
MSG_SWAP_SWAPPINESS="Setting swappiness"
MSG_SWAP_SWAPPINESS_DONE="swappiness set to 10"
MSG_SWAP_FSTAB_ADD="Adding swap to /etc/fstab"
MSG_SWAP_FSTAB_DONE="Swap added to fstab"
MSG_SWAP_CONFIRM_CREATE="Confirm creating swap file?"
MSG_SWAP_SKIP="Skipping swap configuration"
MSG_SWAP_DONE="Swap configuration complete"

# ═══════════════════════════════════════════
# Errors and Warnings
# ═══════════════════════════════════════════

MSG_ERROR_SCRIPT_NOT_ROOT="This script must be run with root privileges"
MSG_ERROR_FILE_NOT_FOUND="File not found"
MSG_ERROR_RESTORE_FAILED="Restore failed"

MSG_WARN_CONNECTION="Please test new configuration before closing current session"
MSG_WARN_SAVE_KEY="Please make sure you have saved your SSH private key file"
MSG_WARN_TEST_FIRST="Please test new configuration before closing current session"

# ═══════════════════════════════════════════
# SSH Connection Test (Full mode)
# ═══════════════════════════════════════════

MSG_SSH_TEST_CONNECTION="Testing SSH connection..."
MSG_SSH_TEST_PASS="SSH connection test passed (port %s)"
MSG_SSH_TEST_FAIL="SSH connection test failed (port %s) — rollback timer set"
MSG_SSH_TEST_WAITING="Waiting for SSH service to be ready..."
MSG_SSH_TEST_CONFIRM="Please confirm you can connect via SSH on the new port"
MSG_SSH_TEST_INSTRUCTIONS="In another terminal, run: ssh -p %s user@host"

# ═══════════════════════════════════════════
# Completion
# ═══════════════════════════════════════════

MSG_GOODBYE="Goodbye!"

# ═══════════════════════════════════════════
# Auto Security Updates
# ═══════════════════════════════════════════

MSG_AUTOUPDATE_TITLE="Auto Security Updates"
MSG_AUTOUPDATE_START="Starting auto security update configuration..."
MSG_AUTOUPDATE_INSTALL="Installing auto update package..."
MSG_AUTOUPDATE_ALREADY="Auto update tool already installed"
MSG_AUTOUPDATE_INSTALL_DONE="Auto update tool installed"
MSG_AUTOUPDATE_INSTALL_FAILED="Auto update tool installation failed"
MSG_AUTOUPDATE_CONFIGURE="Configuring auto security updates..."
MSG_AUTOUPDATE_CONFIGURE_DONE="Auto security update configuration complete"
MSG_AUTOUPDATE_ENABLE="Enabling auto update service..."
MSG_AUTOUPDATE_ENABLE_DONE="Auto update service enabled"
MSG_AUTOUPDATE_STATUS="Current auto update status"
MSG_AUTOUPDATE_CONFIGURED="Configured"
MSG_AUTOUPDATE_NOT_CONFIGURED="Not configured"
MSG_AUTOUPDATE_SCOPE_PROMPT="Update scope"
MSG_AUTOUPDATE_SCOPE_SECURITY="[1] Security updates only (recommended)"
MSG_AUTOUPDATE_SCOPE_ALL="[2] All updates"
MSG_AUTOUPDATE_REBOOT_PROMPT="Auto reboot policy"
MSG_AUTOUPDATE_REBOOT_NEVER="[1] Never auto reboot"
MSG_AUTOUPDATE_REBOOT_IF_NEEDED="[2] Reboot if needed"
MSG_AUTOUPDATE_DONE="Auto security update configuration complete"
MSG_AUTOUPDATE_TYPE="Update type"
MSG_AUTOUPDATE_SUMMARY_ENABLED="Auto security updates: enabled"
MSG_AUTOUPDATE_SUMMARY_DISABLED="Auto security updates: disabled"

# ═══════════════════════════════════════════
# Task Descriptions (continued)
# ═══════════════════════════════════════════

MSG_TASK_AUTOUPDATE="Auto Security Updates"

# ═══════════════════════════════════════════
# Main menu section separators + SSH port status (spec §3.1 GAP-1/2)
# ═══════════════════════════════════════════

MSG_SECTION_STATUS="────── Status ──────"
MSG_SECTION_HARDENING="────── Hardening (Recommended Order) ──────"
MSG_SECTION_QUICK="────── One-Click ──────"
MSG_SECTION_SERVER="────── Server Software ──────"
MSG_STATUS_SSH_PORT_HARDENED="Hardened"
MSG_STATUS_SSH_PORT_DEFAULT="Not hardened"

# ── Batch 5a: Backup/Rollback Center + Dashboard ──
MSG_SECTION_OPS="────── Operations ──────"
MSG_MAIN_MENU_BACKUP_CENTER="[17] Backup & Rollback Center"
MSG_MAIN_MENU_BACKUP_CENTER_DESC="Browse backups, one-key restore, rollback timer management"
MSG_MAIN_MENU_DASHBOARD="[18] Security Dashboard"
MSG_MAIN_MENU_DASHBOARD_DESC="Multi-module CIS compliance scoring and risk level"
MSG_ERROR_RESTORE_TARGET_REQUIRED="Restore failed: target path missing (no .meta metadata)"
MSG_ERROR_RESTORE_TARGET_NOT_ABSOLUTE="Restore failed: target path must be absolute"
MSG_BACKUP_CENTER_TITLE="Backup & Rollback Center"
MSG_BACKUP_CENTER_MENU_LIST="1. View backup history"
MSG_BACKUP_CENTER_MENU_RESTORE="2. Restore module"
MSG_BACKUP_CENTER_MENU_ROLLBACK="3. SSH rollback timer"
MSG_BACKUP_CENTER_MENU_CLEAN="4. Clean old backups"
MSG_BACKUP_CENTER_MENU_BACK="0. Back to main menu"
MSG_BACKUP_CENTER_HISTORY_TITLE="Backup history (grouped by module)"
MSG_BACKUP_CENTER_NO_BACKUPS="No backups found — nothing hardened yet?"
MSG_BACKUP_CENTER_SELECT_MODULE="Select module to restore"
MSG_BACKUP_CENTER_NO_RESTORABLE="No restorable backups for this module"
MSG_BACKUP_CENTER_CONFIRM_RESTORE="The latest backup of each file below will be restored. This cannot be undone."
MSG_BACKUP_CENTER_CONFIRM_PROMPT="Confirm restore? (y/N)"
MSG_BACKUP_CENTER_RESTORED="Module restored"
MSG_BACKUP_CENTER_RESTORE_ABORTED="Restore cancelled"
MSG_BACKUP_CENTER_RESTORE_SYSCTL="Kernel params restored, reloading sysctl..."
MSG_BACKUP_CENTER_RESTORE_SSH_HINT="SSH config restored. Test the new port connection immediately; if unreachable, check the system."
MSG_BACKUP_CENTER_RESTORE_SYSCTL_SUCCESS="sysctl reloaded"
MSG_BACKUP_CENTER_RESTORE_SYSCTL_FAILED="sysctl --system failed"
MSG_BACKUP_CENTER_RESTORE_MODULE="Restore %s"
MSG_BACKUP_CENTER_MODULE_PROMPT="Enter the module to restore"
MSG_BACKUP_CENTER_RESTORE_FAILED="Restore failed for module %s: one or more files could not be restored"
MSG_BACKUP_CENTER_ROLLBACK_NONE="No SSH rollback timer pending"
MSG_BACKUP_CENTER_ROLLBACK_PENDING="SSH rollback timer pending (PID %s)"
MSG_BACKUP_CENTER_ROLLBACK_CANCEL="Rollback timer cancelled"
MSG_BACKUP_CENTER_ROLLBACK_NO_PID="No rollback timer to cancel"
MSG_BACKUP_CENTER_CLEAN_CONFIRM="Old backups beyond retention will be deleted. Confirm? (y/N)"
MSG_BACKUP_CENTER_CLEAN_DONE="Old backups cleaned"
MSG_BACKUP_CENTER_CLEAN_EMPTY="Nothing to clean"
MSG_DASHBOARD_TITLE="Security Dashboard"
MSG_DASHBOARD_TOTAL="Total"
MSG_DASHBOARD_RISK="Risk"
MSG_DASHBOARD_RISK_LOW="Low"
MSG_DASHBOARD_RISK_MEDIUM="Medium"
MSG_DASHBOARD_RISK_HIGH="High"
MSG_DASHBOARD_RISK_CRITICAL="Critical"

# ═══════════════════════════════════════════
# Status detection: score + color + recommendation (spec §3.3 GAP-4/5/6)
# ═══════════════════════════════════════════

MSG_STATUS_HARDENED="Hardened"
MSG_STATUS_PARTIAL="Partially hardened"
MSG_STATUS_NOT_HARDENED="Not hardened"
MSG_STATUS_NOT_CONFIGURED="Not configured"
MSG_STATUS_RECOMMENDATION="Recommended next step"

# ═══════════════════════════════════════════
# Submenu status fallback hints (M16 fix: i18n)
# ═══════════════════════════════════════════

MSG_HINT_STATUS_FAIL2BAN="Fail2Ban status: see main menu [1] System Status Check"
MSG_HINT_STATUS_AUDIT="Audit status: see main menu [1] System Status Check"
MSG_HINT_STATUS_USERS="User status: see main menu [1] System Status Check"
MSG_HINT_STATUS_KERNEL="Kernel status: see main menu [1] System Status Check"
MSG_HINT_STATUS_FILESYSTEM="Filesystem status: see main menu [1] System Status Check"
MSG_HINT_STATUS_SERVICES="Service status: see main menu [1] System Status Check"
MSG_HINT_STATUS_AUTOUPDATE="Auto update status: see main menu [1] System Status Check"

# ═══════════════════════════════════════════
# Status key completions (remove :- fallbacks in install.sh, spec GAP-8)
# ═══════════════════════════════════════════

MSG_STATUS_USERS="User Management"
MSG_STATUS_USERS_COUNT="Custom users"
MSG_STATUS_KERNEL="Kernel Hardening"
MSG_STATUS_KERNEL_CONF="sysctl config"
MSG_STATUS_FILESYSTEM="Filesystem"
MSG_STATUS_FS_SUID="SUID files"
MSG_STATUS_SERVICES="Service Management"
MSG_STATUS_SERVICES_RUNNING="Running services"
MSG_STATUS_SERVICES_UNNECESSARY="Unnecessary services"

# ═══════════════════════════════════════════
# Module 4-9 submenu shells (4 keys per module, spec §3.2 GAP-3)
# ═══════════════════════════════════════════

MSG_FAIL2BAN_MENU_TITLE="Fail2Ban Intrusion Prevention"
MSG_AUTOUPDATE_MENU_WIZARD="[1] Full hardening wizard"
MSG_AUTOUPDATE_MENU_STATUS="[2] Status only"
MSG_AUTOUPDATE_MENU_BACK="[0] Back to main menu"
MSG_FAIL2BAN_MENU_WIZARD="[1] Full hardening wizard"
MSG_FAIL2BAN_MENU_STATUS="[2] Status only"
MSG_FAIL2BAN_MENU_BACK="[0] Back to main menu"

MSG_AUDIT_MENU_TITLE="Audit Logging"
MSG_AUDIT_MENU_WIZARD="[1] Full hardening wizard"
MSG_AUDIT_MENU_STATUS="[2] Status only"
MSG_AUDIT_MENU_BACK="[0] Back to main menu"

MSG_USERS_MENU_TITLE="User Management"
MSG_USERS_MENU_WIZARD="[1] Full hardening wizard"
MSG_USERS_MENU_STATUS="[2] Status only"
MSG_USERS_MENU_BACK="[0] Back to main menu"

MSG_KERNEL_MENU_TITLE="Kernel Hardening"
MSG_KERNEL_MENU_WIZARD="[1] Full hardening wizard"
MSG_KERNEL_MENU_STATUS="[2] Status only"
MSG_KERNEL_MENU_BACK="[0] Back to main menu"

MSG_FILESYSTEM_MENU_TITLE="Filesystem Security"
MSG_FILESYSTEM_MENU_WIZARD="[1] Full hardening wizard"
MSG_FILESYSTEM_MENU_STATUS="[2] Status only"
MSG_FILESYSTEM_MENU_BACK="[0] Back to main menu"

MSG_SERVICES_MENU_TITLE="Service Management"
MSG_SERVICES_MENU_WIZARD="[1] Full hardening wizard"
MSG_SERVICES_MENU_STATUS="[2] Status only"
MSG_SERVICES_MENU_BACK="[0] Back to main menu"

# ═══════════════════════════════════════════
# view_report history (spec §3.4 GAP-7)
# ═══════════════════════════════════════════

MSG_REPORT_HISTORY_TITLE="Hardening Report History"
MSG_REPORT_NO_FILES="No hardening reports found"
MSG_TIME_JUST_NOW="just now"
MSG_TIME_MINUTES_AGO="%d minutes ago"
MSG_TIME_HOURS_AGO="%d hours ago"
MSG_TIME_DAYS_AGO="%d days ago"

# ═══════════════════════════════════════════
# parse_args error (simplified, spec §3.5 GAP-9)
# ═══════════════════════════════════════════

MSG_ERROR_REMOVED_ARG="Error: --%s has been removed. This script only supports interactive mode."
MSG_ERROR_REMOVED_HINT="Tip: use --status for read-only detection, or no argument for interactive menu."

# ═══════════════════════════════════════════
# Mode (Lite/Full)
# ═══════════════════════════════════════════

MSG_MODE_LITE="Lite Mode"
MSG_MODE_FULL="Full Mode"
MSG_MODE_CURRENT="Current Mode"
MSG_MODE_LITE_TAG="[Lite]"
MSG_MODE_FULL_TAG="[Full]"
MSG_MODE_LITE_DESC="Core security only, optimized for low-memory servers"
MSG_MODE_FULL_DESC="All security hardening features"
MSG_MODE_FULL_ONLY="[Full mode only]"
MSG_ERROR_LITE_MODE="This feature is only available in Full mode. Re-run without --lite to enable."

# ═══════════════════════════════════════════
# Hardening Mode Selection (Batch 4)
# ═══════════════════════════════════════════

MSG_MODE_SELECT_TITLE="Select Hardening Mode"
MSG_MODE_SELECT_DESC="Choose the hardening level for your needs"
MSG_MODE_BASIC="Basic Hardening"
MSG_MODE_BASIC_DESC="SSH + Firewall + Kernel + System Init"
MSG_MODE_BASIC_TIP="Quick deploy, minimal impact"
MSG_MODE_STANDARD="Standard Hardening"
MSG_MODE_STANDARD_DESC="Basic + Fail2Ban + User Management"
MSG_MODE_STANDARD_TIP="Recommended for most servers"
MSG_MODE_ADVANCED="Advanced Hardening"
MSG_MODE_ADVANCED_DESC="Standard + Audit + Services + Filesystem"
MSG_MODE_ADVANCED_TIP="For high-security environments"
MSG_MODE_CUSTOM="Custom"
MSG_MODE_CUSTOM_DESC="Full control, pick each item"
MSG_MODE_CUSTOM_TIP="For users with specific needs"
MSG_MODE_SELECT_PROMPT="Enter option [1-4] (default: 4)"
MSG_MODE_WIZARD_BASIC="Basic Hardening Wizard"
MSG_MODE_WIZARD_STANDARD="Standard Hardening Wizard"
MSG_MODE_WIZARD_ADVANCED="Advanced Hardening Wizard"

# ═══════════════════════════════════════════
# SSH Safety Enhancement (Batch 4)
# ═══════════════════════════════════════════

MSG_SSH_SESSION_ACTIVE="Active SSH sessions detected"
MSG_SSH_SESSION_NONE="Warning: No active SSH sessions detected! Run from an SSH connection to avoid lockout"
MSG_SSH_CONSOLE_AVAILABLE="Backup console access detected"
MSG_SSH_CONSOLE_NONE="Warning: No backup console access detected"
MSG_SSH_ROLLBACK_CONFIRM_PROMPT="Continue?"
MSG_STATUS_NA_LITE="N/A (not included in Lite mode)"
MSG_HELP_LITE="  --lite          Lite mode: core security only (SSH/firewall/kernel)"

# ═══════════════════════════════════════════
# Command-line help text (M17 fix: i18n)
# ═══════════════════════════════════════════

MSG_HELP_USAGE="Usage: bash install.sh [options]"
MSG_HELP_OPTIONS="Options:"
MSG_HELP_STATUS="  --status       Show system security status (read-only)"
MSG_HELP_HELP="  --help, -h     Show this help"
MSG_HELP_NO_ARGS="No arguments: interactive menu."
MSG_HELP_EXAMPLES="Examples:"
MSG_HELP_EXAMPLE_INTERACTIVE="  bash install.sh                      # Interactive menu"
MSG_HELP_EXAMPLE_STATUS="  bash install.sh --status             # Status check only"
MSG_HELP_EXAMPLE_CURL="  curl -fsSL .../install.sh | sudo bash"
MSG_ERROR_UNKNOWN_ARG="Error: Unknown argument: %s"
MSG_ERROR_USE_HELP="Use --help for available options"

# ═══════════════════════════════════════════
# AIDE Intrusion Detection
# ═══════════════════════════════════════════

MSG_AIDE_WIZARD_TITLE="AIDE Intrusion Detection Wizard"
MSG_AIDE_WIZARD_DESC="File integrity checking system using AIDE (Advanced Intrusion Detection Environment)"
MSG_AIDE_WIZARD_START="Start AIDE configuration?"
MSG_AIDE_WIZARD_SKIPPED="Skipping AIDE configuration"
MSG_AIDE_WIZARD_DONE="AIDE configuration complete"
MSG_AIDE_INSTALL="Installing AIDE..."
MSG_AIDE_INSTALL_DONE="AIDE installed"
MSG_AIDE_ALREADY_INSTALLED="AIDE already installed"
MSG_AIDE_UNSUPPORTED_OS="Unsupported OS for AIDE"
MSG_AIDE_BACKUP="Backing up AIDE config"
MSG_AIDE_CONFIGURE="Configuring AIDE..."
MSG_AIDE_CONFIGURE_DONE="AIDE configured"
MSG_AIDE_INIT_DB="Initializing AIDE database..."
MSG_AIDE_INIT_DB_DONE="AIDE database initialized"
MSG_AIDE_INIT_DB_WARN="AIDE database initialization may take 5-30 minutes on large servers"
MSG_AIDE_INIT_DB_SKIP="Skipping AIDE database initialization"
MSG_AIDE_INIT_DB_EXISTS="AIDE database already exists"
MSG_AIDE_INIT_DB_REINIT="Reinitialize AIDE database? (will overwrite existing)"
MSG_AIDE_DB_STATUS="Database status"
MSG_AIDE_DB_AGE="Database age"
MSG_AIDE_CRON_SETUP="Setting up daily AIDE check cron"
MSG_AIDE_CRON_DONE="Daily AIDE cron setup done"
MSG_AIDE_CRON_EXISTS="Daily AIDE cron already exists"
MSG_AIDE_CRON_SKIP="Skipping AIDE cron setup"
MSG_AIDE_STATUS="AIDE Status"
MSG_AIDE_NOT_INSTALLED="AIDE not installed"
MSG_AIDE_SUMMARY="AIDE Configuration Summary"
MSG_AIDE_TIPS_TITLE="AIDE management commands:"
MSG_AIDE_TIPS_1="Check integrity: aide --check"
MSG_AIDE_TIPS_2="Update database: aide --update"
MSG_AIDE_TIPS_3="View report: cat /var/log/aide/check-*.log"
MSG_AIDE_TIPS_4="Reinit database: aideinit --init or aide --init"
MSG_AIDE_MENU_TITLE="AIDE Intrusion Detection"
MSG_AIDE_MENU_WIZARD="[1] Full hardening wizard"
MSG_AIDE_MENU_STATUS="[2] Status only"
MSG_AIDE_MENU_BACK="[0] Back to main menu"
MSG_HINT_STATUS_AIDE="AIDE status: see main menu [1] System Status Check"
MSG_STATUS_AIDE="AIDE"
MSG_REPORT_WARN_AIDE="AIDE database initialized. Run aide --check regularly to verify file integrity."
MSG_TASK_AIDE="AIDE Intrusion Detection"

# ═══════════════════════════════════════════
# ClamAV Virus Scanner
# ═══════════════════════════════════════════

MSG_CLAMAV_WIZARD_TITLE="ClamAV Virus Scanner Wizard"
MSG_CLAMAV_WIZARD_DESC="Open-source antivirus with freshclam and on-demand scanning"
MSG_CLAMAV_WIZARD_START="Start ClamAV configuration?"
MSG_CLAMAV_WIZARD_SKIPPED="Skipping ClamAV configuration"
MSG_CLAMAV_WIZARD_DONE="ClamAV configuration complete"
MSG_CLAMAV_INSTALL="Installing ClamAV..."
MSG_CLAMAV_INSTALL_DONE="ClamAV installed"
MSG_CLAMAV_ALREADY_INSTALLED="ClamAV already installed"
MSG_CLAMAV_UNSUPPORTED_OS="Unsupported OS for ClamAV"
MSG_CLAMAV_MEMORY_WARN="Warning: ClamAV freshclam may use ~200-300MB during virus database updates"
MSG_CLAMAV_MEMORY_CONFIRM="Continue despite memory usage during updates?"
MSG_CLAMAV_CONFIGURE="Configuring freshclam..."
MSG_CLAMAV_CONFIGURE_DONE="freshclam configured"
MSG_CLAMAV_FRESHCLAM_CRON="Setting up hourly freshclam cron"
MSG_CLAMAV_FRESHCLAM_CRON_DONE="Freshclam cron setup done"
MSG_CLAMAV_FRESHCLAM_NOW="Running initial virus database update..."
MSG_CLAMAV_FRESHCLAM_NOW_DONE="Virus database updated"
MSG_CLAMAV_FRESHCLAM_NOW_WARN="Freshclam update may take a while (~100MB download)"
MSG_CLAMAV_SCAN_CRON_PROMPT="Set up daily scan cron? (default: skip)"
MSG_CLAMAV_SCAN_CRON_SETUP="Setting up daily scan cron..."
MSG_CLAMAV_SCAN_CRON_DONE="Daily scan cron setup done"
MSG_CLAMAV_SCAN_CRON_SKIP="Skipping daily scan cron"
MSG_CLAMAV_RUN_SCAN="Running on-demand virus scan..."
MSG_CLAMAV_SCAN_DONE="Virus scan complete"
MSG_CLAMAV_SCAN_FOUND="Threats found! Check quarantine and scan log"
MSG_CLAMAV_SCAN_CLEAN="No threats found"
MSG_CLAMAV_STATUS="ClamAV Status"
MSG_CLAMAV_DB_STATUS="Virus database"
MSG_CLAMAV_DB_UPTODATE="Up to date"
MSG_CLAMAV_DB_OUTDATED="Out of date (older than 7 days)"
MSG_CLAMAV_LAST_SCAN="Last scan"
MSG_CLAMAV_NOT_INSTALLED="Not installed"
MSG_CLAMAV_SUMMARY="ClamAV Configuration Summary"
MSG_CLAMAV_TIPS_TITLE="ClamAV management commands:"
MSG_CLAMAV_TIPS_1="Update virus definitions: freshclam"
MSG_CLAMAV_TIPS_2="Scan a file: clamscan <file>"
MSG_CLAMAV_TIPS_3="Scan a directory: clamscan -r <dir>"
MSG_CLAMAV_TIPS_4="Quarantine file: mv <file> /var/quarantine/"
MSG_CLAMAV_MENU_TITLE="ClamAV Virus Scanner"
MSG_CLAMAV_MENU_WIZARD="[1] Full hardening wizard"
MSG_CLAMAV_MENU_STATUS="[2] Status only"
MSG_CLAMAV_MENU_BACK="[0] Back to main menu"
MSG_HINT_STATUS_CLAMAV="ClamAV status: see main menu [1] System Status Check"
MSG_STATUS_CLAMAV="ClamAV"
MSG_REPORT_WARN_CLAMAV="ClamAV installed. Keep virus definitions updated with freshclam."
MSG_TASK_CLAMAV="ClamAV Virus Scanner"

# ClamAV clamd daemon
MSG_CLAMAV_CLAMD_PROMPT="Enable ClamAV daemon (clamd) for real-time protection? (Requires ~300MB additional RAM)"
MSG_CLAMAV_CLAMD_SKIPPED="Skipped clamd installation"
MSG_CLAMAV_CLAMD_INSTALL="Installing clamd daemon..."
MSG_CLAMAV_CLAMD_INSTALL_DONE="Clamd installation complete"
MSG_CLAMAV_CLAMD_ALREADY="Clamd already installed"
MSG_CLAMAV_CLAMD_CONFIGURE="Configuring clamd..."
MSG_CLAMAV_CLAMD_CONFIGURE_DONE="Clamd configured"
MSG_CLAMAV_CLAMD_ENABLE="Starting clamd service..."
MSG_CLAMAV_CLAMD_ENABLE_DONE="Clamd service started"
MSG_CLAMAV_CLAMD_DISABLE="Stopping clamd service..."
MSG_CLAMAV_CLAMD_DISABLE_DONE="Clamd service stopped"
MSG_CLAMAV_CLAMD_DISABLED="Clamd not enabled"
MSG_STATUS_CLAMD="Clamd Status"

# ═══════════════════════════════════════════
# Rootkit Detection
# ═══════════════════════════════════════════

MSG_ROOTKIT_WIZARD_TITLE="Rootkit Detection Wizard"
MSG_ROOTKIT_WIZARD_DESC="Detect rootkits and backdoors using rkhunter and chkrootkit"
MSG_ROOTKIT_WIZARD_START="Start rootkit detection configuration?"
MSG_ROOTKIT_WIZARD_SKIPPED="Skipping rootkit detection configuration"
MSG_ROOTKIT_WIZARD_DONE="Rootkit detection configuration complete"
MSG_ROOTKIT_INSTALL_RKHUNTER="Installing rkhunter..."
MSG_ROOTKIT_INSTALL_RKHUNTER_DONE="rkhunter installed"
MSG_ROOTKIT_RKHUNTER_ALREADY="rkhunter already installed"
MSG_ROOTKIT_INSTALL_CHKROOTKIT="Installing chkrootkit..."
MSG_ROOTKIT_INSTALL_CHKROOTKIT_DONE="chkrootkit installed"
MSG_ROOTKIT_CHKROOTKIT_ALREADY="chkrootkit already installed"
MSG_ROOTKIT_CHKROOTKIT_UNAVAIL="chkrootkit not available on this distro, continuing with rkhunter only"
MSG_ROOTKIT_UNSUPPORTED_OS="Unsupported OS for Rootkit detection"
MSG_ROOTKIT_CONFIGURE="Configuring rkhunter..."
MSG_ROOTKIT_CONFIGURE_DONE="rkhunter configured"
MSG_ROOTKIT_PROPUPD="Updating rkhunter file properties database..."
MSG_ROOTKIT_PROPUPD_DONE="rkhunter file properties updated"
MSG_ROOTKIT_RUN_SCAN="Running rootkit scan"
MSG_ROOTKIT_SCAN_RUNNING="Rootkit scan in progress (may take 10-30 minutes)..."
MSG_ROOTKIT_SCAN_DONE="Rootkit scan complete"
MSG_ROOTKIT_SCAN_FOUND="Rootkit warnings found! Review /var/log/rkhunter/rkhunter.log"
MSG_ROOTKIT_SCAN_CLEAN="No rootkit warnings found"
MSG_ROOTKIT_CRON_SETUP="Setting up weekly rkhunter cron"
MSG_ROOTKIT_CRON_DONE="Weekly rkhunter cron setup done"
MSG_ROOTKIT_CRON_EXISTS="Weekly rkhunter cron already exists"
MSG_ROOTKIT_CRON_SKIP="Skipping weekly rkhunter cron"
MSG_ROOTKIT_STATUS="Rootkit Detection Status"
MSG_ROOTKIT_LAST_SCAN="Last scan"
MSG_ROOTKIT_NOT_INSTALLED="Not installed"
MSG_ROOTKIT_SUMMARY="Rootkit Detection Summary"
MSG_ROOTKIT_TIPS_TITLE="Rootkit detection management commands:"
MSG_ROOTKIT_TIPS_1="Run rkhunter scan: rkhunter --check --skip-keypress"
MSG_ROOTKIT_TIPS_2="Update file properties after updates: rkhunter --propupd"
MSG_ROOTKIT_TIPS_3="Run chkrootkit scan: chkrootkit"
MSG_ROOTKIT_TIPS_4="View rkhunter log: cat /var/log/rkhunter/rkhunter.log"
MSG_ROOTKIT_MENU_TITLE="Rootkit Detection"
MSG_ROOTKIT_MENU_WIZARD="[1] Full hardening wizard"
MSG_ROOTKIT_MENU_STATUS="[2] Status only"
MSG_ROOTKIT_MENU_BACK="[0] Back to main menu"
MSG_HINT_STATUS_ROOTKIT="Rootkit status: see main menu [1] System Status Check"
MSG_STATUS_ROOTKIT="Rootkit Detection"
MSG_REPORT_WARN_ROOTKIT="Rootkit detection tools installed. Run rkhunter --check weekly."
MSG_TASK_ROOTKIT="Rootkit Detection"
