# Clúster Kubernetes con kubeadm y despliegue de aplicaciones

## Información académica

- Autor: Juan José Arias Gallego
- Asignatura: Infraestructura III
- Entorno: Fedora, VirtualBox, Vagrant y Rocky Linux
- Herramienta de instalación del clúster: kubeadm

## Descripción

Este proyecto documenta la implementación de un clúster Kubernetes
en un entorno virtualizado y el despliegue de aplicaciones sobre él.

El laboratorio integra dos actividades:

1. Implementación de la infraestructura, preparación de los nodos,
   inicialización del control plane, incorporación del worker y
   administración remota desde un bastión.
2. Construcción y publicación de una imagen de aplicación Flask,
   despliegue mediante manifiestos YAML, exposición mediante un Service
   NodePort y pruebas de escalamiento y recuperación automática.

La documentación distingue las configuraciones implementadas, las
validaciones realizadas y los ajustes pendientes.

## Arquitectura

| Máquina | Función | IP del laboratorio |
|---------|---------|--------------------|
| dns-dhcp01 | DHCP, DNS y administración con kubectl | 192.168.56.10 |
| k8s-master | Control plane de Kubernetes | 192.168.56.110 |
| k8s-worker | Ejecución de las aplicaciones | 192.168.56.120 |

Las direcciones del master y del worker se asignan mediante reservas
DHCP asociadas a sus direcciones MAC.

La administración del clúster se realiza desde dns-dhcp01 mediante
kubectl y un kubeconfig protegido.

## Versiones verificadas

| Componente | Versión |
|------------|---------|
| Kubernetes en master y worker | v1.34.12 |
| kubectl en el bastión | v1.34.12 |
| containerd en master y worker | 2.2.7 |
| Rocky Linux en master y worker | 9.8 |
| VirtualBox en el host | 7.2 |

La consigna de instalación menciona Rocky Linux 9.7.
Los nodos implementados reportan Rocky Linux 9.8; esta diferencia
se registra como parte del entorno utilizado.

## Redes del clúster

| Elemento | Configuración |
|----------|---------------|
| Red del laboratorio | 192.168.56.0/24 |
| Red de Pods | 10.244.0.0/16 |
| Red de Services | 10.96.0.0/12 |
| Plugin CNI | Flannel |
| API Server | 192.168.56.110:6443 |

## Aplicaciones del laboratorio

| Aplicación | Deployment | Service | Acceso desde el bastión |
|------------|------------|---------|------------------------|
| Nginx | nginx-lab | nginx-lab | http://192.168.56.120:30080 |
| Flask | webapp-deployment | webapp-service | http://192.168.56.120:30001 |

La aplicación Flask se construyó a partir del repositorio académico
mariocr73/K8S-apps y se publicó con la referencia:

docker.io/juanjarias2006/webapp:v1

Su respuesta HTTP esperada es:

¡Hola Mundo desde Kubernetes!

## Estado y alcance

Se verificó la disponibilidad de ambos nodos y de los componentes
del sistema desde el bastión.

Las evidencias de DNS, escalamiento y self-healing se documentan
en sus secciones correspondientes.

El laboratorio aún requiere cerrar la configuración persistente
de red antes de considerar validado su comportamiento tras un reinicio.
