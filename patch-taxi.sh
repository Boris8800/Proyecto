#!/bin/bash
# Script parcheado sin chequeos problemáticos

# Copiar script original
cp taxi-install.sh taxi-patched.sh

# Eliminar líneas con chequeos problemáticos de paquetes rotos y dpkg
sed -i '/paquetes rotos\|apt --fix-broken\|dpkg --configure/d' taxi-patched.sh

# Reemplazar BASH_SOURCE con $0 para máxima compatibilidad
sed -i 's/\${BASH_SOURCE:-\$0}/\$0/g' taxi-patched.sh
sed -i 's/\$BASH_SOURCE/\$0/g' taxi-patched.sh

chmod +x taxi-patched.sh
echo "Script parcheado creado: taxi-patched.sh"
bash taxi-patched.sh
