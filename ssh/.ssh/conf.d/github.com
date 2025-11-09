Host github.com
  User git
  Hostname ssh.github.com
  Port 443
  IdentityFile ~/.ssh/id_ed25519_zawakin
  PreferredAuthentications publickey
  UseKeychain yes
  AddKeysToAgent yes

Host github.com-trybase77
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_trybase77
  AddKeysToAgent yes
  UseKeychain yes
