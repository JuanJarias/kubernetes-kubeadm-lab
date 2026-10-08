# Actividad 2: despliegue de una aplicación Flask en Kubernetes

## 1. Objetivo

Construir, publicar y desplegar una aplicación contenerizada sobre el
clúster Kubernetes creado con kubeadm. Validar su exposición mediante
un Service NodePort, su escalamiento y su recuperación automática.

## 2. Entorno

La administración se realiza desde el bastión dns-dhcp01.

| Componente | Configuración |
|------------|---------------|
| Kubernetes | v1.34.12 |
| Master | 192.168.56.110 |
| Worker | 192.168.56.120 |
| Aplicación | Flask |
| Imagen publicada | docker.io/juanjarias2006/webapp:v1 |
| Puerto de la aplicación | 5000 |
| Puerto del Service | 80 |
| NodePort | 30001 |

## 3. Procedencia del código

La aplicación y el Dockerfile proceden del repositorio académico:

https://github.com/mariocr73/K8S-apps

Se conserva la licencia original junto al código en apps/webapp.

La aplicación define una ruta HTTP `/` que devuelve:

¡Hola Mundo desde Kubernetes!

## 4. Análisis de los manifiestos originales

| Archivo | Recurso | Observación |
|---------|---------|-------------|
| webapp-configmap.yaml | ConfigMap | Define APP_ENV=production. |
| webapp-dbsecret.yaml | Secret | Contiene marcadores de credenciales; la aplicación no utiliza una base de datos. |
| webapp-deployment.yaml | Deployment | Define inicialmente dos réplicas y requiere especificar una imagen real. |
| webapp-dhsecret.yaml | Secret | La plantilla Opaque no es adecuada como credencial de descarga del registro. |
| webapp-replicaset.yaml | ReplicaSet | Comparte el selector del Deployment; no se desplegó como controlador independiente. |
| webapp-service.yaml | Service | Expone la aplicación mediante NodePort 30001. |

## 5. Adaptaciones realizadas

Se conservaron los manifiestos originales en el repositorio del docente
y se prepararon manifiestos adaptados para esta entrega:

- Se especificó la imagen docker.io/juanjarias2006/webapp:v1.
- Se seleccionó k8s-worker mediante nodeSelector.
- Se conectó el ConfigMap al contenedor mediante envFrom.
- Se definieron solicitudes y límites de CPU y memoria.
- Se omitió el ReplicaSet independiente.
- Se omitieron los Secrets de ejemplo, al no ser necesarios para
  la configuración utilizada.

APP_ENV se inyecta como variable de entorno, pero el código actual
no la consulta. Su valor no desactiva el debug=True de app.py.

## 6. Construcción y publicación de la imagen

Los siguientes comandos se ejecutaron en el bastión, dentro del
repositorio original clonado:

```bash
podman build -t localhost/webapp:v1 .
podman tag localhost/webapp:v1 docker.io/juanjarias2006/webapp:v1
podman login docker.io --username juanjarias2006
podman push docker.io/juanjarias2006/webapp:v1
```

La construcción finalizó correctamente y la publicación terminó
con el mensaje "Writing manifest to image destination".

Las credenciales del registro no se incluyen en este repositorio.

Para reconstruir desde esta entrega, el contexto de construcción es:

```bash
podman build -t localhost/webapp:v1 apps/webapp/
```

## 7. Despliegue

Durante el laboratorio se aplicó la carpeta manifests-lab del bastión.

En este repositorio, los archivos equivalentes se encuentran en
manifests/actividad-2. Desde la raíz de esta entrega y con kubectl
configurado:

```bash
kubectl apply -f manifests/actividad-2/
kubectl rollout status deployment/webapp-deployment --timeout=180s
kubectl get deployment webapp-deployment
kubectl get pods -l app=hola-mundo -o wide
kubectl get service webapp-service
```

El manifiesto inicial solicita dos réplicas.

## 8. Acceso a la aplicación

Desde el bastión:

```bash
curl --connect-timeout 5 --max-time 15 http://192.168.56.120:30001/
```

Respuesta esperada:

```text
¡Hola Mundo desde Kubernetes!
```

El Service selecciona los Pods mediante la etiqueta app=hola-mundo
y dirige el tráfico del puerto 80 hacia el puerto 5000 del contenedor.

## 9. Escalamiento a tres réplicas

Procedimiento de validación:

```bash
kubectl scale deployment webapp-deployment --replicas=3
kubectl rollout status deployment/webapp-deployment --timeout=120s
kubectl get deployment webapp-deployment
kubectl get pods -l app=hola-mundo -o wide
```

Resultado requerido:
Deployment con READY 3/3 y tres Pods disponibles.

Estado documental:
Pendiente de incorporar la salida y la captura de validación.

El comando scale modifica el estado del clúster. Para conservar tres
réplicas al volver a aplicar el manifiesto, también debe actualizarse
spec.replicas en el archivo versionado.

## 10. Prueba de self-healing

Procedimiento de validación:

```bash
kubectl get pods -l app=hola-mundo -o wide
POD=$(kubectl get pods -l app=hola-mundo -o jsonpath='{.items.metadata.name}')
echo "$POD"
kubectl delete pod "$POD"
kubectl get pods -l app=hola-mundo -w
```

Se detiene la observación con Ctrl+C cuando las tres réplicas
vuelven a estar disponibles.

Resultado requerido:
Un Pod de reemplazo con nombre y UID diferentes y recuperación
del número deseado de réplicas.

Estado documental:
Pendiente de incorporar evidencias del antes, eliminación y después.

## 11. Preguntas de análisis

### ¿Por qué usar Deployment en lugar de crear Pods directamente?

Un Deployment administra el estado deseado de una aplicación mediante
ReplicaSets. Permite mantener réplicas y gestionar actualizaciones
declarativas y reversiones.

Un Pod creado directamente no dispone por sí mismo de un controlador
que cree otro Pod cuando se elimina.

### ¿Quién recrea el Pod eliminado?

El controlador del ReplicaSet detecta que hay menos Pods que el número
deseado y crea un reemplazo.

El Deployment administra ese ReplicaSet. El scheduler asigna el nuevo
Pod a un nodo y kubelet gestiona su ejecución en ese nodo.

La prueba demuestra el reemplazo de un Pod eliminado, no la recuperación
ante la caída completa del único worker.

## 12. Evidencias requeridas

Guardar en docs/evidencias/actividad-2:

1. Nodos Ready.
2. Deployment y Pods disponibles.
3. Service NodePort.
4. Respuesta HTTP de la aplicación.
5. Deployment escalado a tres réplicas.
6. Eliminación de un Pod y aparición del reemplazo.

Cada captura debe incluir una explicación del comando, el resultado
observado y su interpretación.

## 13. Limitaciones

- La aplicación utiliza el servidor de desarrollo de Flask con debug=True;
  se utiliza como demostración académica, no como despliegue de producción.
- Los Pods se fijan al único worker, por lo que tres réplicas no implican
  tolerancia a la caída de ese nodo.
- La configuración persistente de red sigue pendiente y se documenta
  en docs/incidencias-red.md.
