# Cuaderno de Notas de Trabajo: Adquisición Forense
**Caso Pericial:** Bahía Sistemas / Almadraba Diseño  
**Perito Responsable:** Natalia Alejo Pérez (Alumno 20)  
**Marca Testigo Pericial:** `AFI-NataliaAlejo-20261103`  
**Perito Receptor / Custodio:** Eduardo Moreno Rodríguez (`Edu DAM`)  
**Fecha de Intervención:** 3 al 5 de noviembre de 2026  
**Normativa Pericial:** UNE 71506:2013 · ISO/IEC 27037:2012 · RFC 3227

---

## 1. Datos del Caso y Escena Inicial

- **Entorno investigado:** Equipo Windows comprometido en el cuarto de informática de Almadraba Diseño.
- **Nombre de máquina / Dominio:** `FORENSE-06` / `FORENSIC_10` (Workgroup: `FORENSICS`).
- **Sistema Operativo:** Windows 10 Pro (x64) · Instalación base corporativa.
- **Hardware virtual:** 1 procesador vCPU, 1.00 GB de memoria RAM física asignada.
- **Estado al inicio de la intervención:** Encendido (estación activa con sesión iniciada).
- **Evidencia física anexa hallada:** Dispositivo de almacenamiento flash USB sin etiquetar encontrado sobre la mesa junto al teclado del usuario.
- **Dispositivo USB documentado:** `General UDisk USB Device` (32 GB comercial / 29,29 GB útiles, S/N: `2107221816162859250002`), partición única formateada en `exFAT`.

---

## 2. Registro Cronológico de Acciones Paso a Paso (Orden de Volatilidad)

El procedimiento pericial se organizó de forma estricta respetando el orden de volatilidad establecido por la **RFC 3227**:
1. Registros volátiles en memoria física (RAM) y conexiones activas.
2. Tráfico de red en tránsito.
3. Estado de procesos y tablas de enrutamiento.
4. Almacenamiento no volátil (disco duro del sistema y pendrive de la escena).

```mermaid
flowchart TD
    A["Escena en Vivo: FORENSIC_10"] --> B["1. Documentar Pendrive y Hardware"]
    B --> C["2. Montar USB_RESPUESTA y TAP de Red"]
    C --> D["3. Fijar Marca de Autoría"]
    D --> E["4. Volcado de RAM desde Hipervisor (1,21 GB)"]
    E --> F["5. Triaje Ligero en Vivo (PowerShell / Salida)"]
    F --> G["6. Comprobación BitLocker y Apagado Forzado"]
    G --> H["7. Adquisición Post-Mortem Disco E01 (FTK)"]
    H --> I["8. Adquisición Física Pendrive E01 (FTK)"]
    I --> J["9. Verificación Cruzada Hashes (28/28 OK)"]
```

---

### 2.1 Preparación del Entorno y Documentación Previa de la Evidencia Física
- **Hora:** 15:30 h · 03/11/2026
- **Acción:** Inspección visual y documentación pericial del pendrive encontrado antes de conectarlo a la máquina investigada. Se fotografiaron sus características físicas (cuerpo giratorio rojo y metálico) y se extrajeron sus identificadores unívocos de hardware en la estación pericial forense: fabricante genérico (`General UDisk USB Device`), número de serie `2107221816162859250002` y formato de archivos `exFAT`.
- **Evidencias gráficas:**
  <p align="center">
    <img src="capturas/01-pendrive-foto.png" alt="Inspección física del pendrive de la escena" width="550" />
  </p>
  <p align="center">
    <img src="capturas/02-pendrive-propiedades-hardware.png" alt="Propiedades de hardware y número de serie" width="650" />
  </p>
  <p align="center">
    <img src="capturas/03-pendrive-capacidad-exfat.png" alt="Capacidad y formato de archivos exFAT" width="650" />
  </p>

---

### 2.2 Configuración del Medio de Respuesta y Captura de Red
- **Hora:** 15:42 h · 03/11/2026
- **Acción:** Siguiendo las mejores prácticas forenses para optimizar el almacenamiento y evitar escrituras involuntarias en los discos del caso, se configuró un segundo disco virtual dedicado (`USB_RESPUESTA.vdi`, 25 GB) sobre la controladora SAS de la máquina `FORENSIC_10`. Este volumen actúa como unidad de respuesta para depositar herramientas y salidas sin alterar el disco principal del sistema (`FORENSIC_10_disk0.vmdk`). Se inicializó en MBR y se formateó en NTFS con la etiqueta `RESPUESTA (D:)`.
- **Captura de tráfico de red en modo TAP:** Activación de la intercepción de paquetes desde el exterior del hipervisor mediante comandos `VBoxManage`, garantizando un impacto del 0% en la máquina investigada:
  ```bash
  VBoxManage modifyvm "FORENSIC_10" --nictracefile1 "hashes/red.pcap"
  VBoxManage modifyvm "FORENSIC_10" --nictrace1 on
  ```

---

### 2.3 Arranque y Fijación de la Marca de Autoría
- **Hora del sistema virtual:** 3:58 PM (15:58 h) · 11/3/2026
- **Hora real del perito:** 15:58 h · 03/11/2026
- **Desfase temporal del reloj:** **0 minutos** (el reloj de la máquina virtual se encuentra perfectamente sincronizado con la hora de la estación pericial).
- **Inyección de marca pericial forense:**
  1. Apertura de sesión con credenciales de administración facilitadas (`Administrador` / `HSrupaliuwCCvh`).
  2. Apertura del Bloc de notas (`notepad`) con la marca personal `AFI-NataliaAlejo-20261103`, manteniéndolo en memoria activa sin guardar en disco para garantizar su presencia en el volcado volátil de RAM.
  3. Creación del archivo testigo `marca-nataliaalejo.txt` en el Escritorio del equipo y réplica en la raíz del pendrive físico de la escena.
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/04-estado-inicial-marca-ram.png" alt="Inyección de marca pericial en memoria activa" width="650" />
  </p>

---

### 2.4 Adquisición Forense de la Memoria RAM (En Vivo)
- **Hora:** 17:29 h · 03/11/2026
- **Herramienta utilizada:** Volcado de depuración a nivel de hipervisor VirtualBox (`VBoxManage debugvm dumpvmcore`).
- **Justificación técnica pericial:** Se optó por la extracción desde el hipervisor para garantizar un **impacto nulo (0% de alteración)** en el espacio de usuario del sistema operativo investigado, eliminando el riesgo de sobreescritura de procesos o bloqueos asociados a binarios antiguos de captura en vivo.
- **Fichero generado:** `hashes/FORENSIC_10-ram.raw` (1.214.117.728 bytes / 1,21 GB).
- **Hash de integridad SHA-256:**
  `0401711ec86b3cbe66844d451064a0726325230105a0149aef2e7c5ab3a24e90`
- **Verificación pericial de la marca en memoria:** Búsqueda en texto codificado UTF-16 dentro del fichero `.raw`. Se confirmó la presencia íntegra de la cadena `AFI-NataliaAlejo-20261103` en el offset de bytes exacto **`276165056`** (0x10760000).
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/05-verificacion-marca-ram.png" alt="Verificación de la marca pericial en el offset de memoria RAM" width="650" />
  </p>

---

### 2.5 Recolección de Datos Volátiles de Triaje
- **Hora:** 17:56 h · 03/11/2026
- **Herramienta utilizada:** Script pericial oficial de la práctica (`respuesta-en-vivo.ps1`) y comandos nativos del sistema volcados hacia la unidad de respuesta externa `D:\salida\`.
- **Alcance:** El triaje se limitó a comandos nativos de consola, ejecutados después de la extracción de la RAM (apartado 2.4) y antes de la adquisición del disco. No se emplearon KAPE ni Velociraptor; las consecuencias de esta decisión se recogen en el apartado 6 (Incidencias y Limitaciones). La extracción profunda de artefactos queda para la fase de análisis sobre la copia de trabajo E01.
- **Artefactos adquiridos:**
  - `01-fecha.txt`: Registro de fecha y hora local del sistema.
  - `06-netstat.txt`: Conexiones TCP/UDP activas y mapeo de procesos con PIDs (`netstat -ano`).
  - `10-red.txt`: Configuración completa de interfaces IP, gateways y servidores DNS (`ipconfig /all`).
  - `12-procesos.txt`: Listado completo de procesos en ejecución del atacante (`tasklist`).
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/06-datos-volatiles-salida.png" alt="Recolección de datos volátiles hacia la unidad de respuesta" width="650" />
  </p>

---

### 2.6 Comprobación de Cifrado de Discos y Apagado Forense
- **Hora:** 17:59 h · 03/11/2026
- **Comprobación de BitLocker:** Ejecución de `manage-bde -status` en la consola administrativa.
- **Resultado:** Ningún volumen se encuentra cifrado.
  - Volumen `C:` (Sistema): `Conversion Status: Fully Decrypted`, `Percentage Encrypted: 0%`, `Protection Status: Protection Off`.
  - Volumen `D:` (Respuesta): `Conversion Status: Fully Decrypted`, `Protection Off`.
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/07-comprobacion-cifrado-bitlocker.png" alt="Comprobación de ausencia de cifrado BitLocker" width="650" />
  </p>
- **Decisión de apagado:** Al confirmarse la ausencia total de cifrado de volumen (lo que descarta el riesgo de bloqueo de particiones tras reinicio), se procedió al **apagado inmediato por hardware virtual (`poweroff`)** a las 18:00 h, garantizando que el sistema operativo no ejecute rutinas de desmontaje ni modifique marcas de tiempo en el disco `.vmdk`.
- **Cierre de captura de red:** Se detuvo la traza TAP. Fichero consolidado: `hashes/red.pcap` (2.241.370 bytes, SHA-256: `22818ef0752ac4f03bc54c6e1b7802bc6f0ae106f2fd7887e0839853cc0d77f3`).
- **Fijación de Hash previo del disco original:** Inmediatamente tras el apagado, se calculó el SHA-256 del disco `.vmdk`:
  `f98ca9c5585c0fd6605d3563c0b52d7b9addfa8c3930f0568459722cf49cd6a6`
- **Recomprobación del hash tras la adquisición:** El 11/11/2026 se volvió a calcular el SHA-256 del disco `.vmdk` con el equipo investigado apagado, para comprobar que nada había escrito en el original durante las adquisiciones:
  ```powershell
  Get-FileHash "C:\Users\esana\VirtualBox VMs\FORENSIC_10\FORENSIC_10_disk0.vmdk" -Algorithm SHA256
  ```
  - **Resultado:** `F98CA9C5585C0FD6605D3563C0B52D7B9ADDFA8C3930F0568459722CF49CD6A6`, **idéntico** al calculado inmediatamente tras el apagado.
  - **Fecha de modificación del fichero:** 03/11/2026 18:00:09 (la hora del apagado), sin cambios posteriores. Tamaño: 13.286.047.744 bytes.
  - **Conclusión:** el disco original no ha sido modificado desde el apagado.

---

### 2.7 Adquisición Post-Mortem del Disco Virtual (Formato Forense E01)
- **Hora:** 21:28 h · 04/11/2026
- **Herramienta utilizada:** AccessData FTK Imager v3.4.0.5.
- **Origen de adquisición:** `FORENSIC_10_disk0.vmdk` (imagen lógica del disco preservada sin arranques).
- **Destino y formato:** `hashes/FORENSIC_10_disk0.E01` (Expert Witness Format, segmentado en bloques de 1.500 MB).
- **Metadatos de la evidencia incorporados en la cabecera E01:**
  - Case Number: `AFI-UD1`
  - Evidence Number: `EVIDENCIA-01`
  - Unique Description: `Disco FORENSIC_10 post-mortem`
  - Examiner: `Natalia Alejo Perez`
- **Verificación automática de integridad post-adquisición:**
  - **MD5 calculado y verificado:** `d23cd66a7475d2a47dbaffd960fd1f80` (`Match`)
  - **SHA-1 calculado y verificado:** `5d36b49702c656dbb3997b77b88df2bc3c5a68f6` (`Match`)
  - Sectores totales verificados: `67.108.864` (32.768 MB).
- **Ficheros generados:**
  - `FORENSIC_10_disk0.E01` (1.572.749.374 bytes)
  - `FORENSIC_10_disk0.E02` (1.572.799.453 bytes)
  - `FORENSIC_10_disk0.E03` (1.572.729.802 bytes)
  - `FORENSIC_10_disk0.E04` (264.633.827 bytes)
  - `FORENSIC_10_disk0.E01.txt` (Registro oficial de adquisición y geometría)
- **Evidencias gráficas:**
  <p align="center">
    <img src="capturas/08-adquisicion-ftk-e01-verificada.png" alt="Verificación íntegra de adquisición E01 del disco en FTK Imager" width="650" />
  </p>
  <p align="center">
    <img src="capturas/09-marca-personal-en-disco-e01.png" alt="Verificación de marca de agua pericial en disco montado" width="650" />
  </p>

---

### 2.8 Adquisición Post-Mortem del Pendrive Encontrado en la Escena (Formato E01)
- **Hora:** 23:05 h · 04/11/2026
- **Herramienta utilizada:** AccessData FTK Imager v3.4.0.5.
- **Origen de adquisición:** Disco físico `\\.\PHYSICALDRIVE1` (`General UDisk USB Device`, 31 GB, S/N: `2107221816162859250002`).
- **Destino y formato:** `hashes/PENDRIVE_ESCENA.E01` (formato E01 segmentado en fragmentos de 1.500 MB).
- **Metadatos periciales introducidos:**
  - Case Number: `AFI-UD1`
  - Evidence Number: `EVIDENCIA-02`
  - Unique Description: `Pendrive escena del crimen`
  - Examiner: `Natalia Alejo Perez`
  - Notes: `Adquisicion fisica post-mortem verificada`
- **Resultados de la verificación de integridad:**
  - **MD5 calculado y verificado:** `ebb9488b0e337f05db11d14acc26be54` (`Match`)
  - **SHA-1 calculado y verificado:** `c1870f834ae3d71afc72252b7132a5792ae06471` (`Match`)
  - Sectores totales leídos: `61.440.000` sectores.
  - Sectores defectuosos (Bad Sectors): **`0` (No bad sectors found)**.
- **Ficheros generados:** Segmentos `PENDRIVE_ESCENA.E01` hasta `PENDRIVE_ESCENA.E17` y log pericial `PENDRIVE_ESCENA.E01.txt`.
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/10-adquisicion-pendrive-ftk-verificada.png" alt="Adquisición física de pendrive en FTK Imager con 0 bad sectors" width="650" />
  </p>
- **Bloqueo de escritura:** No se conserva constancia (ni registro, ni captura, ni script) de que se activara un bloqueo de escritura antes de conectar el pendrive para su adquisición. Véase el apartado 6.
- **Verificación de la marca en la imagen del pendrive:**
  - **Hora:** 13:43 h · 11/11/2026
  - **Acción:** Apertura de `PENDRIVE_ESCENA.E01` en FTK Imager 3.4.0.5 con `File → Add Evidence Item → Image File`, que muestra el contenido de la imagen sin montarla y sin escribir en ella. Se localizó el fichero testigo `marca-nataliaalejo.txt` en la raíz del volumen `EVIDENCIA [exFAT]`, y el visor de contenido muestra la cadena `AFI-NataliaAlejo-20261103`.
  - **Nota:** Se intentó primero montar la imagen con `File → Image Mounting`, pero FTK Imager devolvió el error `Add drive failed`. Se optó por la vía anterior (ver apartado 6).
- **Evidencia gráfica:**
  <p align="center">
    <img src="capturas/12-marca-en-pendrive-e01.png" alt="Marca pericial localizada en la raíz de la imagen del pendrive en FTK Imager" width="650" />
  </p>

---

## 3. Manifiesto Oficial de Integridad Criptográfica (`hashes/hashes.sha256`)

> **Nota de trazabilidad pericial:** El archivo `hashes/hashes.sha256` contiene única y exclusivamente las sumas de control de los artefactos y evidencias que se transfieren físicamente en el soporte de custodia al perito receptor (Eduardo Moreno). El hash previo del disco lógico `.vmdk` original (`f98ca9c5585c0fd6605d3563c0b52d7b9addfa8c3930f0568459722cf49cd6a6`) se conserva documentado en el apartado 2.6 de estas notas como testigo inmutable pre-adquisición, excluyéndose del archivo de verificación del pendrive al haberse entregado su imagen forense de trabajo en formato E01 (`FORENSIC_10_disk0.E01` a `.E04`) según directrices del caso.

```text
0401711ec86b3cbe66844d451064a0726325230105a0149aef2e7c5ab3a24e90 *FORENSIC_10-ram.raw
22818ef0752ac4f03bc54c6e1b7802bc6f0ae106f2fd7887e0839853cc0d77f3 *red.pcap
95c1959031dcf31a44e56d1f53fc6fc8fcad82f56a31f042303715686f5ae841 *FORENSIC_10.vbox
c16c987ef8f366dbd0e8557c583437c9c7720986e8460875dada482e045cb2d9 *Logs/VBox.log
a41e02f4ff5289759c347a227baa9ea30955728636316032b7f8f104dcbee4c2 *Logs/VBoxHardening.log
9b928de0e6cfcc153b519b53adb50bd0e9ec6746e211ee1869baa867238b48a9 *FORENSIC_10_disk0.E01
5389b28197d3a54d04c3a1b12723b59143710d7c7967ee89e4d7f903613db9a1 *FORENSIC_10_disk0.E02
b503ecd888033603a6eeaf21dc961339d7087256e2834c503d49ae85232d6528 *FORENSIC_10_disk0.E03
0917e7c4e82255a80ade219cf9aa1d50600518f7fa7cbd6f1ac95b392596b98f *FORENSIC_10_disk0.E04
14eb27dcdb93fb32ace9a02c47fb0b064b401f608b11a7863f8c1c11314219a4 *FORENSIC_10_disk0.E01.txt
d337810f3b08c11b6a842379e45fcc630fe2359945bc008728cef7c11eb2528f *PENDRIVE_ESCENA.E01
92575195723e4347ae90b3e875fcfb0f2356da6438c24b87838234c128c08fa7 *PENDRIVE_ESCENA.E02
6a0fdc411e450bc65e2f039f5ace457824a6613d39d02d494be575c60d4e9033 *PENDRIVE_ESCENA.E03
2b683685d89dc0f1eadfede40e2b8a37a3f999b8bd409ab6edd8146f937b36b9 *PENDRIVE_ESCENA.E04
2ef2c6dc7dd7426d60694b6f3f5838ec6c6b3ce020c5c0e8217fef211d32564b *PENDRIVE_ESCENA.E05
d465f382d64b7062d88bbb1bdae06dbb630de2e87a1181efe3280ef463b2cfa8 *PENDRIVE_ESCENA.E06
ec04e37593e2ef20cbd5ec49974313e337f904f6536164e8ef96d68cc201bffb *PENDRIVE_ESCENA.E07
c9099cd72e16506d8bfd4aa4d7d8eed065a51636ddb1e223360c6e30bf6facf5 *PENDRIVE_ESCENA.E08
201c3befbe63d713eca7c0fd70b85510a369787cf04e6060a3fab083beb039c1 *PENDRIVE_ESCENA.E09
fa66a08191646bc81f436a47426ad117aa9b6b0320ed45681772d7a548f09f13 *PENDRIVE_ESCENA.E10
645cef5d7befafe5897ad95084671e5c9ca879cf38fa2533d4958686d0a32fa0 *PENDRIVE_ESCENA.E11
d88ebfb833e85d4a9058370f500af45cce963899f2988eae5dcccd2c60e36bdf *PENDRIVE_ESCENA.E12
43035230dbd3e4489f4fd2a3bfccbaf09422540967a96232c35ab99778ca1ed8 *PENDRIVE_ESCENA.E13
990dbda1fb27e13eaa2f61c765dd6339984bad8863d96bac1366f91ded109890 *PENDRIVE_ESCENA.E14
fdc4e072fedc45bfd8ca1746b4ca9c9010b08ce363904ff7a9fda7fe69877bf5 *PENDRIVE_ESCENA.E15
245a99f816209e435b66e5d5d182a23ad873e2b934067d62b74a2f466753b1bd *PENDRIVE_ESCENA.E16
fe44711c4ea2ff2f7294c46f791ed1f88862b7d6823f70fa24aa8f52c94d79a9 *PENDRIVE_ESCENA.E17
c1cd05171a868b78803139384df1f46add3a8dde03506dabb0fb91ce1440dec6 *PENDRIVE_ESCENA.E01.txt
```

---

## 4. Verificación de Integridad Cruzada en Pareja (28/28 OK)

Se realizó la verificación formal de todas las evidencias volcadas sobre el soporte de custodia USB en la estación de trabajo de **Eduardo Moreno Rodríguez** (`ASUS@LAPTOP-INN5P1GR`), ejecutando el comando de comprobación en entorno Git Bash:

```bash
cd /e/hashes && sha256sum -c hashes.sha256
```

- **Resultado:** **28/28 ficheros devolvieron `OK` con 0 errores y 0 avisos de advertencia**, ratificando la perfecta correspondencia matemática y la ausencia total de corrupción de datos durante el traspaso físico de la prueba.

<p align="center">
  <img src="capturas/13-verificacion-hashes-receptor.png" alt="Verificación de los 28 hashes SHA-256 en la estación del perito receptor" width="700" />
</p>

> **Nota sobre la captura:** La captura anterior es la comprobación del perito receptor, Eduardo Moreno, en su propia estación (`ASUS@LAPTOP-INN5P1GR`, carpeta `/e/hashes`), realizada durante la transferencia 1 del registro de custodia (05/11/2026, 13:41 h). Devolvió `OK` en las 28 líneas del manifiesto.

Previamente, la perito adquirente había realizado la misma comprobación en su propia estación (`esana@Natalia`, carpeta `/d/hashes`), con el mismo resultado:

<p align="center">
  <img src="capturas/11-verificacion-hashes-sha256-ok.png" alt="Verificación de los 28 hashes SHA-256 en la estación de la perito adquirente" width="700" />
</p>

---

## 5. Conclusiones Periciales de la Fase de Adquisición

1. **Inmutabilidad de la Prueba:** Todas las evidencias fueron adquiridas siguiendo el principio de no alteración y orden de volatilidad estricto. La estación comprometida fue apagada por hardware para asegurar el estado forense exacto de los clusters de disco.
2. **Trazabilidad Continua:** Se emitió el acta de adquisición pericial y el registro de cadena de custodia de 3 páginas con firmas vectorizadas, formalizando el depósito y traspaso a Eduardo Moreno sin lagunas temporales.
3. **Certificación Criptográfica:** La verificación independiente en el equipo receptor arrojó correspondencia del 100% en todas las sumas SHA-256, garantizando que el material entregado es idéntico al intervenido en la escena para la posterior fase de análisis (UD2).

---

## 6. Incidencias y Limitaciones

Se dejan aquí, aunque no afecten a la integridad de las evidencias, las incidencias y las limitaciones del procedimiento:

1. **Triaje sin KAPE ni Velociraptor:** El triaje en vivo se realizó con el script `respuesta-en-vivo.ps1` y comandos nativos del sistema (apartado 2.5), sin utilizar KAPE ni un recolector offline de Velociraptor. Como consecuencia, no se recolectó la tabla de ficheros `$MFT` en el triaje y **no se ha comprobado la marca en el triaje**. La marca sí se ha verificado en la RAM (apartado 2.4), en el disco (apartado 2.7) y en el pendrive (apartado 2.8).
2. **Volcado de RAM desde el hipervisor:** La memoria se adquirió con `VBoxManage debugvm dumpvmcore` en lugar de con una herramienta ejecutada dentro de la máquina (como DumpIt), por la justificación técnica recogida en el apartado 2.4.
3. **Error al montar la imagen del pendrive:** Al intentar montar `PENDRIVE_ESCENA.E01` con `File → Image Mounting` en FTK Imager, el programa devolvió `Add drive failed`. No se insistió en el montaje: se consultó el contenido de la imagen con `File → Add Evidence Item`, que la abre en modo lectura (apartado 2.8).
4. **Reconexión del pendrive original:** El 11/11/2026, entre las 13:31 y las 13:41 h, durante la revisión del trabajo, se conectó de nuevo el pendrive original a la estación **sin bloqueo de escritura**, únicamente para consultar su contenido. Se listaron sus ficheros sin abrirlos, copiarlos ni modificarlos. Contenía `marca-nataliaalejo.txt` (30 bytes, creado el 03/11/2026 a las 16:09) y la carpeta de sistema `System Volume Information` (creada el 03/11/2026 a las 14:40, anterior a la documentación del apartado 2.1; el historial USB de Windows registra la primera conexión del pendrive a la estación de la perito el 03/11/2026 a las 14:37 h). **No existe ningún fichero con fecha de creación o modificación del 11/11/2026.** La evidencia de referencia es la imagen E01 verificada, no el soporte original.
5. **Bloqueo de escritura del pendrive sin constancia:** La adquisición del pendrive (apartado 2.8) exigía activar y comprobar un bloqueo de escritura antes de conectarlo. **No se conserva constancia de que se hiciera**: no existe `bloqueo-usb.log` ni captura del estado `PROTEGIDO`, y una búsqueda del script y de otras herramientas de bloqueo en la estación de la perito (11/11/2026) no encontró ningún resultado. Por ello, la adquisición debe considerarse realizada **sin bloqueo de escritura verificado**. Como datos comprobados que lo matizan, sin sustituir al bloqueo: (a) la imagen E01 quedó verificada con MD5 y SHA-1 (`Match`) y 0 sectores defectuosos; (b) el listado del pendrive original del 11/11/2026 no muestra ningún fichero con fecha posterior a la marca del 03/11/2026 (16:09 h), y `System Volume Information` es anterior a la documentación del apartado 2.1 (03/11/2026, 14:40 h).
6. **El `.vmdk` no forma parte de la entrega:** El disco `.vmdk` original no se entrega en el soporte de custodia, por lo que no figura en `hashes.sha256`, que contiene los 28 ficheros entregados. Su contenido está en la imagen E01 del disco, verificada con MD5 y SHA-1 (`Match`); su SHA-256 se conserva en el apartado 2.6 y se recomprobó el 11/11/2026.

---

## 7. Corrección del Registro de Custodia (Versión 2)

El `registro-custodia.pdf` de este repositorio es la **versión 2**, rectificada y firmada el 11/11/2026 por ambos peritos, que **sustituye a la versión 1** firmada el 06/11/2026. La versión 1 se conserva en el historial del repositorio. La versión 2 lo indica en su cabecera. La perita adquirente firmó con su firma y el perito receptor firmó a mano sobre el PDF. Las discrepancias detectadas en la versión 1 entre sus valores y los ficheros reales, contrastados con los registros de FTK Imager y con el manifiesto, son estas:

| Campo del registro de custodia | Valor en la versión 1 | Valor en la versión 2 (correcto) | Fuente de verificación |
| :--- | :--- | :--- | :--- |
| SHA-256 del `.vmdk` previo | `da15d0eb…` | `f98ca9c5585c0fd6605d3563c0b52d7b9addfa8c3930f0568459722cf49cd6a6` | Apartado 2.6 y recomprobación del 11/11/2026 |
| Tamaño de `FORENSIC_10-ram.raw` | 1.298.544.640 bytes | 1.214.117.728 bytes | Fichero original y apartado 2.4 |
| Tamaño de `red.pcap` | 2.352.128 bytes | 2.241.370 bytes | Fichero original y apartado 2.6 |
| SHA-1 de la imagen del disco | `cb255554…` | `5d36b49702c656dbb3997b77b88df2bc3c5a68f6` | `FORENSIC_10_disk0.E01.txt` |
| SHA-1 de la imagen del pendrive | `188fc836…` | `c1870f834ae3d71afc72252b7132a5792ae06471` | `PENDRIVE_ESCENA.E01.txt` |
| Fecha y hora de la Transferencia 0 | 03/11/2026 · 18:00 h | Volcado de RAM y apagado: 03/11/2026 (17:29–18:00 h). Imágenes E01: 04/11/2026 (21:28–23:35 h) | Apartados 2.4, 2.6, 2.7 y 2.8 |
| Capacidad del pendrive | 26,2 GB | 29,29 GB (los 26,2 GB son el tamaño total de los segmentos E01) | Apartado 2.1 y `PENDRIVE_ESCENA.E01.txt` |
| Orden de las fases en la tabla | Triaje en vivo antes que la RAM | RAM (17:29 h) antes que el triaje (17:56 h) | Apartados 2.4 y 2.5 |
| Número de registros del manifiesto `hashes.sha256` | 25 registros | 28 registros | `hashes/hashes.sha256` |
| Resultado de la verificación del perito receptor (transferencia 1) | 25/25 ficheros `OK` | 28/28 ficheros `OK` | Apartado 4 y captura 13 |
| Técnica del triaje en vivo (hoja 1, fase de triaje) | «Script PowerShell / Volatilidad» | Script `respuesta-en-vivo.ps1` y comandos nativos del sistema (no se usó Volatility) | Apartado 2.5 |
| Garantía de inmutabilidad (hoja 1, apartado 2) | «…mediante bloqueadores de escritura…» | No se conserva constancia de que se utilizara bloqueo de escritura en la adquisición del pendrive | Apartado 6, incidencia 5 |

**Origen de las discrepancias en hashes, tamaños y recuento:** En la versión 1, los SHA-1 de las dos imágenes E01, el SHA-256 truncado del `.vmdk`, los tamaños en bytes de `FORENSIC_10-ram.raw` y `red.pcap` y el recuento «25/25» se escribieron sin consultar los ficheros reales ni los logs de FTK Imager, sin ejecutar ningún comando de cálculo de hash y sin advertir de su carácter provisional. El registro se firmó sin contrastar esos valores con la evidencia, y las discrepancias se detectaron el 11/11/2026 al verificarlos. Los valores válidos son los certificados por FTK Imager en `FORENSIC_10_disk0.E01.txt` y `PENDRIVE_ESCENA.E01.txt` y los del manifiesto `hashes.sha256`, comprobado sobre los 28 ficheros reales.

El resto de los datos del registro (identificadores de evidencia, SHA-256 de los ficheros, fechas de las transferencias 1 y 2) es correcto y coincide con `hashes/hashes.sha256`.

**Rectificación del acta de adquisición:** El `acta-adquisicion.pdf` se rectificó el 11/11/2026 (consta en su cabecera, y sustituye a la de 04/11/2026) para incorporar el apartado 2, «Cronología de Acciones», con la hora de cada paso y la mención del disco virtual utilizado como unidad de respuesta. Las evidencias, las herramientas y los hashes del resto del acta no han cambiado.

---

## 8. Verificación Posterior de Integridad (11/11/2026)

- **Fecha:** 11/11/2026, con posterioridad a la devolución del soporte de custodia.
- **Acción:** Se volvió a comprobar la integridad de las dos copias de las evidencias: el soporte de custodia devuelto (unidad `D:`, `Alejo 1Tb`) y la copia conservada en la estación de la perito (`Desktop\afi-ud1-adquisicion\hashes`). Para cada copia se leyó `hashes.sha256`, se calculó con `Get-FileHash -Algorithm SHA256` el hash de cada fichero y se comparó con el esperado. La operación es de solo lectura.
- **Resultados:**

| Copia | Inicio | Fin | Resultado |
| :--- | :---: | :---: | :--- |
| Soporte de custodia (`D:\hashes`) | 13:56 h | 14:11 h | **28 `OK`, 0 fallos** |
| Estación de la perito (`Desktop`) | 14:11 h | 14:12 h | **28 `OK`, 0 fallos** |

- **Manifiesto:** el propio `hashes.sha256` es idéntico en ambas copias (SHA-256: `33d46a9faa5c59d0893f9dcfa69cea1e61398b31bd6a561a17a9e6d63556ee6f`).
- **Conclusión:** las evidencias del soporte de custodia devuelto y las conservadas en la estación de la perito son idénticas entre sí y coinciden con el manifiesto, por lo que no han sufrido alteración desde su adquisición.
- **Imagen maestra y copia de trabajo:** A fecha de 11/11/2026, y tras verificar la identidad de ambas copias, se designa como **imagen maestra** la conservada en el soporte de custodia (`D:`), que permanece sin modificar, y como **copia de trabajo** para la UD2 la conservada en la estación de la perito. Las imágenes fueron generadas originalmente en la estación de la perito por FTK Imager y volcadas después al soporte de custodia.
