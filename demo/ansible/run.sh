#!/usr/bin/env bash
# Uso: /vagrant/ansible/run.sh site.yml | deploy.yml [opciones de ansible-playbook]
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

# vboxsf es world-writable y Ansible ignora un ansible.cfg ahí salvo que se lo nombre.
export ANSIBLE_CONFIG="$dir/ansible.cfg"

if [ ! -f "$dir/group_vars/all/vault.yml" ]; then
  echo "Falta group_vars/all/vault.yml: copialo de vault.example.yml, cambiá los valores y cifralo." >&2
  exit 1
fi

if [ ! -f "$HOME/.vault_pass" ]; then
  read -r -s -p "Clave del vault: " clave
  echo
  (umask 077 && printf '%s\n' "$clave" > "$HOME/.vault_pass")
fi

cd "$dir"
exec ansible-playbook "$@"
