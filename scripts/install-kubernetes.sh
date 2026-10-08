#!/usr/bin/env bash
set -Eeuo pipefail

# Uso:
#   sudo bash install-kubernetes.sh master
#   sudo bash install-kubernetes.sh worker
#
# Este script se ejecuta DENTRO de cada VM Rocky Linux.
# No inicializa el clúster: solo prepara runtime, herramientas y firewall.

NODE_ROLE="${1:?Uso: sudo bash install-kubernetes.sh <master|worker>}"
K8S_MINOR="${K8S_MINOR:-v1.34}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: ejecute este script con sudo."
  exit 1
fi

if [[ "${NODE_ROLE}" != "master" && "${NODE_ROLE}" != "worker" ]]; then
  echo "Error: el rol debe ser master o worker."
  exit 1
fi

echo "============================================================"
echo "Fase 3: runtime e instalación Kubernetes en ${NODE_ROLE}"
echo "============================================================"

echo "[1/8] Actualizando metadatos e instalando dependencias..."
dnf makecache -y
dnf install -y containerd curl ca-certificates

echo "[2/8] Generando configuración estándar de containerd..."
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

echo "[3/8] Configurando SystemdCgroup = true..."
sed -ri 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

if ! grep -q 'SystemdCgroup = true' /etc/containerd/config.toml; then
  echo "Error: no fue posible establecer SystemdCgroup = true."
  exit 1
fi

echo "[4/8] Activando containerd..."
systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd
systemctl is-active --quiet containerd

echo "[5/8] Configurando repositorio oficial pkgs.k8s.io..."
cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "[6/8] Instalando kubelet, kubeadm y kubectl..."
dnf clean all
dnf makecache -y
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

echo "[7/8] Habilitando kubelet..."
systemctl enable --now kubelet

echo "[8/8] Configurando firewalld..."
systemctl enable --now firewalld

# Todos los nodos: kubelet, NodePort y Flannel VXLAN.
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-port=30000-32767/udp
firewall-cmd --permanent --add-port=8472/udp

# Solo control plane: API Server y componentes de control.
if [[ "${NODE_ROLE}" == "master" ]]; then
  firewall-cmd --permanent --add-port=6443/tcp
  firewall-cmd --permanent --add-port=2379-2380/tcp
  firewall-cmd --permanent --add-port=10257/tcp
  firewall-cmd --permanent --add-port=10259/tcp
fi

firewall-cmd --reload

echo
echo "==================== VALIDACIÓN FASE 3 ====================="
echo "Containerd:"
systemctl is-active containerd
grep -n 'SystemdCgroup' /etc/containerd/config.toml

echo
echo "Versiones:"
kubeadm version
kubelet --version
kubectl version --client

echo
echo "Puertos abiertos:"
firewall-cmd --list-ports

echo
echo "Nota: kubelet puede aparecer reiniciándose hasta ejecutar"
echo "kubeadm init (master) o kubeadm join (worker). Es normal."
