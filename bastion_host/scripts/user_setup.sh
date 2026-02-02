#!/bin/bash
# Install required packages
dnf update -y
dnf install -y curl git jq lsof nmap nmap-ncat postgresql17 rsync strace sudo tcpdump tmux traceroute vim wget zsh

# Install SSM Agent for Amazon Linux 2023
dnf install -y amazon-ssm-agent

# Setup users and groups from terraform variables
user_groups='${user_groups}'

echo "$user_groups" | jq -r 'to_entries[] | .key as $group | .value as $groupinfo | .value.users[] | [$group, .username, $groupinfo.sudo_access] | @tsv' | while IFS=$'\t' read -r group user sudo_access; do
    # Create group if it doesn't exist
    if ! getent group "$group" > /dev/null; then
        groupadd "$group"
    fi

    # Create user if it doesn't exist
    if ! id "$user" &>/dev/null; then
        useradd -m -g "$group" "$user"

        # Create and configure user's home directory
        user_home="/home/$user"
        mkdir -p "$user_home"

        # Create .bashrc with custom configuration
        cat > "$user_home/.bashrc" << 'EOFBASHRC'
# .bashrc
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH

alias ll='ls -la'
alias h='history'
EOFBASHRC

        # Create .bash_profile
        cat > "$user_home/.bash_profile" << 'EOFPROFILE'
# .bash_profile
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export PS1="[\u@\h \W]\$ "
EOFPROFILE

        # Generate a random password
        password=$(openssl rand -base64 12)
        echo "$user:$password" | chpasswd

        # Set proper ownership and permissions
        chown -R "$user:$group" "$user_home"
        chmod 700 "$user_home"
        chmod 600 "$user_home/.bash_profile" "$user_home/.bashrc"
    fi

    # Set up sudo access if enabled
    if [[ "$sudo_access" == "true" ]]; then
        echo "$user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$user"
        chmod 0440 "/etc/sudoers.d/$user"
    fi
done

# Configure SSM Agent
mkdir -p /etc/amazon/ssm
cat > /etc/amazon/ssm/amazon-ssm-agent.json << 'EOFSSM'
{
    "Agent": {
        "Telemetry": {
            "Disabled": false
        }
    },
    "Mds": {
        "CommandWorkersLimit": 5
    },
    "SessionManager": {
        "Enabled": true,
        "RunAsEnabled": true,
        "RunAsDefaultUser": "ssm-user"
    },
    "Ssm": {
        "Hints": {
            "RebootCmdLine": "shutdown -r +1",
            "ShutdownCmdLine": "shutdown +1"
        }
    }
}
EOFSSM

chown root:root /etc/amazon/ssm/amazon-ssm-agent.json
chmod 600 /etc/amazon/ssm/amazon-ssm-agent.json

# Start SSM Agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
