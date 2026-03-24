#!/bin/bash
# Install required packages
dnf update -y
dnf install -y git lsof nmap nmap-ncat postgresql17 rsync strace tcpdump tmux traceroute vim wget zsh openssh-server redis6

# Enable and start SSH daemon
systemctl enable sshd
systemctl start sshd

# Setup users and groups from terraform variables
user_groups='${user_groups}'

echo "$user_groups" | jq -r 'to_entries[] | .key as $group | .value as $groupinfo | .value.users[] | [$group, .username, $groupinfo.sudo_access, .public_key] | @tsv' | while IFS=$'\t' read -r group user sudo_access public_key; do
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

        # Create .ssh directory for SSH key authentication
        mkdir -p "$user_home/.ssh"
        echo "$public_key" > "$user_home/.ssh/authorized_keys"
        chmod 700 "$user_home/.ssh"
        chmod 600 "$user_home/.ssh/authorized_keys"

        # Generate a random password
        password=$(openssl rand -base64 12)
        echo "$user:$password" | chpasswd

        # Set proper ownership and permissions
        chown -R "$user:$group" "$user_home"
        chmod 700 "$user_home"
        chmod 600 "$user_home/.bash_profile" "$user_home/.bashrc"
    fi

done

# Set up sudo access for groups with sudo_access enabled
echo "$user_groups" | jq -r 'to_entries[] | select(.value.sudo_access == true) | .key' | while read -r group; do
    echo "%$group ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$group"
    chmod 0440 "/etc/sudoers.d/$group"
done
