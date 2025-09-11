# 🐚 BashUtils
Un petit pack d’outils Bash fait maison pour rendre la vie plus simple :sparkles:
## :inbox_tray: Installation

Copie-colle cette commande dans ton terminal :
```bash
curl -fsSL https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main/install.sh | bash
```
Ensuite relance ton Shell

## :pushpin: Commandes disponibles

:mag: search

Permet de chercher un mot dans tous les fichiers d’un dossier (récursif).
```bash
search "mot" [chemin]
```
## Exemple :
```bash
search "hello" ~/Documents
```

:recycle: update

Met à jour automatiquement les scripts depuis le dépôt GitHub.
```bash
update
```
:bulb: Un auto-update est aussi lancé à chaque redémarrage de la machine.

## :open_file_folder: Emplacement des fichiers
Les scripts sont installés dans :
```bash
$HOME/Documents/alias/
```
