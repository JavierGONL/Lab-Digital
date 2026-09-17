#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/johnnycubides/digital-electronic-1-101.git"
OUT="${PWD}/digital-electronic-1-101-arch"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v git >/dev/null 2>&1 || {
    echo "Error: git no está instalado." >&2
    exit 1
}

if ! command -v rar >/dev/null 2>&1; then
    command -v yay >/dev/null 2>&1 || {
        echo "Error: 'rar' no está instalado y no encontré yay para instalarlo desde el AUR." >&2
        echo "Instala yay primero y vuelve a ejecutar este script." >&2
        exit 1
    }
    yay -S --needed --noconfirm rar
fi

rm -rf "$OUT"

echo "Clonando repositorio..."
git clone --depth 1 "$REPO" "$TMP/repo" >/dev/null
mkdir -p "$OUT"
cp -a "$TMP/repo/installTools" "$OUT/"

python3 - "$OUT/installTools" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])


def replace_once(path, old, new, label):
    s = path.read_text()
    if old not in s:
        raise SystemExit(f"[{label}] No encontré el texto esperado en {path}")
    if s.count(old) > 1:
        raise SystemExit(f"[{label}] El texto esperado aparece más de una vez en {path}")
    path.write_text(s.replace(old, new, 1))


# ---------------------------------------------------------------------------
# digital-logic-design.sh
# ---------------------------------------------------------------------------
p = root / "digital-logic-design.sh"

old_fn = '''debian-dependencias() {
  sudo apt update
  sudo apt install \\
    build-essential \\
    coreutils \\
    curl \\
    default-jre \\
    desktop-file-utils \\
    gcc \\
    gcc-riscv64-unknown-elf \\
    git \\
    ngspice \\
    picocom \\
    pulseview \\
    python3-venv \\
    shared-mime-info \\
    sigrok-firmware-fx2lafw \\
    tar \\
    unzip \\
    wget \\
    -y || return 1

  if command -v node >/dev/null 2>&1; then
    echo "Using existing Node.js: $(node --version)"

    if ! command -v npm >/dev/null 2>&1; then
      echo "Node.js is installed, but npm is not available." >&2
      echo "Install npm using the same Node.js installation method." >&2
      return 1
    fi

    echo "Using existing npm: $(npm --version)"
    return 0
  fi

  sudo apt install nodejs npm -y
}'''

new_fn = '''arch-dependencias() {
  sudo pacman -Syu --needed --noconfirm \\
    base-devel \\
    coreutils \\
    curl \\
    desktop-file-utils \\
    gcc \\
    git \\
    jre-openjdk \\
    ngspice \\
    picocom \\
    pulseview \\
    python \\
    riscv64-elf-gcc \\
    shared-mime-info \\
    sigrok-firmware-fx2lafw \\
    tar \\
    unzip \\
    wget || return 1

  if command -v node >/dev/null 2>&1; then
    echo "Using existing Node.js: $(node --version)"

    if ! command -v npm >/dev/null 2>&1; then
      echo "Node.js is installed, but npm is not available." >&2
      echo "Install npm using the same Node.js installation method." >&2
      return 1
    fi

    echo "Using existing npm: $(npm --version)"
    return 0
  fi

  sudo pacman -S --needed --noconfirm nodejs npm
}'''

replace_once(p, old_fn, new_fn, "digital-logic-design.sh: arch-dependencias()")

replace_once(
    p,
    'echo "  debian-dependencias  Install Debian system packages"',
    'echo "  arch-dependencias  Install Arch Linux system packages"',
    "digital-logic-design.sh: help text",
)

replace_once(
    p,
    'echo "  ./digital-logic-design.sh debian-dependencias"',
    'echo "  ./digital-logic-design.sh arch-dependencias"',
    "digital-logic-design.sh: help example",
)

replace_once(
    p,
    '''  debian-dependencias)
    debian-dependencias
    ;;
  oss_cad_suite)''',
    '''  arch-dependencias)
    arch-dependencias
    ;;
  oss_cad_suite)''',
    "digital-logic-design.sh: case dispatcher",
)

replace_once(
    p,
    '''  unset -f \\
    debian-dependencias \\
    oss_cad_suite \\''',
    '''  unset -f \\
    arch-dependencias \\
    oss_cad_suite \\''',
    "digital-logic-design.sh: unset -f list",
)

# ---------------------------------------------------------------------------
# hw-permissions.sh
# ---------------------------------------------------------------------------
p = root / "hw-permissions.sh"
replace_once(
    p,
    "sudo usermod -a $USER -G plugdev",
    'sudo usermod -a -G uucp "$USER"',
    "hw-permissions.sh: plugdev",
)
replace_once(
    p,
    "sudo usermod -a -G dialout `whoami`",
    'sudo usermod -a -G uucp "$(whoami)"',
    "hw-permissions.sh: dialout",
)

# ---------------------------------------------------------------------------
# geany.md
# ---------------------------------------------------------------------------
p = root / "geany.md"
replace_once(p, "En debian:", "En Arch Linux:", "geany.md: heading")
replace_once(
    p,
    "sudo apt install geany geany-plugins",
    "sudo pacman -S --needed geany geany-plugins",
    "geany.md: install",
)

# ---------------------------------------------------------------------------
# how-install-linux.md
# ---------------------------------------------------------------------------
p = root / "how-install-linux.md"
replace_once(
    p,
    "Para el caso de Debian y la mayoría de sus derivados se hace uso de algunos gestores de paquetes que facilitan el proceso de instalación de los programas; tal es el caso de **apt**, **apt-get** o **aptitude**.",
    "Para el caso de Arch Linux se hace uso del gestor de paquetes **pacman**, y para paquetes del AUR puede utilizarse un helper como **yay**.",
    "how-install-linux.md: intro",
)
replace_once(
    p,
    "A continuación se explica el proceso de uso **apt**:",
    "A continuación se explica el proceso de uso **pacman**:",
    "how-install-linux.md: subheading",
)
replace_once(
    p,
    "| `apt update` | Actualiza los apuntadores de los sources list para que pueda encontrar los servidores donde están los paquetes de los programas |",
    "| `pacman -Sy` | Actualiza las bases de datos de paquetes disponibles en los repositorios |",
    "how-install-linux.md: table update",
)
replace_once(
    p,
    "| `apt install paquete` | Permite instalar una aplicación con la opción de aceptar algunas condiciones como por ejemplo instalación de dependencias |",
    "| `pacman -S paquete` | Permite instalar una aplicación junto con sus dependencias |",
    "how-install-linux.md: table install",
)
replace_once(
    p,
    "| `apt install -f` | Tratará de reparar el funcionamiento de una aplicación a través de por ejemplo la instalación de dependencias rotas, sino lo logra, es posible que desinstale la aplicación y se requiera un procedimiento manual |",
    "| `pacman -Syu` | Sincroniza las bases de datos y actualiza los paquetes del sistema |",
    "how-install-linux.md: table fix",
)
replace_once(
    p,
    "| `apt remove paquete` | Desinstala un paquete |",
    "| `pacman -R paquete` | Desinstala un paquete |",
    "how-install-linux.md: table remove",
)

# ---------------------------------------------------------------------------
# conda-and-tools.md
# ---------------------------------------------------------------------------
p = root / "conda-and-tools.md"
replace_once(
    p,
    "Para las distribuciones basadas en debian, puede ejecutar el siguiente comando:",
    "Para Arch Linux puede ejecutar el siguiente comando:",
    "conda-and-tools.md: intro",
)
replace_once(
    p,
    "sudo apt update\nsudo apt install eog picocom imagemagick curl wget default-jdk git pulseview sigrok-firmware-fx2lafw ngspice gcc build-essential -y",
    "sudo pacman -Syu --needed --noconfirm eog picocom imagemagick curl wget jdk-openjdk git pulseview sigrok-firmware-fx2lafw ngspice gcc base-devel",
    "conda-and-tools.md: install block",
)
replace_once(p, "grupo *dialout*", "grupo *uucp*", "conda-and-tools.md: dialout")
replace_once(
    p,
    "sudo apt install libfuse2",
    "sudo pacman -S --needed fuse2",
    "conda-and-tools.md: libfuse2",
)

# ---------------------------------------------------------------------------
# notas-instalacion-herramientas.md
# ---------------------------------------------------------------------------
p = root / "notas-instalacion-herramientas.md"
replace_once(
    p,
    "$ sudo apt install openjdk-11-jdk # > Si es una distribución basada en debian\n$ pamac install jdk-openjdk # > Si es una distribución basada en arch",
    "$ sudo pacman -S jre-openjdk # > Si solo necesita el JRE\n$ sudo pacman -S jdk-openjdk # > Si necesita el JDK completo (recomendado)",
    "notas-instalacion-herramientas.md: jdk lines",
)
replace_once(
    p,
    "sudo apt install libfuse2",
    "sudo pacman -S --needed fuse2",
    "notas-instalacion-herramientas.md: libfuse2",
)
replace_once(p, "grupo *dialout*", "grupo *uucp*", "notas-instalacion-herramientas.md: dialout")

# ---------------------------------------------------------------------------
# instruments/logic-analizer-24MHz-8CH/README.md
# ---------------------------------------------------------------------------
p = root / "instruments/logic-analizer-24MHz-8CH/README.md"
replace_once(
    p,
    "sudo apt install pulseview",
    "sudo pacman -S --needed pulseview",
    "logic-analizer README: pulseview",
)
replace_once(
    p,
    "sudo apt install sigrok-firmware-fx2lafw",
    "sudo pacman -S --needed sigrok-firmware-fx2lafw",
    "logic-analizer README: firmware",
)
replace_once(
    p,
    "Seguir las instrucciones de Instalación para sistemas basados en Debian:",
    "Seguir las instrucciones de Instalación para sistemas basados en Arch Linux:",
    "logic-analizer README: saleae",
)

# ---------------------------------------------------------------------------
# quartus.md
# ---------------------------------------------------------------------------
p = root / "quartus.md"
s = p.read_text()
if s.count('GROUP="plugdev"') != 3:
    raise SystemExit("quartus.md: se esperaban 3 ocurrencias de GROUP=\"plugdev\"")
p.write_text(s.replace('GROUP="plugdev"', 'GROUP="uucp"'))

# ---------------------------------------------------------------------------
# README.md
# ---------------------------------------------------------------------------
p = root / "README.md"
replace_once(
    p,
    "   ./digital-logic-design.sh debian-dependencias",
    "   ./digital-logic-design.sh arch-dependencias",
    "README.md: quickstart",
)
replace_once(
    p,
    '''`debian-dependencias` contiene la instalación mediante APT para Debian y sus
derivados. La lista de paquetes se mantiene solamente dentro de
`digital-logic-design.sh`. En Arch Linux u otra distribución se puede revisar
esa función y crear el comando homólogo con el administrador de paquetes y los
nombres correspondientes de esa distribución.''',
    '''`arch-dependencias` contiene la instalación mediante pacman para Arch Linux.
La lista de paquetes se mantiene solamente dentro de
`digital-logic-design.sh`.''',
    "README.md: dependencias explanation",
)
replace_once(
    p,
    '''Netlist2SVG requiere Node.js y npm. La función `debian-dependencias` conserva
una instalación existente de Node.js, por ejemplo una administrada mediante
nvm. Si `node` no está disponible, instala `nodejs` y `npm` desde APT. Si
encuentra `node` pero no encuentra `npm`, se detiene para evitar mezclar
instalaciones y muestra cómo corregirlo.''',
    '''Netlist2SVG requiere Node.js y npm. La función `arch-dependencias` conserva
una instalación existente de Node.js, por ejemplo una administrada mediante
nvm. Si `node` no está disponible, instala `nodejs` y `npm` con pacman. Si
encuentra `node` pero no encuentra `npm`, se detiene para evitar mezclar
instalaciones y muestra cómo corregirlo.''',
    "README.md: netlist2svg explanation",
)
replace_once(
    p,
    "Las herramientas que antes estaban en el\nentorno Conda se obtienen desde OSS CAD Suite, APT, npm o sus releases\noficiales.",
    "Las herramientas que antes estaban en el\nentorno Conda se obtienen desde OSS CAD Suite, pacman, npm o sus releases\noficiales.",
    "README.md: conda tools",
)
replace_once(
    p,
    '''El comando `digital-logic-design debian-dependencias` instala PulseView y el
firmware `sigrok-firmware-fx2lafw` para analizadores basados en Cypress FX2,
incluidos los clones de 8 y 16 canales. El paquete libsigrok de Debian instala
también las reglas udev necesarias.''',
    '''El comando `digital-logic-design arch-dependencias` instala PulseView y el
firmware `sigrok-firmware-fx2lafw` para analizadores basados en Cypress FX2,
incluidos los clones de 8 y 16 canales. El paquete libsigrok de Arch Linux
instala también las reglas udev necesarias.''',
    "README.md: analizador lógico",
)

print("OK: todos los parches se aplicaron correctamente")
PY

chmod +x \
  "$OUT/installTools/digital-logic-design.sh" \
  "$OUT/installTools/hw-permissions.sh" \
  "$OUT/installTools/instruments/oscilloscope-owon/install-owon-linux.sh"

echo "Creando RAR..."
cd "$(dirname "$OUT")"
rar a -r -idq "digital-electronic-1-101-arch.rar" "$(basename "$OUT")" >/dev/null

echo
echo "Listo:"
echo "  Carpeta: $OUT"
echo "  RAR:     ${OUT}.rar"
