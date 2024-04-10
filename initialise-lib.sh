#!/usr/bin/zsh

clear

# Define ANSI escape codes for colors
BLUE='\033[1;34m'  # Bold Blue
RED='\033[1;31m'  # Bold red
NC='\033[0m'       # No Color

V_NODE="20.11.1"
V_PROJECT_NAME="my-ng-base-project"
V_ANGULAR_VERSION="17.3.3"

# Function to echo the input string in bold blue
print_in_bold_blue() {
    echo -e "${BLUE}$1${NC}"
}
# Function to echo the input string in bold red
print_in_bold_red() {
    echo -e "${RED}$1${NC}"
}

check_nvm() {
    print_in_bold_blue ">>Check if NVM is sourced successfully"
    print_in_bold_blue ">>>Enforce Node.js version to $V_NODE"
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    # Check if NVM is sourced
    if [ -f "$NVM_SCRIPT" ]; then
        . "$NVM_SCRIPT"

        # Check if Node.js version $V_NODE is installed
        if nvm ls $V_NODE &> /dev/null; then
            print_in_bold_blue ">>>>Node.js version $V_NODE is installed."
        else
            print_in_bold_blue ">>>>Node.js version $V_NODE is not installed."
            print_in_bold_blue ">>>>Installing Node.js version $V_NODE..."
            nvm install $V_NODE
        fi

        # Use Node.js version $V_NODE
        print_in_bold_blue ">>>Enforcing Node.js version $V_NODE"
        nvm use $V_NODE

    else
        print_in_bold_blue ">>>NVM not found or failed to load. Please make sure it's installed and sourced properly."
        print_in_bold_blue ">>>Please refer to https://github.com/nvm-sh/nvm for further instructions."
        print_in_bold_blue ">>>Exiting..."
        exit 1
    fi
    print_in_bold_blue ">>>Node.js Environment setup completed."
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
    print_in_bold_blue ">>Install tools"
    current_angular_version=$(get_angular_cli_version)
    print_in_bold_blue ">>>Current Angular CLI version: $current_angular_version"
    print_in_bold_blue ">>>Required Angular CLI version: $V_ANGULAR_VERSION"
    if [ "$current_version" = "$desired_version" ]; then
        print_in_bold_blue ">>>Angular CLI version $desired_version is already installed."
    else
        print_in_bold_blue ">>>Installing Angular CLI version $desired_version..."
        install_angular_cli
        print_in_bold_blue ">>>Angular CLI version $desired_version installed successfully."
    fi
}

create_lib_and_showcase_projects() {
    # Create a starter library
    print_in_bold_blue ">>>Creating library project"
    ng g library $library_name

    # Create a starter showcase SCSS and SSR
    print_in_bold_blue ">>>Creating showcase project"
    ng g application $showcase_name --style=scss --ssr

    # Add build package.json script
    print_in_bold_blue ">>>Adding build package.json script"
    npm pkg delete 'scripts.build'
    npm pkg set 'scripts.build:lib'="ng build $library_name"
    npm pkg set 'scripts.build:showcase'="ng build $showcase_name"
    npm pkg set 'scripts.build:all'='npm run build:lib && npm run build:showcase'
}

copy_extra_files() {
    # Add extra files (license, code of conduct, changelog, contributing, readme, .all-contributorsrc)
    print_in_bold_blue ">>>Adding extra files"
    print_in_bold_blue ">>Post creation steps"
    print_in_bold_blue ">>>Copying project files: LICENSE, CODE_OF_CONDUCT.md, CONTRIBUTING.md, README.md"
    cp ../sources/LICENSE ./LICENSE
    cp ../sources/CODE_OF_CONDUCT.md ./CODE_OF_CONDUCT.md
    cp ../sources/CONTRIBUTING.md ./CONTRIBUTING.md
    cp ../sources/README.md ./README.md    
    print_in_bold_blue ">>>Project files copied successfully."

    print_in_bold_blue ">>>Creating an empty CHANGELOG.md file"
    touch ./CHANGELOG.md
    print_in_bold_blue ">>>Change log file created successfully."
}

finalise_lib_project() {
    print_in_bold_blue " "
    print_in_bold_blue ">>Finalizing..."
    npm run format:check:lib
    npm run format:write:lib
    npm run format:lint:lib

    npm run format:check:showcase
    npm run format:write:showcase
    npm run format:lint:showcase
}

setup_create_ng_workspace() {
    # create the angular base project with create-application=false
    print_in_bold_blue ">>>Create the angular base project with create-application=false"
    # Remove the existing project directory if it exists
    if [ -d "$V_PROJECT_NAME" ]; then
        print_in_bold_blue ">>>>Removing existing project directory: $V_PROJECT_NAME"
        rm -rf "$V_PROJECT_NAME" || { print_in_bold_red "Error: Failed to remove existing directory." >&2; exit 1; }
    fi
    print_in_bold_blue ">>>>Creating project directory: $V_PROJECT_NAME"
    ng new $V_PROJECT_NAME --create-application=false  || { print_in_bold_red "Error: Failed to create Angular project." >&2; exit 1; }

    # Change directory to the newly created project
    cd "$V_PROJECT_NAME" || { print_in_bold_red "Error: Failed to change directory to $V_PROJECT_NAME" >&2; exit 1; }
    git init

    # Install dependencies
    print_in_bold_blue ">>>Installing dependencies"
    npm install --silent
}

setup_prettier() {
    # Prettier
    print_in_bold_blue ">>Installing Prettier..."
    npm install --silent -D prettier

    npm pkg set 'scripts.format:check:lib'="prettier --check \"projects/$library_name/src/**/*.{ts,js,html,scss,json}\""
    npm pkg set 'scripts.format:write:lib'="prettier --write \"projects/$library_name/src/**/*.{ts,js,html,scss,json}\""

    npm pkg set 'scripts.format:check:showcase'="prettier --check \"projects/$showcase_name/src/**/*.{ts,js,html,scss,json}\""
    npm pkg set 'scripts.format:write:showcase'="prettier --write \"projects/$showcase_name/src/**/*.{ts,js,html,scss,json}\""

    npm pkg set 'scripts.format:check:all'='npm run format:check:lib && npm run format:check:showcase'
    npm pkg set 'scripts.format:write:all'='npm run format:write:lib && npm run format:write:showcase'
}

setup_eslint() {
    # Lint
    print_in_bold_blue ">>Installing ESLint..."
    ng add @angular-eslint/schematics --skip-confirmation

    npm pkg set 'scripts.format:lint:lib'="eslint --fix \"projects/$library_name/src/**/*.{ts,js}\""
    npm pkg set 'scripts.format:lint:showcase'="eslint --fix \"projects/$showcase_name/src/**/*.{ts,js}\""
    npm pkg set 'scripts.format:lint:all'='npm run format:lint:lib && npm run format:lint:showcase'

    # Starting file
    cp ../sources/.eslintrc.json ./
}

setup_doctoc() {
    # Doctoc
    print_in_bold_blue ">>Installing Doctoc..."
    npm install --silent -D doctoc

    npm pkg set 'scripts.documentation:toc'="doctoc README.md"

    # Post build
    print_in_bold_blue ">>Installing Post Build..."
    npm pkg set 'scripts.postbuild:lib'="npm run documentation:toc && cp README.md projects/$library_name/README.md && cp LICENSE projects/$library_name/LICENSE"
}

setup_all_contributors() {
    # Contributors
    print_in_bold_blue ">>Installing Contributors..."
    npm install --silent -D all-contributors-cli

    npm pkg set 'scripts.contributors:generate'="all-contributors generate"
    npm pkg set 'scripts.contributors:add'="all-contributors add"

    # Starting file
    cp ../sources/.all-contributorsrc ./
}

setup_husky_with_prettyquick_and_commitlint() {
    # Husky
    print_in_bold_blue ">>Installing Husky..."
    npm install --silent -D husky
    print_in_bold_blue ">>>Installing Pretty-Quick..."

    npm pkg set 'scripts.husky:init'="husky init"
    npm pkg set 'scripts.husky:prepare'="husky"

    print_in_bold_blue ">>>Initialise husky"
    print_in_bold_blue ">>>>Will create a first pre-commit file and add the hooksPath to .git/config"
    print_in_bold_blue ">>>>Please refer to https://typicode.github.io/husky/ for more details."
    npm run husky:init
    if [ ! -d ".git" ]; then
        print_in_bold_blue ">>>>No .git folder found. Skipping adding path to .git/config"
        # Check if core.hooksPath is already set
        if ! git config --get core.hooksPath >/dev/null 2>&1; then
            # Adding manually, as husky does not add it by default as there is no .git folder
            git config core.hooksPath '.husky/_'
            print_in_bold_blue "Added hooksPath to .git/config"
        else
            print_in_bold_blue "hooksPath already exists in .git/config"
        fi
    fi

    npm install --silent -D pretty-quick
    print_in_bold_blue ">>>Installing Commitlint..."
    npm install --silent -D @commitlint/cli @commitlint/config-conventional
    print_in_bold_blue "export default {extends: ["@commitlint/config-conventional"],};" > commitlint.config.mjs
    npm pkg set 'scripts.commitlint'="commitlint --edit"

    print_in_bold_blue ">>Setup Husky hooks"
    print_in_bold_blue "npm run pretty-quick" > .husky/pre-commit
    print_in_bold_blue "npm run commitlint ${1}" > .husky/commit-msg
}

setup_replace_json() {
    # Replace Json Property
    print_in_bold_blue ">>Installing Replace Json Property..."
    npm install --silent -D replace-json-property

    npm pkg set 'scripts.bump-version'="rjp package.json version '$'VERSION && rjp projects/$library_name/package.json version '$'VERSION"
}

setup_github_actions() {
    # GitHub Actions
    print_in_bold_blue ">>Copying GitHub Actions samples files..."
    mkdir -p .github/workflows
    cp ../sources/.github/workflows/branch.yml .github/workflows/branch.yml
    cp ../sources/.github/workflows/release.yml .github/workflows/release.yml
}

setup_test_and_coverage() {
    # Tests and Coveralls
    print_in_bold_blue ">>Installing Coveralls..."

    npm pkg set 'scripts.tests:lib'="ng test --no-watch $library_name"
    npm pkg set 'scripts.tests:showcase'="ng test --no-watch $showcase_name"

    npm pkg set 'scripts.tests:lib-w-coverage'="ng test --no-watch $library_name --code-coverage"
    npm pkg set 'scripts.tests:showcase-w-coverage'="ng test --no-watch $showcase_name --code-coverage"

    # Create specific Karma
    # Change the browser to ChromeHeadless
    if [ ! -f "$library_name/karma.conf.js" ]; then
        print_in_bold_blue ">>Installing Karma... for $library_name"
        ng generate config karma --no-interactive --project=$library_name

        print_in_bold_blue ">>>>Changing browser to ChromeHeadless"
        sed -i '/browsers:/s/\[.*\]/\[\"ChromeHeadless\"\]/' projects/$library_name/karma.conf.js

        print_in_bold_blue ">>>>Changing type to lcov"
        sed -i "s/{ type: 'html' },/{ type: 'lcov' }/" projects/$library_name/karma.conf.js

        print_in_bold_blue ">>>>Removing text-summary"
        sed -i "/{ type: 'text-summary' }/d" projects/$library_name/karma.conf.js
    fi
    if [ ! -f "$showcase_name/karma.conf.js" ]; then
        print_in_bold_blue ">>Installing Karma... for $showcase_name"
        ng generate config karma --no-interactive --project=$showcase_name

        print_in_bold_blue ">>>>Changing browser to ChromeHeadless"        
        sed -i '/browsers:/s/\[.*\]/\[\"ChromeHeadless\"\]/' projects/$showcase_name/karma.conf.js

        print_in_bold_blue ">>>>Changing type to lcov"
        sed -i "s/{ type: 'html' },/{ type: 'lcov' }/" projects/$showcase_name/karma.conf.js
        
        print_in_bold_blue ">>>>Removing text-summary"
        sed -i "/{ type: 'text-summary' }/d" projects/$showcase_name/karma.conf.js
    fi
}

create_lib_project() {
    print_in_bold_blue ">>Creating library project"

    library_name="$V_PROJECT_NAME-lib"
    showcase_name="$V_PROJECT_NAME-showcase"

    setup_create_ng_workspace

    create_lib_and_showcase_projects

    copy_extra_files

    setup_prettier

    setup_eslint

    setup_doctoc

    setup_all_contributors

    setup_husky_with_prettyquick_and_commitlint

    setup_replace_json
   
    setup_github_actions

    setup_test_and_coverage

    print_in_bold_blue ""
    print_in_bold_blue ">>Setup completed."

    finalise_lib_project

    print_in_bold_blue "😊😊😊 All done. Happy coding! 😊😊😊"

}

print_in_bold_blue ">Initialise environment"

check_nvm

install_tools

create_lib_project
