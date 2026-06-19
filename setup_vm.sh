#!/bin/bash
# =============================================================================
#  TEHTRI-S-Hub Labs — VM Setup Script
#
#  Usage (depuis le dossier décompressé du zip) :
#    sudo bash setup_vm.sh              # Installe tous les labs
#    sudo bash setup_vm.sh --lab aes    # Installe un seul lab
#    sudo bash setup_vm.sh --list       # Liste les labs disponibles
#    sudo bash setup_vm.sh --reset      # Remet tous les labs dans l'état initial
#
#  Prérequis : Ubuntu 22.04 / Debian 12, accès root
#  Le dossier vm-assets/ doit être présent à côté de ce script (fourni dans le zip)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/vm-assets"

# ── Couleurs ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

ok()    { echo -e "${GREEN}[  OK  ]${RESET} $*"; }
info()  { echo -e "${CYAN}[ INFO ]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[ WARN ]${RESET} $*"; }
step()  { echo -e "\n${BOLD}${CYAN}━━  $*  ━━${RESET}"; }
banner(){ echo -e "\n${BOLD}${YELLOW}  ▶ LAB : $*${RESET}"; }
err()   { echo -e "${RED}[ FAIL ]${RESET} $*" >&2; exit 1; }

LABS_ALL=(linux-intro password aes rsa network-flux iptables who-listens clamav suricata sysmon)

# ── Argument parsing ──────────────────────────────────────────────────────────
SINGLE_LAB=""
DO_RESET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab)    shift; SINGLE_LAB="${1:-}" ;;
    --reset)  DO_RESET=true ;;
    --list)   echo "Labs disponibles :"; printf '  %s\n' "${LABS_ALL[@]}"; exit 0 ;;
    -h|--help) head -n 12 "$0" | grep '^#  ' | sed 's/^#  //'; exit 0 ;;
  esac
  shift
done

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]]          || err "Ce script doit être lancé en root : sudo bash $0"
[[ -f /etc/debian_version ]] || err "Système non supporté. Prévu pour Ubuntu/Debian."
[[ -d "$ASSETS_DIR" ]]       || err "Dossier vm-assets/ introuvable à côté du script."

# Vérifier les fichiers critiques
[[ -f "$ASSETS_DIR/aes/Ultra_important_secret.pdf" ]] \
  || err "Fichier manquant : vm-assets/aes/Ultra_important_secret.pdf"
[[ -f "$ASSETS_DIR/rsa/backup_key.gpg" ]] \
  || err "Fichier manquant : vm-assets/rsa/backup_key.gpg"
[[ -f "$ASSETS_DIR/rsa/message.txt.gpg" ]] \
  || err "Fichier manquant : vm-assets/rsa/message.txt.gpg"

# ── Helpers ───────────────────────────────────────────────────────────────────
pkg() {
  for p in "$@"; do
    dpkg -s "$p" &>/dev/null || {
      info "Installation de $p..."
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$p"
    }
  done
}

detect_iface() {
  ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}' | cut -d'@' -f1
}

student_dir() {
  local d="/home/student/labs/$1"
  mkdir -p "$d"
  echo "$d"
}

own_student() {
  chown -R student:student "$1" 2>/dev/null || true
}

# =============================================================================
#  BASE
# =============================================================================
base_setup() {
  step "Configuration de base"
  apt-get update -qq

  if ! id student &>/dev/null; then
    useradd -m -s /bin/bash student
    echo "student:student" | chpasswd
    usermod -aG sudo student 2>/dev/null || true
    ok "Utilisateur 'student' créé (mdp : student)"
  else
    info "Utilisateur 'student' déjà présent."
  fi

  mkdir -p /home/student/labs
  own_student /home/student/labs
}

# =============================================================================
#  LABS
# =============================================================================

# ── linux-intro ───────────────────────────────────────────────────────────────
lab_linux_intro() {
  banner "linux-intro"
  pkg bash coreutils grep findutils procps less

  local dir; dir=$(student_dir linux-intro)
  cp "$ASSETS_DIR/linux-intro/journal.txt" "$dir/journal.txt"

  mkdir -p "$dir/documents/rh" "$dir/documents/it" "$dir/tmp"
  echo "Contrat_Alice_2024.pdf (simulé)"  > "$dir/documents/rh/contrat_alice.txt"
  echo "Contrat_Bob_2024.pdf (simulé)"    > "$dir/documents/rh/contrat_bob.txt"
  echo "Inventaire serveurs — Q4 2024"    > "$dir/documents/it/inventaire.txt"
  echo "#!/bin/bash
# Script de backup quotidien
rsync -a /home/ /backup/" > "$dir/documents/it/backup.sh"
  echo "fichier temporaire 1" > "$dir/tmp/temp1.tmp"
  echo "fichier temporaire 2" > "$dir/tmp/temp2.tmp"

  own_student "$dir"
  ok "linux-intro : arborescence créée dans $dir"
}

# ── password ──────────────────────────────────────────────────────────────────
# Lab scenario : cedric existe avec le mot de passe 'password' (faible, compte actif)
# L'étudiant doit : bloquer (usermod -L) → changer (passwd → fait_1_3ffort,C3dric) → débloquer (usermod -U)
lab_password() {
  banner "password"
  pkg passwd

  if ! id cedric &>/dev/null; then
    useradd -m -s /bin/bash cedric
    ok "Utilisateur 'cedric' créé"
  fi

  # Mot de passe volontairement faible — c'est l'état initial du lab
  echo "cedric:password" | chpasswd
  # Compte actif (non verrouillé) — l'étudiant le verrouille lui-même à l'étape 3
  usermod -U cedric 2>/dev/null || true

  local dir; dir=$(student_dir password)
  cat > "$dir/TICKET_001.txt" <<'EOF'
TICKET #001 — Alerte Sécurité
==============================
Audit de routine : le compte de Cédric utilise un mot de passe figurant
dans tous les dictionnaires d'attaque connus.

Mot de passe actuel : password
(Oui. Vraiment. "password".)

Actions attendues :
  1. Vérifier l'état du compte      : passwd -S cedric  /  chage -l cedric
  2. Bloquer le compte pendant l'op : sudo usermod -L cedric
  3. Définir un nouveau mot de passe : sudo passwd cedric
     Nouveau mot de passe attendu   : fait_1_3ffort,C3dric
  4. Débloquer le compte             : sudo usermod -U cedric

Validation :
  su - cedric  →  'password'           doit ÉCHOUER
  su - cedric  →  'fait_1_3ffort,C3dric' doit RÉUSSIR
EOF
  own_student "$dir"
  ok "password : cedric créé (mdp : password, compte actif)"
}

# ── aes ───────────────────────────────────────────────────────────────────────
# Fichier source : bit-bang-main/Common/beginnerPack/AES_decrypt/Ultra_important_secret.pdf
# Déjà chiffré avec AES-256-CBC.
# Mots de passe candidats (entre guillemets simples) : 'Aniki<3' | 'BGduWeb25' | 'Urt1ka1r3'
# ⚠ Rappeler à l'étudiant : `cat` sur le fichier chiffré casse le terminal → taper `reset`
lab_aes() {
  banner "aes"
  pkg openssl file

  local dir; dir=$(student_dir aes)

  # Copier le fichier chiffré original (déjà prêt, pas besoin de re-chiffrer)
  cp "$ASSETS_DIR/aes/Ultra_important_secret.pdf" "$dir/Ultra_important_secret.pdf"
  cp "$ASSETS_DIR/aes/NOTE_patron.txt"             "$dir/NOTE_patron.txt"

  own_student "$dir"
  ok "aes : Ultra_important_secret.pdf copié dans $dir"
  info "Mots de passe candidats : 'Aniki<3' | 'BGduWeb25' | 'Urt1ka1r3'"
  info "Déchiffrement : openssl enc -d -aes-256-cbc -in Ultra_important_secret.pdf -out Ultra_important.pdf -k 'MOT_DE_PASSE'"
  warn "Si l'étudiant fait 'cat' sur le fichier chiffré, son terminal sera corrompu — rappeler : taper 'reset' + Entrée"
}

# ── rsa / GPG ─────────────────────────────────────────────────────────────────
# Fichiers source : bit-bang-main/Common/beginnerPack/RSA/
#   backup_key.gpg   — clé privée GPG à importer (protégée par phrase de passe)
#   message.txt.gpg  — message chiffré à déchiffrer
# Phrase de passe GPG : cyberIsD0pe  (demandée à l'import ET au déchiffrement)
lab_rsa() {
  banner "rsa / GPG"
  pkg gnupg

  local dir; dir=$(student_dir rsa)

  cp "$ASSETS_DIR/rsa/backup_key.gpg"   "$dir/backup_key.gpg"
  cp "$ASSETS_DIR/rsa/message.txt.gpg"  "$dir/message.txt.gpg"

  cat > "$dir/CONTEXTE.txt" <<'EOF'
Vous avez changé d'ordinateur récemment.
Vous avez pensé à récupérer votre backup_key.gpg. Youpi.

Votre patron a envoyé un nouveau message chiffré : message.txt.gpg

Étapes :
  1. Importer la clé privée  : gpg --import backup_key.gpg
     → Phrase de passe : cyberIsD0pe
  2. Déchiffrer le message   : gpg --output message_clair.txt --decrypt message.txt.gpg
     → Phrase de passe : cyberIsD0pe
EOF

  own_student "$dir"
  ok "rsa : backup_key.gpg + message.txt.gpg copiés dans $dir"
  info "Phrase de passe GPG : cyberIsD0pe  (import + déchiffrement)"
}

# ── network-flux ──────────────────────────────────────────────────────────────
# Reproduit : bit-bang-main/Common/beginnerPack/flux/break.sh
lab_network_flux() {
  banner "network-flux"
  pkg curl

  # Script de l'agent (curl en boucle vers 10.0.0.10:8080, comme break.sh)
  cat > /usr/local/bin/telemetry-agent.sh <<'EOF'
#!/bin/bash
while true; do
  curl http://10.0.0.10:8080 >/dev/null 2>&1
  sleep 30
done
EOF
  chmod +x /usr/local/bin/telemetry-agent.sh

  cat > /etc/systemd/system/telemetry-agent.service <<'EOF'
[Unit]
Description=System Telemetry Agent
After=network.target

[Service]
ExecStart=/usr/local/bin/telemetry-agent.sh
Restart=always
RestartSec=10
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable telemetry-agent 2>/dev/null
  systemctl restart telemetry-agent 2>/dev/null || true

  local dir; dir=$(student_dir network-flux)
  cat > "$dir/ALERTE.txt" <<'EOF'
Alerte SOC — Flux réseau suspect détecté
=========================================
Destination : 10.0.0.10:8080
Protocole   : HTTP
Fréquence   : toutes les ~30 secondes

Identifier le processus responsable et y mettre fin.
EOF
  own_student "$dir"
  ok "network-flux : telemetry-agent démarré (curl → 10.0.0.10:8080 toutes les 30s)"
}

# ── iptables ──────────────────────────────────────────────────────────────────
# Reproduit : bit-bang-main/Common/beginnerPack/iptables/break.sh
# iptables -P INPUT DROP  (politique par défaut DROP sur INPUT)
# NOTE : la règle loopback (lo) est intentionnellement ABSENTE de l'état cassé.
#        Sans elle, curl http://localhost TIME OUT correctement → l'étudiant doit
#        ajouter la règle port 80 pour que ça fonctionne.
#        apache2 est installé et actif pour qu'il y ait quelque chose sur le port 80.
lab_iptables() {
  banner "iptables"
  pkg iptables apache2

  # apache2 doit tourner pour que curl http://localhost réponde une fois la règle ajoutée
  systemctl enable apache2 2>/dev/null || true
  systemctl start  apache2 2>/dev/null || true

  # Appliquer la politique DROP sur INPUT — comme Jimmy
  iptables -P INPUT DROP

  # SSH préservé pour que l'apprenant garde sa connexion
  iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || \
    iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
  # Connexions établies (pour que les réponses aux requêtes sortantes passent)
  iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
    iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
  # PAS de règle loopback — curl http://localhost doit timeout avant la correction

  local dir; dir=$(student_dir iptables)
  cat > "$dir/TICKET_042.txt" <<'EOF'
TICKET #042 — Site web inaccessible
=====================================
Depuis ce matin, le site intranet ne répond plus.
curl http://localhost → timeout (connexion bloquée par le pare-feu).
apache2 tourne bien (systemctl status apache2 = active), mais le trafic entrant est filtré.

Jimmy a "juste testé un truc" hier soir sur le firewall.
Jimmy est en vacances jusqu'à lundi.

Remettre HTTP (port 80) en service.
EOF
  own_student "$dir"
  ok "iptables : politique INPUT DROP appliquée (SSH préservé)"
}

# ── who-listens ───────────────────────────────────────────────────────────────
# Reproduit : bit-bang-main/Common/beginnerPack/whoListens/break.sh
# nc -lk 4444 &
lab_who_listens() {
  banner "who-listens"
  pkg netcat-openbsd 2>/dev/null || pkg ncat 2>/dev/null || \
  pkg netcat-traditional 2>/dev/null || true

  # Trouver le binaire nc disponible
  NC_BIN=""
  for nc in nc ncat netcat; do
    command -v "$nc" &>/dev/null && { NC_BIN=$(command -v "$nc"); break; }
  done
  [[ -n "$NC_BIN" ]] || err "netcat introuvable après installation."

  cat > /etc/systemd/system/diag-listener.service <<EOF
[Unit]
Description=Diagnostics Listener
After=network.target

[Service]
ExecStart=/bin/sh -c 'while true; do $NC_BIN -lp 4444; done'
Restart=always
RestartSec=2
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable diag-listener 2>/dev/null
  systemctl restart diag-listener 2>/dev/null || true

  local dir; dir=$(student_dir who-listens)
  cat > "$dir/ALERTE.txt" <<'EOF'
Alerte SOC — Port inhabituel en écoute
========================================
Port détecté : 4444 / TCP

Identifier le processus, le service associé, et y mettre fin.
EOF
  own_student "$dir"
  ok "who-listens : listener actif sur port 4444"
}

# ── clamav ────────────────────────────────────────────────────────────────────
lab_clamav() {
  banner "clamav"
  pkg clamav clamav-daemon

  systemctl stop    clamav-daemon     2>/dev/null || true
  systemctl stop    clamav-freshclam  2>/dev/null || true
  systemctl disable clamav-daemon     2>/dev/null || true
  systemctl disable clamav-freshclam  2>/dev/null || true

  local dir; dir=$(student_dir clamav)

  # Fichier test EICAR (test antivirus standard, inoffensif)
  printf 'X5O!P%%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*\n' \
    > "$dir/suspicious.txt"
  cp "$ASSETS_DIR/clamav/rapport_mensuel.txt" "$dir/rapport_mensuel.txt"
  echo "#!/bin/bash
rsync -a /home/ /backup/home/" > "$dir/backup.sh"

  cat > "$dir/CONTEXTE.txt" <<'EOF'
L'antivirus n'est plus actif depuis la dernière mise à jour du serveur.
Un fichier suspect a été déposé dans ce dossier ce matin.

Objectifs :
  1. Remettre ClamAV en état de fonctionnement
  2. Mettre à jour la base de signatures (freshclam)
  3. Scanner ce dossier et identifier le fichier infecté
EOF

  own_student "$dir"
  ok "clamav : service arrêté, fichier EICAR présent dans $dir"
}

# ── suricata ──────────────────────────────────────────────────────────────────
lab_suricata() {
  banner "suricata"
  pkg suricata

  local IFACE; IFACE=$(detect_iface)
  local CONF=/etc/suricata/suricata.yaml

  if [[ -f "$CONF" ]]; then
    [[ -f "${CONF}.orig" ]] || cp "$CONF" "${CONF}.orig"
    sed -i "s/interface: ${IFACE}/interface: eth99/" "$CONF"
    sed -i 's|^  - suricata.rules|  # - suricata.rules  # désactivé|' "$CONF"
  fi

  systemctl stop    suricata 2>/dev/null || true
  systemctl disable suricata 2>/dev/null || true

  local dir; dir=$(student_dir suricata)
  cat > "$dir/CONTEXTE.txt" <<EOF
Suricata IDS est installé mais ne démarre pas correctement.

Interface réseau de cette VM : $IFACE
Fichier de configuration     : /etc/suricata/suricata.yaml

Problèmes à corriger :
  1. L'interface configurée (eth99) n'existe pas — remplacer par : $IFACE
  2. Les règles de détection sont désactivées
  3. Le service n'est pas démarré

Config originale sauvegardée : /etc/suricata/suricata.yaml.orig
EOF
  echo "$IFACE" > "$dir/interface.txt"
  own_student "$dir"
  ok "suricata : interface cassée (eth9 au lieu de $IFACE), règles désactivées"
}

# ── sysmon ────────────────────────────────────────────────────────────────────
lab_sysmon() {
  banner "sysmon (Linux)"
  pkg wget apt-transport-https gpg lsb-release

  if ! command -v sysmon &>/dev/null; then
    info "Ajout du dépôt Microsoft..."
    local VER; VER=$(lsb_release -rs)
    wget -q "https://packages.microsoft.com/config/ubuntu/${VER}/packages-microsoft-prod.deb" \
      -O /tmp/ms-prod.deb
    dpkg -i /tmp/ms-prod.deb
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sysmonforlinux
    rm /tmp/ms-prod.deb
  else
    info "sysmon déjà installé."
  fi

  # Supprimer la config au bon chemin (sysmon-config.xml, comme attendu par la page du lab)
  rm -f /opt/sysmon/sysmon-config.xml 2>/dev/null || true
  rm -f /opt/sysmon/config.xml        2>/dev/null || true
  systemctl stop    sysmon 2>/dev/null || true
  systemctl disable sysmon 2>/dev/null || true

  local dir; dir=$(student_dir sysmon)
  cat > "$dir/CONTEXTE.txt" <<'EOF'
Sysmon for Linux est installé mais pas opérationnel.

Problèmes :
  1. Aucun fichier de configuration XML n'est présent (/opt/sysmon/sysmon-config.xml)
  2. Le service n'est pas démarré

Étapes :
  1. Créer le fichier de config  : sudo nano /opt/sysmon/sysmon-config.xml
     (ou copier le template fourni : sudo cp sysmon-config.xml /opt/sysmon/)
  2. Charger la config           : sudo sysmon -accepteula -c /opt/sysmon/sysmon-config.xml
  3. Démarrer le service         : sudo systemctl enable sysmon && sudo systemctl start sysmon
  4. Vérifier les logs           : sudo journalctl -u sysmon -f
EOF

  cat > "$dir/sysmon-config.xml" <<'EOF'
<Sysmon schemaversion="4.30">
  <EventFiltering>
    <RuleGroup name="" groupRelation="or">
      <ProcessCreate onmatch="exclude"/>
    </RuleGroup>
    <RuleGroup name="" groupRelation="or">
      <NetworkConnect onmatch="exclude"/>
    </RuleGroup>
  </EventFiltering>
</Sysmon>
EOF

  own_student "$dir"
  ok "sysmon : installé, sans config XML, service désactivé"
}

# =============================================================================
#  RESET
# =============================================================================
reset_labs() {
  step "Reset de tous les labs"
  warn "Cette opération remet les labs dans l'état 'cassé' initial."
  read -rp "Confirmer ? (oui/non) : " CONFIRM
  [[ "$CONFIRM" == "oui" ]] || { info "Reset annulé."; exit 0; }

  rm -rf /home/student/labs/
  mkdir -p /home/student/labs
  own_student /home/student/labs

  for lab in "${LABS_ALL[@]}"; do
    "lab_${lab//-/_}" || warn "Reset partiel : $lab"
  done
  ok "Reset terminé."
}

# =============================================================================
#  MAIN
# =============================================================================
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║   TEHTRI-S-Hub Labs — VM Setup       ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${RESET}"

if [[ "$DO_RESET" == true ]]; then
  reset_labs; exit 0
fi

base_setup

if [[ -n "$SINGLE_LAB" ]]; then
  FN="lab_${SINGLE_LAB//-/_}"
  declare -f "$FN" &>/dev/null || err "Lab inconnu : $SINGLE_LAB — utilisez --list"
  "$FN"
else
  for lab in "${LABS_ALL[@]}"; do
    "lab_${lab//-/_}"
  done
fi

step "VM prête"
echo -e "  Compte étudiant   : ${GREEN}student${RESET} / ${GREEN}student${RESET}"
echo -e "  Dossiers des labs : ${BOLD}/home/student/labs/${RESET}"
echo ""
echo -e "  ${DIM}Labs configurés :${RESET}"
LABS_TO_SHOW=("${LABS_ALL[@]}")
[[ -n "$SINGLE_LAB" ]] && LABS_TO_SHOW=("$SINGLE_LAB")
for lab in "${LABS_TO_SHOW[@]}"; do
  echo -e "    ${GREEN}✓${RESET} $lab"
done
echo ""
