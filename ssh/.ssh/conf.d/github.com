Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_zawakin
  UseKeychain yes
  AddKeysToAgent yes
  IdentitiesOnly yes
