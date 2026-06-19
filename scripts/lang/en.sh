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

MSG_FW_START="Starting firewall configuration..."
MSG_FW_COMING_SOON="Firewall feature coming soon, will be implemented in v0.2"

# ═══════════════════════════════════════════
# Fail2Ban
# ═══════════════════════════════════════════

MSG_F2B_START="Starting Fail2Ban configuration..."
MSG_F2B_COMING_SOON="Fail2Ban feature coming soon, will be implemented in v0.2"

# ═══════════════════════════════════════════
# User Management
# ═══════════════════════════════════════════

MSG_USER_START="Starting user management..."
MSG_USER_COMING_SOON="User management feature coming soon, will be implemented in v0.3"

# ═══════════════════════════════════════════
# Kernel Hardening
# ═══════════════════════════════════════════

MSG_KERNEL_START="Starting kernel security hardening..."
MSG_KERNEL_COMING_SOON="Kernel hardening feature coming soon, will be implemented in v0.3"

# ═══════════════════════════════════════════
# Report
# ═══════════════════════════════════════════

MSG_REPORT_TITLE="Security Hardening Completion Report"
MSG_REPORT_SYSTEM="System Information"
MSG_REPORT_TASKS="Completed Tasks"
MSG_REPORT_CONFIGS="Modified Configuration Files"
MSG_REPORT_WARNINGS="Important Reminders"
MSG_REPORT_SAVED="Report saved to"

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
