#!/bin/bash

USER=$(who -m | awk '{print $1}')
ascii_art () {
        clear
        echo -e '
           _____ ____  _   _ _____   ____ _______   _____ _   _  _____ _______       _      _      ______ _____
          / ____/ __ \| \ | |  __ \ / __ \__   __| |_   _| \ | |/ ____|__   __|/\   | |    | |    |  ____|  __ \
         | |   | |  | |  \| | |__) | |  | | | |      | | |  \| | (___    | |  /  \  | |    | |    | |__  | |__) |
         | |   | |  | | . ` |  ___/| |  | | | |      | | | . ` |\___ \   | | / /\ \ | |    | |    |  __| |  _  /
         | |___| |__| | |\  | |    | |__| | | |     _| |_| |\  |____) |  | |/ ____ \| |____| |____| |____| | \ \
          \_____\____/|_| \_|_|     \____/  |_|    |_____|_| \_|_____/   |_/_/    \_\______|______|______|_|  \_\
        version v0.4\n'
}
check_sudo () {
        ascii_art
        if [ "$EUID" -ne 0 ]
                then echo "Please run the script as sudo"
                exit
        fi
}
git_clone () {
        ascii_art
        echo "Cloning the Conpot repository"
        echo "https://github.com/mushorg/conpot.git"
        git clone --quiet https://github.com/mushorg/conpot.git > /dev/null
}
install_modules () {
        ascii_art
        echo "Installing multiple python3 libraries"
        cd conpot/
        echo "Installing python3-pip"
        sudo apt install python3-pip -y &>/dev/null
        echo "Installing required python3 libraries"
        sudo pip3 install -r requirements.txt &>/dev/null
        echo "Installing python3 library Sphinx"
        sudo pip3 install sphinx &>/dev/null
        echo "Installing Conpot"
        sudo python3 setup.py install &>/dev/null
}
change_rights () {
        ascii_art
        echo "Changing the rights of multple directories and files"
        echo "Creating conpot directory inside /tmp"
        mkdir -p /tmp/conpot
        echo "Changing rights of the conpot tmp directory"
        sudo chmod 777 /tmp/conpot
        echo "Adding user to the group staff"
        sudo usermod -aG staff $USER
        echo "Adding user to the group sudo"
        sudo usermod -aG sudo $USER
        echo "Changing rights of the python dist-packages directory"
        sudo chmod -R 775 /usr/local/lib/python3.8/dist-packages/
}
make_service () {
        ascii_art
        echo "Creating a Conpot service in systemd"
        sudo touch /etc/systemd/system/conpot.service
        echo "Inserting the service configuration to the Conpot.service file"
        sudo tee /etc/systemd/system/conpot.service << EOF &> /dev/null
[Unit]
Description=Conpot Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
EnvironmentFile=-/tmp/conpot.env
ExecStartPre=sh -c 'echo date=\$(date +%%Y_%%m_%%d-%%H:%%M) > /tmp/conpot.env'
ExecStart=conpot -f --template default --temp_dir /tmp/conpot --logfile /home/$USER/conpot_\${date}.log

[Install]
WantedBy=multi-user.target
EOF
}
finish_installation () {
        ascii_art
        echo "Restarting the daemon"
        sudo systemctl daemon-reload
        echo "Start the Conpot service using the command:"
        echo "  sudo systemctl start conpot"
}

#Check if the script has been executed as sudo
check_sudo
#Change directory to user home directory
cd /home/"$USER"

#Check if there is a conpot directory
if [ -d "conpot" ]
then
        echo "There is already a Conpot directory..."
        read -p "Do you want to remove the current Conpot directory or keep it? (R/K) " kr

        case $kr in
                [kK] ) echo Ok, the directory will be kept.;
                        install_modules
                        change_rights
                        make_service
                        finish_installation
                        exit;;
                [rR] ) echo Removing the Conpot directory;
                        sudo rm -rf conpot
                        git_clone
                        install_modules
                        change_rights
                        make_service
                        finish_installation
                        exit;;
                * ) echo invalid response;;
        esac
else
        echo "Starting the installation..."
        git_clone
        install_modules
        change_rights
        make_service
        finish_installation
fi
