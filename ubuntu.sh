#!/bin/bash
set -euo pipefail

# =============================
# Ubuntu Auto Setup (Azimeee)
# =============================
clear
cat << "EOF"
==============================================================
  _______    _______     __    __    __    _______    _______
|  ___  |  |_____  |   |  |  |   \/   |  |  _____|  |  _____|
| |___| |       /  /   |  |  |  \  /  |  | |____    | |____
| |___| |     /  /     |  |  |  |\/|  |  |  ____|   |  ____|
| |   | |   /  /____   |  |  |  |  |  |  | |_____   | |_____
|_|   |_|  |________|  |__|  |__|  |__|  |_______|  |_______|
                                   
              POWERED BY AZIMEEE            
==============================================================
EOF

# =============================
# Root Check
# =============================
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Please run this script as root (sudo su)."
    exit 1
fi

# =============================
# Essentials Installation
# =============================
echo "[INFO] Updating system..."
apt update -y && apt upgrade -y

echo "[INFO] Installing essentials..."
apt install -y \
    curl wget git vim htop unzip zip \
    software-properties-common apt-transport-https \
    ca-certificates gnupg lsb-release net-tools iproute2

# =============================
# Docker Installation
# =============================
echo "[INFO] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
else
    echo "[INFO] Docker already installed."
fi

systemctl enable docker
systemctl start docker

# =============================
# Docker Compose Installation
# =============================
echo "[INFO] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "[INFO] Docker Compose already installed."
fi

# =============================
# Launch Ubuntu Container as root@nebulacloud
# =============================
echo "[INFO] Pulling Ubuntu image..."
docker pull ubuntu:22.04

echo "[INFO] Launching Ubuntu shell as root@nebulacloud..."

exec docker run -it --rm \
    --hostname nebulacloud \
    ubuntu:22.04 /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1 && apt install -y sudo net-tools vim lsb-release >/dev/null 2>&1
    echo 'root:root' | chpasswd

    # Real MOTD with IP
    IP=\$(hostname -I | awk '{print \$1}')
    cat > /etc/motd <<EOM

Welcome to Ubuntu \$(lsb_release -rs) LTS (\$(uname -r))

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of \$(date)

  System load:  \$(uptime | awk -F'load average:' '{ print \$2 }')
  Usage of /:   \$(df -h / | awk 'NR==2 {print \$5 \" of \" \$2}')
  Memory usage: \$(free -m | awk 'NR==2{printf \"%s%%\", \$3*100/\$2 }')
  Swap usage:   \$(free -m | awk 'NR==3{printf \"%s%%\", \$3*100/\$2 }')
  IP address:   \$IP

EOM

    bash --login
"
