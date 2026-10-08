# Evidencias de la implementación

Este documento organiza las capturas de pantalla utilizadas como evidencia de la implementación del clúster Kubernetes con kubeadm sobre Rocky Linux 9.7.


## 1. Infraestructura virtual

 VirtualBox Manager mostrando `dns-dhcp01`, `k8s-master` y `k8s-worker`.

**Comentario:**  
En esta imagen se observa la infraestructura del laboratorio. El servidor bastión ya existía y actúa como servidor DHCP, DNS y punto central de administración. Se crearon dos VMs adicionales: `k8s-master`, que funciona como control plane, y `k8s-worker`, encargado de ejecutar las cargas de trabajo.

<img width="401" height="182" alt="image" src="https://github.com/user-attachments/assets/e1d66070-eb39-4c67-85de-86026e3a165b" />


## 2. Interfaces de red

 Configuración de red del master en VirtualBox.

**Comentario:**  
El nodo master cuenta con cuatro adaptadores de red: NAT para salida a Internet, Bridge para acceso SSH desde la red física, Host-Only para administración desde el host y una interfaz privada conectada a la red `192.168.56.0/24`, donde se comunica con el bastión y el worker.

<img width="951" height="898" alt="image" src="https://github.com/user-attachments/assets/c394a55e-cb72-49dd-96db-7a52d415b7a2" />

<img width="957" height="542" alt="image" src="https://github.com/user-attachments/assets/e36ef1c4-2f2e-43c2-bf42-311f36ca8898" />



## 3. Configuración DHCP

 Salida de `sudo cat /etc/dhcp/dhcpd.conf` en el bastión.

**Comentario:**  
El servidor DHCP del bastión entrega el dominio `lab.local` y el DNS `192.168.56.10`. Además, se configuraron reservas basadas en MAC para que `k8s-master` obtenga la IP `192.168.56.110` y `k8s-worker` la IP `192.168.56.120`.

<img width="957" height="845" alt="image" src="https://github.com/user-attachments/assets/2729b4d2-db0e-4687-8913-65189bbc9a8d" />


## 4. Resolución DNS

 `getent hosts k8s-master.lab.local` y `getent hosts k8s-worker.lab.local`.

**Comentario:**  
La resolución de nombres confirma que el servicio BIND del bastión conoce los registros de ambos nodos Kubernetes y permite usar nombres en lugar de direcciones IP durante la administración.

<img width="827" height="126" alt="image" src="https://github.com/user-attachments/assets/590b981b-15b0-4909-b69b-4728ad36c35c" />

<img width="793" height="133" alt="image" src="https://github.com/user-attachments/assets/a58ff6eb-8b13-4191-a2b2-15784271f424" />



## 5. Preparación de nodos



```bash
hostnamectl --static
swapon --show
getenforce
lsmod | egrep 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward
```

**Comentario:**  
Los prerrequisitos del sistema fueron aplicados en master y worker. Swap quedó desactivada, SELinux se configuró en modo permisivo, se habilitaron los módulos `overlay` y `br_netfilter`, y se activó el reenvío IPv4 requerido para la red de Kubernetes.

<!-- Insertar imagen aquí -->

## 6. Runtime de contenedores


```bash
systemctl is-active containerd
grep SystemdCgroup /etc/containerd/config.toml
```

**Comentario:**  
Containerd fue instalado como runtime de contenedores. La configuración `SystemdCgroup = true` permite que containerd use el mismo controlador de cgroups que kubelet.

<img width="897" height="932" alt="Fase-3" src="https://github.com/user-attachments/assets/e349923c-f294-4da2-b116-9b7d4635009e" />

<img width="896" height="694" alt="Fase-3-2" src="https://github.com/user-attachments/assets/59003c6f-30fd-4192-9c12-bc8f5258618d" />




## 7. Red de Pods con Flannel


```bash
kubectl get pods -n kube-flannel -o wide
```

**Comentario:**  
Flannel fue instalado como plugin CNI. Sus Pods se ejecutan en los nodos del clúster y habilitan la comunicación entre las redes de Pods.

<img width="897" height="808" alt="Fase-4-1" src="https://github.com/user-attachments/assets/9244e912-964e-4aaa-bd7e-6333bba8609a" />

<img width="895" height="695" alt="Fase-4-2" src="https://github.com/user-attachments/assets/15a68ed2-81bd-43af-a64e-150a91121d55" />





## 8. Deployment en worker


```bash
kubectl get pods -l app=nginx-demo -o wide
```

**Comentario:**  
El Deployment de Nginx creó dos réplicas y, mediante `nodeSelector`, ambas se programaron en `k8s-worker`. La columna `NODE` permite evidenciar dónde se ejecutan los Pods.

<img width="967" height="318" alt="Fase-5-2" src="https://github.com/user-attachments/assets/69629b01-a6ee-4af8-a9e7-e1a4f6a47a46" />


## 9. Servicio NodePort


```bash
kubectl get svc nginx-demo
```

**Comentario:**  
El servicio de tipo NodePort expone la aplicación Nginx en el puerto `30080`. Kubernetes redirige las solicitudes que llegan a ese puerto hacia los Pods seleccionados por la etiqueta `app=nginx-demo`.

<img width="966" height="152" alt="Fase-5-3" src="https://github.com/user-attachments/assets/a20e8642-8760-4f4d-ae4d-76ae083b7c9a" />


## 10. Prueba de acceso desde bastión


```bash
curl -I http://192.168.56.120:30080
```

**Comentario:**  
El bastión consumió la aplicación mediante la IP del worker y el NodePort asignado. La respuesta HTTP 200 demuestra que la publicación del servicio funciona desde fuera del clúster.

<img width="954" height="229" alt="Actividad-2-f1-2" src="https://github.com/user-attachments/assets/5b14b20b-bdcd-4c92-ab1d-654a9cfb49b2" />



