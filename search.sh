#!/bin/bash

# Script pour chercher un mot dans le contenu de tous les fichiers récursivement

if [ $# -eq 0 ]; then
    echo "Usage: $0 <mot_a_chercher> [chemin_de_depart]"
    echo "Exemple: $0 'hello' /home/user/documents"
    exit 1
fi

MOT="$1"
CHEMIN="${2:-.}"  # Par défaut, on commence dans le répertoire courant

echo "Recherche du mot '$MOT' dans le contenu des fichiers à partir de '$CHEMIN'..."
echo "============================================================"

# Utilisation de grep récursif, en ignorant les erreurs de lecture (fichiers binaires, permissions, etc.)
grep -rn --color=always --exclude-dir={.git,.svn,.hg} "$MOT" "$CHEMIN" 2>/dev/null

# Si aucun résultat
if [ $? -ne 0 ]; then
    echo "Aucun résultat trouvé pour '$MOT'."
fi
