# Cuaderno de Notas de Trabajo: Adquisición Forense
**Caso:** Bahía Sistemas / Almadraba Diseño  
**Perito / Estudiante:** Natalia Alejo Pérez (Alumno 20)  
**Identificador de Marca:** `AFI-NataliaAlejo-20261103`  
**Fecha de intervención:** 3 de noviembre de 2026  

---

## 1. Datos del Caso y Escena Inicial
- **Entorno investigado:** Equipo Windows comprometido en el cuarto de informática de Almadraba Diseño.
- **Nombre de máquina / Dominio:** `FORENSE-06` (Workgroup: `FORENSICS`).
- **Hardware virtual:** 1 procesador, 1.00 GB de memoria RAM física.
- **Estado al inicio:** Encendido.
- **Evidencia física anexa:** Pendrive USB sin etiquetar encontrado junto al teclado.
- **Dispositivo USB documentado:** General UDisk USB Device (32 GB comercial / 29,29 GB reales, S/N: `2107221816162859250002`).

---

## 2. Registro Cronológico de Acciones Paso a Paso (Orden de Volatilidad)

### 2.1 Preparación del Entorno y Documentación Previa de la Evidencia Física
- **Hora:** 15:30 h
- **Acción:** Inspección visual y documentación técnica del pendrive encontrado antes de su conexión. Se fotografiaron sus características físicas (pendrive giratorio rojo/metálico) y se registraron sus propiedades de hardware en la estación pericial: fabricante genérico (`General UDisk USB Device`), número de serie `2107221816162859250002`, formateado en `exFAT`.
- **Evidencias gráficas:**
  - `capturas/01-pendrive-foto.png`
  - `capturas/02-pendrive-propiedades-hardware.png`
  - `capturas/03-pendrive-capacidad-exfat.png`

### 2.2 Configuración del Medio de Respuesta y Red
- **Hora:** 15:42 h
- **Acción:** Siguiendo las directrices del enunciado para optimizar el almacenamiento y preservar los medios físicos externos, se configuró un segundo disco virtual dedicado (`USB_RESPUESTA.vdi`, 25 GB) sobre la controladora SAS de la máquina `FORENSIC_10`. Este disco actúa como el "disco de respuesta" para alojar las herramientas forenses y recibir todas las salidas sin escribir en el disco del sistema (`FORENSIC_10_disk0.vmdk`). Se inicializó en MBR y se formateó en NTFS con la etiqueta `RESPUESTA (D:)`.
- **Captura de tráfico de red (TAP):** Activación de la traza de red en modo monitor desde el exterior mediante comando VBoxManage:
  ```bash
  VBoxManage modifyvm "FORENSIC_10" --nictracefile1 "hashes/red.pcap"
  VBoxManage modifyvm "FORENSIC_10" --nictrace1 on
  ```

### 2.3 Arranque y Fijación de la Marca de Autoría
- **Hora del sistema virtual:** 3:58 PM (15:58 h) · 11/3/2026
- **Hora real del perito:** 15:58 h · 03/11/2026
- **Desfase temporal identificado:** 0 minutos (el reloj de la máquina virtual coincide con el reloj local de la estación de trabajo).
- **Inyección de marca forense:**
  1. Apertura de sesión con credenciales de administración facilitadas (`Administrador` / `HSrupaliuwCCvh`).
  2. Apertura del Bloc de notas (`notepad`) con la marca personal `AFI-NataliaAlejo-20261103`, dejándolo en memoria activa sin guardar para garantizar su persistencia en el posterior volcado de RAM.
  3. Creación del archivo testigo `marca-nataliaalejo.txt` en el Escritorio del equipo y réplica en la raíz del pendrive físico de la escena.
- **Evidencia gráfica:**
  - `capturas/04-estado-inicial-marca-ram.png`

### 2.4 Adquisición Forense de la Memoria RAM (En Vivo)
- **Hora:** 17:29 h
- **Herramienta utilizada:** VirtualBox Core Dump a nivel de hipervisor (`VBoxManage debugvm dumpvmcore`).
- **Justificación técnica:** Se optó por la extracción desde el hipervisor para garantizar un impacto nulo (0% de alteración) en el espacio de usuario del sistema operativo investigado, mitigando problemas de compatibilidad de binarios antiguos de DumpIt.
- **Fichero generado:** `hashes/FORENSIC_10-ram.raw` (1.214.117.728 bytes / 1,21 GB).
- **Hash de integridad SHA-256:**
  `0401711ec86b3cbe66844d451064a0726325230105a0149aef2e7c5ab3a24e90`
- **Verificación de la marca del perito en la RAM:** Búsqueda en texto UTF-16 en el volcado de memoria. Se localizó con éxito la cadena `AFI-NataliaAlejo-20261103` en el offset de bytes `276165056`.
- **Evidencia gráfica:**
  - `capturas/05-verificacion-marca-ram.png`

### 2.5 Recolección de Datos Volátiles
- **Hora:** 17:56 h
- **Herramienta utilizada:** Comandos nativos de respuesta a incidentes volcados hacia la unidad de respuesta `D:\salida\`.
- **Artefactos adquiridos:**
  - `01-fecha.txt`: Registro de fecha y hora local del sistema.
  - `06-netstat.txt`: Conexiones TCP/UDP activas y mapeo de procesos con PIDs (`netstat -ano`).
  - `10-red.txt`: Configuración completa de interfaces IP, gateways y servidores DNS (`ipconfig /all`).
  - `12-procesos.txt`: Listado completo de procesos en ejecución del atacante (`tasklist`).
- **Evidencia gráfica:**
  - `capturas/06-datos-volatiles-salida.png`

### 2.6 Comprobación de Cifrado de Discos y Apagado Forense
- **Hora:** 17:59 h
- **Comprobación de BitLocker:** Ejecución de `manage-bde -status` en la consola administrativa.
  - **Resultado:** Ningún volumen se encuentra cifrado.
    - Volumen `C:` (Sistema): `Conversion Status: Fully Decrypted`, `Percentage Encrypted: 0%`, `Protection Status: Protection Off`.
    - Volumen `D:` (Respuesta): `Conversion Status: Fully Decrypted`, `Protection Off`.
- **Evidencia gráfica:**
  - `capturas/07-comprobacion-cifrado-bitlocker.png`
- **Decisión de apagado:** Al confirmarse la ausencia total de cifrado de volumen (lo que descarta el riesgo de bloqueo de particiones tras reinicio), se procedió al **apagado inmediato por hardware virtual (`poweroff`)** a las 18:00 h, garantizando que el sistema no ejecute scripts de apagado ni modifique registros temporales en el disco `.vmdk`.
- **Cierre de captura de red:** Se detuvo la traza TAP. Fichero consolidado: `hashes/red.pcap` (2.241.370 bytes, SHA-256: `22818ef0752ac4f03bc54c6e1b7802bc6f0ae106f2fd7887e0839853cc0d77f3`).
- **Fijación de Hash previo del disco original:** Inmediatamente tras el apagado, se calculó el SHA-256 del disco `.vmdk`:
  `f98ca9c5585c0fd6605d3563c0b52d7b9addfa8c3930f0568459722cf49cd6a6`

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
- **Evidencia gráfica:**
  - `capturas/08-adquisicion-ftk-e01-verificada.png`
  - `capturas/09-marca-personal-en-disco-e01.png` (Verificación de `marca-nataliaalejo.txt` en `C:\Users\Administrador\Desktop` dentro del E01)

---

## 3. Estado Actual de Hashes de Integridad (`hashes/hashes.sha256`)
```text
0401711ec86b3cbe66844d451064a0726325230105a0149aef2e7c5ab3a24e90 *FORENSIC_10-ram.raw
22818ef0752ac4f03bc54c6e1b7802bc6f0ae106f2fd7887e0839853cc0d77f3 *red.pcap
f98ca9c5585c0fd6605d3563c0b52d7b9addfa8c3930f0568459722cf49cd6a6 *FORENSIC_10_disk0.vmdk
9b928de0e6cfcc153b519b53adb50bd0e9ec6746e211ee1869baa867238b48a9 *FORENSIC_10_disk0.E01
5389b28197d3a54d04c3a1b12723b59143710d7c7967ee89e4d7f903613db9a1 *FORENSIC_10_disk0.E02
b503ecd888033603a6eeaf21dc961339d7087256e2834c503d49ae85232d6528 *FORENSIC_10_disk0.E03
0917e7c4e82255a80ade219cf9aa1d50600518f7fa7cbd6f1ac95b392596b98f *FORENSIC_10_disk0.E04
14eb27dcdb93fb32ace9a02c47fb0b064b401f608b11a7863f8c1c11314219a4 *FORENSIC_10_disk0.E01.txt
```
