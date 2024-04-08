#!/usr/bin/zsh

V_NODE="20.11.1"
V_PROJECT_NAME="ng-base-project"
V_ANGULAR_VERSION="17.3.3"

check_nvm() {
    echo "Check if NVM is sourced successfully"
    echo "Enforce Node.js version to $V_NODE"
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    # Check if NVM is sourced
    if [ -f "$NVM_SCRIPT" ]; then
        . "$NVM_SCRIPT"

        # Check if Node.js version $V_NODE is installed
        if nvm ls $V_NODE &> /dev/null; then
            echo "Node.js version $V_NODE is installed."
        else
            echo "Node.js version $V_NODE is not installed."
            echo "Installing Node.js version $V_NODE..."
            nvm install $V_NODE
        fi

        # Use Node.js version $V_NODE
        echo "Enforcing Node.js version $V_NODE"
        nvm use $V_NODE

    else
        echo "NVM not found or failed to load. Please make sure it's installed and sourced properly."
        echo "Please refer to https://github.com/nvm-sh/nvm for further instructions."
        echo "Exiting..."
        exit 1
    fi
    echo "Node.js Environment setup completed."
}

# Function to get the installed Angular CLI version
get_angular_cli_version() {
    ng version | grep -oP '(?<=Angular CLI: )(\d+\.\d+\.\d+)'  # Extracts only the version number
}

# Function to install Angular CLI
install_angular_cli() {
    npm install -g "@angular/cli@$desired_version"
}

install_tools() {
    echo "Install tools"
    current_angular_version=$(get_angular_cli_version)
    echo "Current Angular CLI version: $current_angular_version"
    echo "Required Angular CLI version: $V_ANGULAR_VERSION"
    if [ "$current_version" = "$desired_version" ]; then
        echo "Angular CLI version $desired_version is already installed."
    else
        echo "Installing Angular CLI version $desired_version..."
        install_angular_cli
        echo "Angular CLI version $desired_version installed successfully."
    fi
}

create_full_project() {
    # create the angular base project with create-application=true
    echo "Create the angular base project with create-application=true"
    sudo rm -Rf $V_PROJECT_NAME
    ng new $V_PROJECT_NAME
}

create_lib_project() {
    # create the angular base project with create-application=false
    echo "Create the angular base project with create-application=false"
    sudo rm -Rf $V_PROJECT_NAME
    ng new $V_PROJECT_NAME --create-application=false
    cd $V_PROJECT_NAME
}

echo "*****************************"
echo "Initialise environment"
echo "*****************************"

if [ "$#" -eq 0 ]; then
    echo "Error: No argument provided. Please provide 'full' or 'for-lib'."
    exit 1
fi

echo "First arg: $1"

check_nvm
install_tools


if [ "$1" = "full" ]; then
    create_full_project
fi

if [ "$1" = "for-lib" ]; then
    create_lib_project
fi