# P02: Adquirir un Equipo Comprometido (AFI · UD1)

- **Perito / Estudiante:** Natalia Alejo Pérez (Alumno 20)
- **Módulo:** Análisis Forense Informático (AFI)
- **Curso:** Curso de Especialización en Ciberseguridad
- **Centro Educativo:** IES Rafael Alberti
- **Caso Pericial:** Bahía Sistemas / Almadraba Diseño
- **Estación Investigada:** `FORENSIC_10` (Windows 10 Pro / Grupo de Trabajo `FORENSICS`)
- **Perito Receptor / Custodio:** Eduardo Moreno Rodríguez (`Edu DAM`)
- **Fecha de Intervención:** 3 al 5 de noviembre de 2026

---

## 🎯 Resumen Ejecutivo de la Adquisición Pericial

Este repositorio contiene la memoria técnica, registros de integridad y documentación legal del procedimiento de adquisición forense en vivo y post-mortem ejecutado sobre la estación de trabajo comprometida y el soporte extraíble localizado en el cuarto de informática de Almadraba Diseño.

El procedimiento se ha desarrollado siguiendo el **orden de volatilidad (RFC 3227)** y las normas internacionales de aseguramiento pericial **UNE 71506:2013** e **ISO/IEC 27037:2012**.

### Resultados principales
- **Memoria RAM:** Extracción de memoria RAM física (1,21 GB) realizada a nivel de hipervisor (`debugvm dumpvmcore`), sin ejecutar herramientas de captura dentro del sistema investigado.
- **Marca de autoría:** Localización de la cadena testigo `AFI-NataliaAlejo-20261103` en el offset exacto `276165056` (0x10760000) del volcado de RAM y réplica en disco montado.
- **Imágenes E01:** Adquisición física completa del disco de sistema (`FORENSIC_10_disk0.E01` a `.E04`) y del pendrive de la escena (`PENDRIVE_ESCENA.E01` a `.E17`) en FTK Imager v3.4.0.5 arrojando **0 bad sectors** y correspondencia de hashes MD5 y SHA-1 (`Match`).
- **Verificación de hashes:** Comprobación ejecutada en Git Bash por el compañero receptor Eduardo Moreno (`ASUS@LAPTOP-INN5P1GR`): **28/28 ficheros devolvieron `OK`**.
- **Cadena de custodia:** Registro de 3 páginas con transferencia al perito receptor y devolución, firmado por ambos peritos. Sus discrepancias con los ficheros reales se corrigen en la fe de erratas (enlace 6).

---

## 📊 Inventario General de Evidencias Digitales

| ID Evidencia | Soporte / Fichero | Formato / Técnica | Tamaño Real | Hash de Integridad SHA-256 (en las imágenes E01, el del primer segmento; el resto, en `hashes.sha256`) |
| :--- | :--- | :--- | :---: | :--- |
| **EV-RAM-01** | `FORENSIC_10-ram.raw` | Volcado RAM (Hypervisor) | 1,21 GB | `0401711ec86b3cbe66844d451064a0726325230105a0149aef2e7c5ab3a24e90` |
| **EV-NET-02** | `red.pcap` | Captura Tráfico TAP Red | 2,24 MB | `22818ef0752ac4f03bc54c6e1b7802bc6f0ae106f2fd7887e0839853cc0d77f3` |
| **EV-DISK-03** | `FORENSIC_10_disk0.E01` (.E01-.E04) | Imagen E01 Disco Virtual | 4,98 GB | `9b928de0e6cfcc153b519b53adb50bd0e9ec6746e211ee1869baa867238b48a9` |
| **EV-USB-04** | `PENDRIVE_ESCENA.E01` (.E01-.E17) | Physical Image E01 USB | 26,2 GB | `d337810f3b08c11b6a842379e45fcc630fe2359945bc008728cef7c11eb2528f` |
| **EV-LOGS-05** | `FORENSIC_10.vbox` y `Logs/` | Definición VM y Trazas | 280 KB | Hashes individuales verificados en manifiesto raíz |
| **CONTROL-06** | `hashes/hashes.sha256` | Manifiesto Universal | 2,8 KB | Validación integral mediante comando `sha256sum -c` |

---

## 📁 Estructura Oficial del Repositorio de Entrega

El repositorio respeta escrupulosamente la jerarquía requerida por la cátedra de Análisis Forense:

```text
afi-ud1-adquisicion/
├── README.md               # Portada oficial, resumen ejecutivo y enlaces periciales
├── notas-de-trabajo.md     # Cuaderno de bitácora paso a paso con las 13 capturas incrustadas, incidencias y fe de erratas
├── acta-adquisicion.pdf    # Acta oficial de intervención forense debidamente cumplimentada y firmada
├── registro-custodia.pdf   # Registro de cadena de custodia de 3 páginas con doble transferencia y firmas
├── hashes/                 # Manifiesto hashes.sha256, scripts de respuesta en vivo y logs FTK
│   ├── hashes.sha256       # Manifiesto relativo con 28 registros de comprobación criptográfica
│   ├── respuesta-en-vivo.ps1 # Script pericial nativo de captura de datos volátiles de la práctica
│   ├── FORENSIC_10.vbox    # Fichero de configuración de hardware de la máquina virtual
│   ├── FORENSIC_10_disk0.E01.txt # Log oficial de adquisición de disco de FTK Imager
│   ├── PENDRIVE_ESCENA.E01.txt   # Log oficial de adquisición de pendrive de FTK Imager
│   └── Logs/               # Registros del hipervisor (VBox.log y VBoxHardening.log)
└── capturas/               # Evidencias gráficas del procedimiento (13 capturas numeradas)
```

> **Nota:** Siguiendo las instrucciones de la entrega, los ficheros de evidencia (`.raw`, `.pcap`, `.E01`, `.vmdk`) no se suben al repositorio (están excluidos con `.gitignore`) y se conservan en el soporte extraíble precintado de custodia entregado a Eduardo Moreno.

---

## 🔗 Enlaces Directos a los Documentos Clave

1. 📝 **[Cuaderno de Notas de Trabajo (Bitácora Completa)](./notas-de-trabajo.md)**: Registro exhaustivo con cronología, comandos ejecutados, justificación de la RFC 3227 y las 13 capturas de pantalla.
2. 📄 **[Acta Formal de Adquisición Forense](./acta-adquisicion.pdf)**: Documento de apertura y formalización pericial firmado digitalmente.
3. 🤝 **[Registro de Cadena de Custodia (3 Páginas)](./registro-custodia.pdf)**: Fichas técnicas de evidencias, transferencia de depósito al perito receptor Eduardo Moreno Rodríguez y devolución de cierre.
4. 🔍 **[Manifiesto de Integridad Criptográfica](./hashes/hashes.sha256)**: Tabla de sumas de comprobación SHA-256 en rutas relativas.
5. 📸 **[Galería de Evidencias Gráficas](./capturas/)**: Archivo visual con las 13 capturas periciales del caso.
6. ✏️ **[Incidencias, Limitaciones y Fe de Erratas](./notas-de-trabajo.md#6-incidencias-y-limitaciones)**: Registro de las incidencias del procedimiento y de las correcciones al registro de custodia firmado (apartados 6 y 7 de las notas).
