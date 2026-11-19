# Capítulos de Sebastián Acosta — borrador para revisión

> Documento de trabajo elaborado con los resultados observados el 18 y 19 de noviembre de 2026. Las salidas y estados corresponden a la cuenta de laboratorio en us-east-1. Donde se indica “pendiente”, hace falta insertar la captura del navegador o de la consola de AWS; no se presenta como evidencia algo que no se capturó.

## 4. Configuración con Ansible

### Actualización de ejecución — tag v1.0-listo (19 de noviembre de 2026)

El tag v1.0-listo corresponde al commit 0969811. La primera ejecución sin cambios falló porque curl-minimal entra en conflicto con curl en Amazon Linux 2023. Siguiendo la instrucción, eliminé solo la línea - curl en la copia de prueba ubicada en WSL; una comparación confirmó que no hubo otros cambios y el tag y la rama permanecen intactos. En la nueva prueba SSM mostró dos instancias Online, el inventario detectó dos hosts y ambos respondieron pong. La primera corrida completó con failed=0, unreachable=0 y changed=8 en cada host. La segunda completó con failed=0, unreachable=0 y changed=0 en ambos, por lo que la idempotencia quedó verificada en la copia de prueba. Las salidas completas están en ansible/run1-v1.0-listo.log, ansible/run1-curl-removed-v1.0-listo.log y ansible/run2-curl-removed-v1.0-listo.log.

### 4.1 Objetivo y preparación

El propósito de esta etapa fue verificar que Ansible pudiera descubrir y administrar las instancias EC2 privadas del grupo de Auto Scaling sin abrir SSH. El controlador se preparó en Ubuntu sobre WSL2 con Ansible, boto3, botocore, AWS CLI v2, Session Manager Plugin y las colecciones `amazon.aws`, `ansible.posix` y `community.aws`. La evidencia de las herramientas está en EV-01.

La autenticación de AWS se realizó mediante el perfil IAM `Julio-devops` y el inicio de sesión del AWS CLI. La identidad consultada correspondió a la cuenta de laboratorio y al usuario IAM asignado. No se guardaron contraseñas ni códigos de autenticación en este documento.

### 4.2 Inventario dinámico y acceso SSM

El archivo `ansible/aws_ec2.yml` usa el plugin `amazon.aws.aws_ec2`, consulta la región `us-east-1`, filtra instancias en ejecución con la etiqueta `Name=rompecode-app` y las agrupa como `webservers`. El inventario base compone `ansible_host` con la dirección privada. Para ejecutar comandos de Ansible sobre estas instancias privadas se configuró temporalmente la conexión por AWS Systems Manager (SSM), con Session Manager Plugin y un bucket S3 dedicado para transferencia.

En la prueba actual, las dos instancias aparecieron Online en SSM; el inventario dinámico mostró dos hosts en webservers y el módulo ping respondió pong en ambos. La salida se conserva en EV-18-current-test-copy.log.

### 4.3 Organización de los roles

El playbook `ansible/site.yml` aplica los roles `common`, `webserver` y `deploy`, en ese orden, a los hosts del grupo `webservers`.

- **common:** instala herramientas base, activa `firewalld`, permite HTTP y asegura que exista el usuario `deploy`. Este rol prepara requisitos comunes del sistema.
- **webserver:** instala Nginx, publica su configuración desde una plantilla, crea el directorio de la aplicación e inicia y habilita el servicio. El handler reinicia Nginx cuando cambia la plantilla.
- **deploy:** copia la página y los archivos de la aplicación y configuración a sus rutas, ejecuta nginx -t cuando cambian y mantiene habilitado y activo el servicio rompecode.

Ansible es idempotente cuando una tarea declara un estado final y, al repetirse sin cambios externos, deja changed=0. En esta prueba, la primera corrida tuvo changed=8 por host y la segunda changed=0 por host.

### 4.4 Resultado de la ejecución y bloqueo

La corrida del tag sin modificar se detuvo en la primera tarea de common. DNF informó que curl-minimal, ya instalado en Amazon Linux 2023, entra en conflicto con el paquete curl solicitado; el play recap registró failed=1 y changed=0 en los dos hosts procesados.

Después, en la copia temporal de prueba, quité únicamente la línea - curl. El diff confirmado contiene solo esa eliminación. La primera corrida de esta copia completó common, webserver y deploy con failed=0, unreachable=0 y changed=8 en cada host. La segunda corrida dio failed=0, unreachable=0 y changed=0 en los dos hosts; una validación de Nginx quedó skipped porque los archivos no habian cambiado. Así se verificó idempotencia en la copia de prueba, sin alterar el tag ni el archivo de la rama.

Durante las transferencias aparecieron avisos de limpieza del plugin SSM, pero las tareas y ambos play recaps terminaron correctamente. El error original y las salidas de las dos corridas se guardan en EV-19-original-error-curl-extracto.log, EV-19-run1-curl-removed-resumen.log y EV-20-run2-idempotencia-resumen.log.

## 7. Resultados y pruebas

### 7.1 Balanceo entre instancias y zonas

**Objetivo.** Confirmar que el Application Load Balancer responde y distribuye solicitudes entre las instancias privadas ubicadas en dos zonas de disponibilidad.

**Procedimiento.** Se consultó `/health` y se hicieron 20 solicitudes repetidas a `/api/info` a través del DNS del ALB.

**Resultado esperado.** Código HTTP 200 en salud y al menos dos identificadores de instancia en ambas zonas `us-east-1a` y `us-east-1b`.

**Resultado obtenido.** `/health` devolvió HTTP 200. Las respuestas de `/api/info` alternaron entre las instancias de las zonas `us-east-1a` y `us-east-1b`. La salida de consola está en [EV-08](evidencias/EV-08-s4.log). La captura del portal en navegador que solicita EV-09 queda pendiente de insertar.

**Conclusión.** La prueba por CLI confirmó respuesta saludable y distribución entre las dos zonas. La captura visual de EV-09 debe agregarse antes de cerrar el capítulo.

### 7.2 Recuperación ante la terminación de una instancia

**Objetivo.** Verificar que el servicio mantenga disponibilidad y que el Auto Scaling Group reemplace una instancia terminada.

**Procedimiento.** Se registró el estado inicial de dos targets saludables, se mantuvo una consulta continua a `/health` y se terminó una instancia siguiendo el paso definido en el plan.

**Resultado esperado.** La mayoría de las respuestas continúa en HTTP 200; pueden aparecer respuestas 502/504 durante la detección de la caída. El ASG crea una instancia de reemplazo y el target group recupera dos targets saludables.

**Resultado obtenido.** Durante la transición se observaron algunos 502 y tiempos de espera; después las respuestas volvieron a 200. El ASG sustituyó la instancia y el target group volvió a dos targets saludables. La secuencia de terminación y recuperación está en [EV-14](evidencias/EV-14-before-termination.log), [EV-15 HTTP](evidencias/EV-15-resilience-http.log), [EV-15 terminación](evidencias/EV-15-termination.log) y [EV-15 recuperación](evidencias/EV-15-recovery.log).

**Conclusión.** El grupo recuperó su capacidad tras la terminación. Los errores breves durante la detección se conservaron en la evidencia y no se ocultaron.

### 7.3 Estrés y escalado automático

**Objetivo.** Elevar la CPU por encima del umbral objetivo y comprobar que la política de seguimiento agregue capacidad.

**Procedimiento.** Se verificó el estado base de dos instancias. Las llamadas directas al ALB para iniciar estrés devolvieron HTTP 403. El portal indicaba que la solicitud debía originarse desde un túnel SSM. Se abrieron túneles SSM directos a las instancias y el endpoint `POST /api/stress`, con el encabezado de prueba requerido, respondió HTTP 202 y `{"duration_seconds":300}` en ambas instancias. Las repeticiones durante la carga o el periodo de espera respondieron HTTP 409, de acuerdo con el control de concurrencia del endpoint.

**Resultado esperado.** CPU del ASG superior al 70 %, alarma `AlarmHigh` en ALARM, actividad de lanzamiento y una tercera instancia saludable.

**Resultado obtenido.** La CPU de las instancias originales alcanzó valores cercanos a 100 %. La alarma `TargetTracking-rompecode-asg-AlarmHigh` cruzó el umbral de 70 % durante tres datapoints (95.12 %, 100 % y 99.90 %). A las 04:13:55 UTC del 19 de noviembre la alarma activó `rompecode-scale-up-cpu` y el tamaño deseado cambió de 2 a 3. AWS lanzó `i-0ee8d08853a4bfae9`. A las 04:16 UTC, las tres instancias figuraban `InService / Healthy` en el ASG y `healthy` en el target group. Los resultados están en [EV-13 reintento](evidencias/EV-13-api-stress-reintento.log) y [EV-13 a EV-16 escalado](evidencias/EV-13-16-s6-scaleout.log).

**Conclusión.** Se demostró el escalado real de dos a tres instancias y la incorporación saludable de la nueva instancia. La activación por CLI quedó registrada; la captura del botón del portal solicitada para EV-13 debe agregarse desde el navegador si se requiere evidenciar la interacción visual.

### 7.4 Consideraciones de operación

El monitoreo detallado se habilitó temporalmente en las dos instancias originales para obtener métricas de un minuto y observar la alarma. Se deshabilitó al terminar la prueba; las tres instancias quedaron con ese monitoreo desactivado. La instancia nueva también se lanzó con monitoreo detallado desactivado, lo que indica que la opción no está habilitada en la configuración que la instancia hereda del Launch Template/ASG. Luis debe revisar ese ajuste si se requieren alarmas por minuto en futuras instancias.

Al cierre de esta prueba, el ASG tenía capacidad deseada 3 (mínimo 2, máximo 6) y los tres targets estaban saludables. No se ejecutó `terraform destroy`: el plan asigna esa operación final a Julio. Debe coordinarse la destrucción con él una vez que el equipo haya guardado las capturas de evidencia, para evitar costos de recursos activos.

