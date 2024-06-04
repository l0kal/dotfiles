## Add these env vars to gitpod

### EXTENDA_GCLOUD_AUTH_BASE64

`gcloud auth application-default login`

`cat ~/.config/gcloud/application_default_credentials.json | base 64`

### EXTENDA_NEXUS_TOKEN
NEXUS tokencat 

### EXTENDA_NEXUS_EMAIL
Nexus email

### GPG not working
`gpg --full-generate-key`

`gpg --list-secret-keys --keyid-format=long`

`gpg --armor --export <GPG_SIGNING_KEY>`

#### GPG_PRIVATE_KEY_BASE64
`gpg --output private.pgp --armor --export-secret-key <GPG_SIGNING_KEY>`

`cat private.pgp | base64`

#### GPG_SIGNING_KEY
Key ID generated with `gpg`