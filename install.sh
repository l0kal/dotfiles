#!/bin/bash

main() {
    aliases_setup || (echo "aliases_setup job failed and exited" && exit 1)
    npm_setup || (echo "npm_setup job failed and exited" && exit 1)
    git_setup || (echo "git_setup job failed and exited" && exit 1)
    gcloud_auth_setup || (echo "gcloud_auth_setup job failed and exited" && exit 1)
}

aliases_setup() {
    echo "Setting up bash aliases"

    cp "${HOME}/.dotfiles/.bash_aliases" "${HOME}/.bash_aliases"
}

npm_setup() {
    echo "Setting up NPM"

    if [ -n "${EXTENDA_NEXUS_TOKEN:-}" ]; then
        cp "${HOME}/.dotfiles/.npmrc" "${HOME}/.npmrc"
        npm i -g @hiiretail/nest-app-cli
    fi
}

git_setup() {
    echo "Setting up Git"

    git config --global push.autoSetupRemote true

    echo "Git: Use rebase to pull"
    git config --global pull.rebase false

    # if [ -n "${GPG_PRIVATE_KEY_BASE64:-}" ]; then
    #     echo "Git: Installing GPG key"
    #     gpg --verbose --batch --import <(echo "${GPG_PRIVATE_KEY_BASE64}" | base64 -d)
    #     echo 'pinentry-mode loopback' >> ~/.gnupg/gpg.conf
    #     git config --global user.signingkey "${GPG_SIGNING_KEY}"
    #     git config --global commit.gpgsign true
    #     git config --global tag.gpgsign true
    # fi

    if [[ ! -z $GNUGPG  ]]; then
        echo "Git: Installing GPG key"
        rm -rf $HOME/.gnupg;
        (cd $HOME ; echo $GNUGPG | base64 -d | tar --no-same-owner -xzvf -);
        git config --global commit.gpgsign true;
        git config --global tag.gpgsign true
    fi
}

gcloud_auth_setup() {
    if [ -n "${EXTENDA_GCLOUD_AUTH_BASE64:-}" ]; then
        mkdir -p ~/.config/gcloud
        echo "${EXTENDA_GCLOUD_AUTH_BASE64}" | base64 -d > ~/.config/gcloud/application_default_credentials.json
        sudo cp "${HOME}/.dotfiles/docker-credential-gcr" /usr/bin/docker-credential-gcr
        sudo chmod +x /usr/bin/docker-credential-gcr
        /usr/bin/docker-credential-gcr configure-docker
    fi
}

main "$@"