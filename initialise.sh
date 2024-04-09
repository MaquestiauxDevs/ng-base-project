#!/usr/bin/zsh

clear

V_NODE="20.11.1"
V_PROJECT_NAME="my-ng-base-project"
V_ANGULAR_VERSION="17.3.3"

check_nvm() {
    echo ">>Check if NVM is sourced successfully"
    echo ">>>Enforce Node.js version to $V_NODE"
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    # Check if NVM is sourced
    if [ -f "$NVM_SCRIPT" ]; then
        . "$NVM_SCRIPT"

        # Check if Node.js version $V_NODE is installed
        if nvm ls $V_NODE &> /dev/null; then
            echo ">>>>Node.js version $V_NODE is installed."
        else
            echo ">>>>Node.js version $V_NODE is not installed."
            echo ">>>>Installing Node.js version $V_NODE..."
            nvm install $V_NODE
        fi

        # Use Node.js version $V_NODE
        echo ">>>Enforcing Node.js version $V_NODE"
        nvm use $V_NODE

    else
        echo ">>>NVM not found or failed to load. Please make sure it's installed and sourced properly."
        echo ">>>Please refer to https://github.com/nvm-sh/nvm for further instructions."
        echo ">>>Exiting..."
        exit 1
    fi
    echo ">>>Node.js Environment setup completed."
}

# Function to get the installed Angular CLI version
get_angular_cli_version() {
    ng version | grep -oP '(?<=Angular CLI: )(\d+\.\d+\.\d+)'  # Extracts only the version number
}

# Function to install Angular CLI
install_angular_cli() {
    npm install --global --silent "@angular/cli@$desired_version"
}

install_tools() {
    echo ">>Install tools"
    current_angular_version=$(get_angular_cli_version)
    echo ">>>Current Angular CLI version: $current_angular_version"
    echo ">>>Required Angular CLI version: $V_ANGULAR_VERSION"
    if [ "$current_version" = "$desired_version" ]; then
        echo ">>>Angular CLI version $desired_version is already installed."
    else
        echo ">>>Installing Angular CLI version $desired_version..."
        install_angular_cli
        echo ">>>Angular CLI version $desired_version installed successfully."
    fi
}

copy_extra_files() {
    echo ">>Post creation steps"
    echo ">>>Copying project files: LICENSE, CODE_OF_CONDUCT.md, CONTRIBUTING.md, README.md"
    cp ../sources/LICENSE ./LICENSE
    cp ../sources/CODE_OF_CONDUCT.md ./CODE_OF_CONDUCT.md
    cp ../sources/CONTRIBUTING.md ./CONTRIBUTING.md
    cp ../sources/README.md ./README.md    
    echo ">>>Project files copied successfully."

    echo ">>>Creating an empty CHANGELOG.md file"
    touch ./CHANGELOG.md
    echo ">>>Change log file created successfully."
}

finalise_lib_project() {
    echo " "
    echo ">>Finalizing..."
    npm run format:check:lib
    npm run format:write:lib
    npm run format:lint:lib

    npm run format:check:showcase
    npm run format:write:showcase
    npm run format:lint:showcase
}

create_lib_project() {
    echo ">>Creating library project"

    library_name="$V_PROJECT_NAME-lib"
    showcase_name="$V_PROJECT_NAME-showcase"

    # create the angular base project with create-application=false
    echo ">>>Create the angular base project with create-application=false"
    # Remove the existing project directory if it exists
    if [ -d "$V_PROJECT_NAME" ]; then
        echo ">>>>Removing existing project directory: $V_PROJECT_NAME"
        rm -rf "$V_PROJECT_NAME" || { echo "Error: Failed to remove existing directory." >&2; exit 1; }
    fi
    echo ">>>>Creating project directory: $V_PROJECT_NAME"
    ng new $V_PROJECT_NAME --create-application=false  || { echo "Error: Failed to create Angular project." >&2; exit 1; }

    # Change directory to the newly created project
    cd "$V_PROJECT_NAME" || { echo "Error: Failed to change directory to $V_PROJECT_NAME" >&2; exit 1; }
    git init

    # Install dependencies
    echo ">>>Installing dependencies"
    npm install --silent

    # Create a starter library
    echo ">>>Creating library project"
    ng g library $library_name

    # Create a starter showcase SCSS and SSR
    echo ">>>Creating showcase project"
    ng g application $showcase_name --style=scss --ssr

    # Add extra files (license, code of conduct, changelog, contributing, readme, .all-contributorsrc)
    echo ">>>Adding extra files"
    copy_extra_files

    # Add build package.json script
    echo ">>>Adding build package.json script"
    npm pkg delete 'scripts.build'
    npm pkg set 'scripts.build:lib'="ng build $library_name"
    npm pkg set 'scripts.build:showcase'="ng build $showcase_name"
    npm pkg set 'scripts.build:all'='npm run build:lib && npm run build:showcase'

    # Extra packages
    # Prettier
    echo ">>Installing Prettier..."
    npm install --silent -D prettier

    npm pkg set 'scripts.format:check:lib'="prettier --check \"projects/$library_name/src/**/*.{ts,js,html,scss,json}\""
    npm pkg set 'scripts.format:write:lib'="prettier --write \"projects/$library_name/src/**/*.{ts,js,html,scss,json}\""

    npm pkg set 'scripts.format:check:showcase'="prettier --check \"projects/$showcase_name/src/**/*.{ts,js,html,scss,json}\""
    npm pkg set 'scripts.format:write:showcase'="prettier --write \"projects/$showcase_name/src/**/*.{ts,js,html,scss,json}\""

    npm pkg set 'scripts.format:check:all'='npm run format:check:lib && npm run format:check:showcase'
    npm pkg set 'scripts.format:write:all'='npm run format:write:lib && npm run format:write:showcase'

    # Lint
    echo ">>Installing ESLint..."
    ng add @angular-eslint/schematics --skip-confirmation

    npm pkg set 'scripts.format:lint:lib'="eslint --fix \"projects/$library_name/src/**/*.{ts,js}\""
    npm pkg set 'scripts.format:lint:showcase'="eslint --fix \"projects/$showcase_name/src/**/*.{ts,js}\""
    npm pkg set 'scripts.format:lint:all'='npm run format:lint:lib && npm run format:lint:showcase'

    # Starting file
    cp ../sources/.eslintrc.json ./

    # Doctoc
    echo ">>Installing Doctoc..."
    npm install --silent -D doctoc

    npm pkg set 'scripts.documentation:toc'="doctoc README.md"

    # Post build
    echo ">>Installing Post Build..."
    npm pkg set 'scripts.postbuild:lib'="npm run documentation:toc && cp README.md projects/$library_name/README.md && cp LICENSE projects/$library_name/LICENSE"

    # Contributors
    echo ">>Installing Contributors..."
    npm install --silent -D all-contributors-cli

    npm pkg set 'scripts.contributors:generate'="all-contributors generate"
    npm pkg set 'scripts.contributors:add'="all-contributors add"

    # Starting file
    cp ../sources/.all-contributorsrc ./

    # Husky
    echo ">>Installing Husky..."
    npm install --silent -D husky
    echo ">>>Installing Pretty-Quick..."

    npm pkg set 'scripts.husky:init'="husky init"
    npm pkg set 'scripts.husky:prepare'="husky"

    echo ">>>Initialise husky"
    echo ">>>>Will create a first pre-commit file and add the hooksPath to .git/config"
    echo ">>>>Please refer to https://typicode.github.io/husky/ for more details."
    npm run husky:init
    if [ ! -d ".git" ]; then
        echo ">>>>No .git folder found. Skipping adding path to .git/config"
        # Check if core.hooksPath is already set
        if ! git config --get core.hooksPath >/dev/null 2>&1; then
            # Adding manually, as husky does not add it by default as there is no .git folder
            git config core.hooksPath '.husky/_'
            echo "Added hooksPath to .git/config"
        else
            echo "hooksPath already exists in .git/config"
        fi
    fi

    npm install --silent -D pretty-quick
    echo ">>>Installing Commitlint..."
    npm install --silent -D @commitlint/cli @commitlint/config-conventional
    echo "export default {extends: ["@commitlint/config-conventional"],};" > commitlint.config.mjs
    npm pkg set 'scripts.commitlint'="commitlint --edit"

    echo ">>Setup Husky hooks"
    echo "npm run pretty-quick" > .husky/pre-commit
    echo "npm run commitlint ${1}" > .husky/commit-msg

    # Replace Json Property
    echo ">>Installing Replace Json Property..."
    npm install --silent -D replace-json-property

    npm pkg set 'scripts.bump-version'="rjp package.json version '$'VERSION && rjp projects/$library_name/package.json version '$'VERSION"
   
    # Final
    echo ""
    echo ">>Setup completed."
    finalise_lib_project

    echo "😊😊😊 All done. Happy coding! 😊😊😊"

}



echo ">Initialise environment"

if [ "$#" -eq 0 ]; then
    echo "Error: No argument provided. Please provide 'full' or 'for-lib'."
    exit 1
fi

echo ">Executing script for: $1"

check_nvm
install_tools

if [ "$1" = "for-lib" ]; then
    create_lib_project
fi
