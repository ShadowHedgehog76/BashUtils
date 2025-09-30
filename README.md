# 🐚 BashUtils

Un petit pack d’outils Bash fait maison pour rendre la vie plus simple ✨

## :inbox_tray: Installation

Copie-colle cette commande dans ton terminal :

```bash
curl -fsSL https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main/install.sh | bash
```

Ensuite relance ton Shell.

## :pushpin: Commandes disponibles

### :mag: search

Permet de chercher **dans le contenu des fichiers** ou **dans les noms de fichiers** (recherche récursive).

#### Usage :

```bash
search [ -s | -e | -p ] <motif_ou_regex> [chemin] [--name "glob"] [--exclude "glob"]
```

#### Modes :

* `-s, --simple` → recherche texte exacte (par défaut)
* `-e, --regex` → recherche avec regex étendue (`grep -E`)
* `-p, --perl` → recherche avec regex Perl (`grep -P`) si supporté

#### Options :

* `--name "glob"` → inclure uniquement certains fichiers
* `--exclude "glob"` → exclure certains fichiers/dossiers
* `--en / --fr / --jp` → choisir la langue de l’aide (`--en` par défaut)
* `-h, --help` → afficher l’aide

#### Exemples :

```bash
# Recherche simple du mot "hello" dans ~/Documents
search "hello" ~/Documents

# Recherche regex : fonctions exportées en Go
search -e "^func\s+[A-Z]\w+" . --name "*.go"

# Recherche PCRE (insensible à la casse) : TODO
search -p "(?i)TODO:" .

# Recherche de fichiers commençant par ma et finissant par .go
search "ma*.go"

# Recherche d'email, en excluant les fichiers minifiés
search -e "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" . --exclude "*.min.js"
```

---

### :recycle: update

Met à jour automatiquement les scripts depuis le dépôt GitHub.

```bash
update
```

💡 Un auto-update est aussi lancé à chaque redémarrage de la machine.

---

## :open_file_folder: Emplacement des fichiers

Les scripts sont installés dans :

```bash
$HOME/Documents/alias/
```
