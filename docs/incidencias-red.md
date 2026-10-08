# Incidencia de red: interfaces duplicadas y DHCP concurrente

## Situación observada

Los adaptadores 3 y 4 del master y del worker estaban conectados
a la misma red host-only de VirtualBox, vboxnet0.

En esa red se identificaron dos servidores DHCP:

- Bastión: 192.168.56.10.
- VirtualBox: 192.168.56.2.

El DHCP de VirtualBox tenía habilitado el rango
192.168.56.3–192.168.56.254, que se solapa con las direcciones
utilizadas por el laboratorio.

## Síntomas

- El master recibió inicialmente una dirección distinta de su reserva.
- Los nodos tenían dos interfaces en 192.168.56.0/24.
- La ruta del master hacia el bastión utilizaba eth2.
- El acceso TCP desde el bastión al API Server terminaba en timeout.

## Medidas aplicadas

1. Se probó temporalmente rp_filter=2 en eth2 y eth3 del master.
2. Se desactivó el perfil redundante asociado a eth2.
3. Se verificó que las rutas hacia el bastión utilizaran eth3.

Direcciones verificadas:

- Master: 192.168.56.110.
- Worker: 192.168.56.120.

## Pendientes

- Eliminar la competencia entre los servidores DHCP sin afectar otras VMs.
- Actualizar el diseño declarado en Vagrant.
- Resolver la diferencia entre la red host-only implementada y
  la red interna aislada solicitada en la consigna.
- Validar la configuración tras un reinicio controlado.

El ajuste temporal de rp_filter no se considera una solución
persistente del diseño de red.
