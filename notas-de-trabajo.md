# Cuaderno de Notas de Trabajo: Adquisición Forense
**Caso:** Bahía Sistemas / Almadraba Diseño  
**Perito / Estudiante:** Natalia Alejo Pérez  
**Identificador de Marca:** `AFI-NataliaAlejo-20261103`  
**Fecha de intervención:** 3 de noviembre de 2026  

---

## 1. Datos del Caso y Escena Inicial
- **Entorno investigado:** Equipo Windows comprometido en el cuarto de informática de Almadraba Diseño.
- **Estado al inicio:** Encendido.
- **Evidencia anexa:** Pendrive USB sin etiquetar junto al teclado.
- **Dispositivo USB sospechoso:** General UDisk USB Device (32 GB, S/N: `2107221816162859250002`).

---

## 2. Registro Cronológico de Acciones Paso a Paso

### 2.1 Preparación del Entorno y Documentación Previa
- **Hora:** 15:30 h
- **Acción:** Inspección y documentación de la evidencia física encontrada (pendrive rojo giratorio). Registro de sus propiedades de hardware en Windows anfitrión: fabricante genérico (`General UDisk USB Device`), número de serie `2107221816162859250002`, capacidad de 32 GB (29,29 GB reales) formateado en `exFAT`.
- **Evidencias gráficas:**
  - `capturas/01-pendrive-foto.png`
  - `capturas/02-pendrive-propiedades-hardware.png`
  - `capturas/03-pendrive-capacidad-exfat.png`

### 2.2 Configuración del Medio de Respuesta y Red
- **Hora:** 15:42 h
- **Acción:** Siguiendo las directrices del enunciado para optimizar el almacenamiento y preservar los medios físicos externos, se configuró un segundo disco virtual dedicado (`USB_RESPUESTA.vdi`, 25 GB) sobre la controladora SAS de la máquina `FORENSIC_10`. Este disco actúa como el "disco de respuesta" para alojar las herramientas forenses y recibir todas las salidas sin escribir en el disco del sistema (`FORENSIC_10_disk0.vmdk`).
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

---

## 3. Próximas Acciones (En Progreso)
1. **Volcado de Memoria RAM:** Adquisición con `DumpIt` hacia la unidad de respuesta y cálculo de hash SHA-256.
2. **Triaje de datos volátiles:** Ejecución de `respuesta-en-vivo.ps1` y recolección de artefactos.
3. **Comprobación de Cifrado y Apagado Ordenado.**
4. **Adquisición Post-Mortem:** Imagen E01 del disco `.vmdk` y del pendrive con bloqueo de escritura.
