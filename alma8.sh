#!/bin/bash

################################################################################################################################################
#### INSTALL SOME DEPENDENCIES:) #### -------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

echo "Updating and upgrading packages..."
sudo dnf update -y
sudo dnf upgrade -y

echo "Enabling CRB..."
/usr/bin/crb enable  # Enable CodeReady Builder

echo "Installing EPEL and other utilities..."
yum -y install epel-release
yum -y install terminator
yum -y install expect
yum -y install curl
yum -y install wget
yum -y install git
yum -y install jq

################################################################################################################################################
#### INSTALL VNC SERVER #### ----------------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

echo "Installing GUI and TigerVNC..."
sudo dnf groupinstall "Server with GUI" -y
sudo dnf install tigervnc-server -y

echo "Creating .vnc directory..."
mkdir -p ~/.vnc/

# Use xstartup instead of config, more reliable
content=$(cat <<END
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec /etc/X11/xinit/xinitrc
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
startxfce4 &
END
)

echo "$content" > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# Create a new user 'admin' with a predefined password
echo "Adding user 'admin'..."
sudo adduser admin
echo "admin:Money22" | sudo chpasswd  # Set the password for 'admin'

# Grant the 'admin' user passwordless sudo access for specific commands
echo "Granting 'admin' passwordless sudo..."
echo "admin ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/admin_no_password
sudo chmod 440 /etc/sudoers.d/admin_no_password
sudo visudo -c  # Check syntax of sudoers files

# Switch to the 'admin' user environment to configure VNC
echo "Configuring VNC for user 'admin'..."
sudo -i -u admin bash <<'EOF'

# Ensure .vnc directory exists
mkdir -p ~/.vnc

# Set the VNC password directly
echo "Money22" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Create a systemd service for the VNC server
cat <<SERVICE_EOF | sudo tee /etc/systemd/system/vncserver@:1.service >/dev/null
[Unit]
Description=Remote desktop (VNC) service
After=syslog.target network.target

[Service]
Type=forking
User=admin
WorkingDirectory=/home/admin

PIDFile=/home/admin/.vnc/%H:%i.pid
ExecStart=/usr/bin/vncserver :1 -geometry 1280x800
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
SERVICE_EOF

####### Enable VNC to start on reboot #######
sudo systemctl daemon-reload
sudo systemctl enable vncserver@:1.service
EOF

echo "Reloading systemd and enabling VNC..."
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service

# Configure the firewall to allow VNC
echo "Configuring firewall..."
sudo firewall-cmd --permanent --add-service=vnc-server
sudo firewall-cmd --reload

################################################################################################################################################
#### FINAL SETUP MESSAGE TO TG #### ---------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

echo "VNC server installed and configured.  Connect to port 5901 (display :1)."

################################################################################################################################################
#### INSTALL SOME SOFTWARE #### -------------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

###### CCRYPT INSTALL ######
echo "Installing ccrypt..."
wget https://ccrypt.sourceforge.net/download/1.11/ccrypt-1.11-1.x86_64.rpm
sudo rpm -Uvh ccrypt-1.11-1.x86_64.rpm

rm -f ccrypt-1.11-1.x86_64.rpm

###### SUBLIME TEXT ######
echo "Installing Sublime Text..."
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install sublime-text -y

###### LIBRE OFFICE ######
#yum install -y libreoffice

###### GEANY ######
#sudo dnf install geany -y

###### GOOGLE CHROME ######
echo "Installing Google Chrome..."
sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

###### VSCODE ######
#sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
#sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
#sudo dnf install code -y

####### INSTALL SPEEDTEST #######
echo "Installing Speedtest CLI..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
sudo yum -y install speedtest

#mdkir /root/vscode

################################################################################################################################################
#### DELETE ALL SCRIPTS AND CLEAN UP  #### --------------------------------------------------------------------------------------------- #######
################################################################################################################################################

echo "Cleaning up..."
rm -rf /root/vnc

echo "Script completed."
