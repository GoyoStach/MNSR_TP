# Exercice : Système de gestion d'une Librairie

## Phase 1 : Préparation du système

### Étape 1.1 : Création des groupes
```bash
# Créer les trois groupes principaux
sudo groupadd lecteurs
sudo groupadd auteurs  
sudo groupadd libraires
```


```bash
# Vérifier la création
getent group | grep -E "(lecteurs|auteurs|libraires)"
```

### Étape 1.2 : Création des utilisateurs

#### Lecteurs

Créer votre propre utilisateur, mettez votre nom et choissisez un mot de passe ( vous pouvez utiliser un mot de passe non sécurisé facile à taper)

```bash
sudo useradd -m -s /bin/bash -G lecteurs <username>
```

```bash
# Définir les mots de passe
sudo passwd <username>
```

#### Auteurs (avec groupes multiples)

Ici il faudra aussi ajouter un mot de passe (obligatoire), vous pouvez utiliser le même pour les 3 auteurs
```bash
sudo useradd -m -s /bin/bash -G auteurs,lecteurs victor_hugo
sudo useradd -m -s /bin/bash -G auteurs,lecteurs jules_verne
sudo useradd -m -s /bin/bash -G auteurs,lecteurs george_sand

# Mots de passe
sudo passwd victor_hugo
sudo passwd jules_verne  
sudo passwd george_sand
```

#### Libraires (accès administratif)
```bash
sudo useradd -m -s /bin/bash -G libraires,auteurs,lecteurs bibliothecaire

# Mots de passe
sudo passwd bibliothecaire
```

### Étape 1.3 : Structure des dossiers
Nous allons désormais populer les dossier pour les droits.

```bash
# Créer la structure de la librairie
sudo mkdir -p /librairie/{catalogue,auteurs,administration}
sudo mkdir -p /librairie/catalogue/{romans,poesie,theatre}
sudo mkdir -p /librairie/auteurs/{victor_hugo,jules_verne,george_sand}
sudo mkdir -p /librairie/administration/{rapports,gestion}
```

## Phase 2 : Configuration des permissions de base

### Étape 2.1 : Propriétés des dossiers principaux
```bash
# Dossier racine librairie
sudo chown root:libraires /librairie
sudo chmod 755 /librairie

# Catalogue (lecture publique)
sudo chown root:lecteurs /librairie/catalogue
sudo chmod 755 /librairie/catalogue

# Dossiers auteurs (spécifiques à chaque auteur)
sudo chown victor_hugo:auteurs /librairie/auteurs/victor_hugo
sudo chown jules_verne:auteurs /librairie/auteurs/jules_verne  
sudo chown george_sand:auteurs /librairie/auteurs/george_sand
sudo chmod 755 /librairie/auteurs
sudo chmod 750 /librairie/auteurs/*
sudo chown root:auteurs /librairie/auteurs

# Administration (libraires seulement)
sudo chown root:libraires /librairie/administration
sudo chmod 770 /librairie/administration
```

### Étape 2.2 : Permissions sur les sous-dossiers du catalogue
```bash
sudo chown root:lecteurs /librairie/catalogue/*
sudo chmod 755 /librairie/catalogue/*
```

## Phase 3 : Création du contenu

### Étape 3.1 : Livres dans le catalogue
```bash
# Romans
sudo tee /librairie/catalogue/romans/les_miserables.txt << 'EOF'
Les Misérables - Victor Hugo
Tome I : Fantine

Tant qu'il existera, par le fait des lois et des mœurs, 
une damnation sociale créant artificiellement, en pleine civilisation, 
des enfers, et compliquant d'une fatalité humaine la destinée qui est divine...
EOF

sudo tee /librairie/catalogue/romans/vingt_mille_lieues.txt << 'EOF'
Vingt mille lieues sous les mers - Jules Verne
Chapitre I : Un écueil fuyant

L'année 1866 fut marquée par un événement bizarre, 
un phénomène inexpliqué et inexplicable que personne n'a sans doute oublié...
EOF

# Théâtre
sudo tee /librairie/catalogue/theatre/hernani.txt << 'EOF'
Hernani - Victor Hugo
Acte I, Scène I

Serait-ce déjà lui ? C'est bien à l'escalier
Dérobé... Vite, ouvrons !
EOF

# Poésie
sudo tee /librairie/catalogue/poesie/contemplations.txt << 'EOF'
Les Contemplations - Victor Hugo

Elle était déchaussée, elle était décoiffée,
Assise, les pieds nus, parmi les joncs penchants...
EOF
```

### Étape 3.2 : Manuscrits des auteurs (dans leurs dossiers personnels)
```bash
# Victor Hugo
sudo -u victor_hugo tee /librairie/auteurs/victor_hugo/nouveau_roman.txt << 'EOF'
Nouveau projet de roman - Brouillon
Titre provisoire : "L'Homme qui rit"

Notes d'écriture :
- Personnage principal : Gwynplaine
- Époque : Angleterre, fin XVIIe siècle
EOF

# Jules Verne  
sudo -u jules_verne tee /librairie/auteurs/jules_verne/projet_scientifique.txt << 'EOF'
Nouveau projet - Roman d'aventures scientifiques
Titre : "De la Terre à la Lune"

Concept : Voyage spatial grâce à un canon géant
Lieu : Baltimore, États-Unis
EOF

# George Sand
sudo -u george_sand tee /librairie/auteurs/george_sand/roman_champetre.txt << 'EOF'
Nouveau roman champêtre - George Sand
Titre : "La Mare au Diable"

Personnages :
- Germain, laboureur veuf
- Marie, jeune bergère
EOF
```

**PROBLEMATIQUE : Tout les auteurs ont les même droits et pourraient donc modifier les manuscrits des autres auteurs. Pour remédier à ça ACL apporte plus de granularité**

## Phase 4 : Permissions avancées avec ACL

### Étape 4.1 : Catalogue (lecture pour tous)
```bash
# Tous les groupes peuvent lire le catalogue
sudo setfacl -R -m g:lecteurs:r-x /librairie/catalogue
sudo setfacl -R -m g:auteurs:r-x /librairie/catalogue  
sudo setfacl -R -m g:libraires:rwx /librairie/catalogue

# Permissions par défaut pour nouveaux fichiers
sudo setfacl -d -m g:lecteurs:r-x /librairie/catalogue
sudo setfacl -d -m g:auteurs:r-x /librairie/catalogue
sudo setfacl -d -m g:libraires:rwx /librairie/catalogue
```

**Verification :**
```bash
ls -la /librairie/catalogue
# Affiche : drwxr-xr-x+ root root catalogue
#          ↑ Le "+" indique la présence d'ACL

getfacl /librairie/catalogue
# user::rwx
# group::r-x  
# group:lecteurs:r-x    ← Nouvelle règle ACL
# mask::rwx
# other::r-x
```

### Étape 4.2 : Dossiers auteurs (accès personnel)
```bash
# Victor Hugo : accès total à son dossier, libraires et autres auteurs seulement
sudo setfacl -R -m u:victor_hugo:rwx /librairie/auteurs/victor_hugo
sudo setfacl -R -m g:libraires:rwx /librairie/auteurs/victor_hugo
sudo setfacl -R -m g:auteurs:r-x /librairie/auteurs/victor_hugo
sudo setfacl -R -m g:lecteurs:--- /librairie/auteurs/victor_hugo

# Jules Verne
sudo setfacl -R -m u:jules_verne:rwx /librairie/auteurs/jules_verne
sudo setfacl -R -m g:libraires:rwx /librairie/auteurs/jules_verne  
sudo setfacl -R -m g:auteurs:r-x /librairie/auteurs/jules_verne
sudo setfacl -R -m g:lecteurs:--- /librairie/auteurs/jules_verne

# George Sand
sudo setfacl -R -m u:george_sand:rwx /librairie/auteurs/george_sand
sudo setfacl -R -m g:libraires:rwx /librairie/auteurs/george_sand
sudo setfacl -R -m g:auteurs:r-x /librairie/auteurs/george_sand
sudo setfacl -R -m g:lecteurs:--- /librairie/auteurs/george_sand

# Dossier parent auteurs - accès bloqué pour les lecteurs
sudo setfacl -m g:lecteurs:--- /librairie/auteurs
```

### Étape 4.3 : Administration (libraires uniquement)
```bash
sudo setfacl -R -m g:libraires:rwx /librairie/administration
sudo setfacl -R -m g:auteurs:--- /librairie/administration
sudo setfacl -R -m g:lecteurs:--- /librairie/administration
```

## Phase 5 : Tests et vérifications

### Test 1 : Lecteur (C'est vous !)
```bash
# Se connecter en tant que vous !
su - <username>

# Tests à effectuer :
cd /librairie/catalogue                    # ✓ Doit fonctionner
cat romans/les_miserables.txt             # ✓ Doit fonctionner  
cd /librairie/auteurs                      # ✗ Doit échouer (Permission denied)
ls /librairie/auteurs                      # ✗ Doit échouer (Permission denied)
cd /librairie/administration              # ✗ Doit échouer (Permission denied)
```

### Test 2 : Auteur (victor_hugo)
```bash
# Se connecter en tant que victor_hugo
su - victor_hugo

# Tests à effectuer :
cd /librairie/auteurs/victor_hugo          # ✓ Doit fonctionner
echo "Nouveau chapitre..." >> nouveau_roman.txt  # ✓ Doit fonctionner
cd /librairie/auteurs/jules_verne          # ✓ Accès lecture (autres auteurs)
cat projet_scientifique.txt               # ✓ Doit fonctionner
echo "test" > /librairie/auteurs/jules_verne/test.txt  # ✗ Doit échouer
cd /librairie/administration              # ✗ Doit échouer
```

### Test 3 : Libraire (bibliothecaire)
```bash
# Se connecter en tant que bibliothecaire
su - bibliothecaire

# Tests à effectuer :
cd /librairie/administration              # ✓ Doit fonctionner
echo "Rapport mensuel" > administration/rapports/janvier.txt  # ✓ Doit fonctionner
echo "Nouveau livre" > catalogue/romans/nouveau_livre.txt     # ✓ Doit fonctionner
```

## Phase 6 : Scripts d'aide

### Script de vérification des permissions
```bash
#!/bin/bash
# verification_permissions.sh

echo "=== Vérification des permissions de la librairie ==="
echo

echo "1. Structure des dossiers :"
tree /librairie -d

echo -e "\n2. Permissions détaillées :"
echo "Catalogue :"
ls -la /librairie/catalogue
getfacl /librairie/catalogue/romans

echo -e "\nDossiers auteurs :"
ls -la /librairie/auteurs/
getfacl /librairie/auteurs/victor_hugo

echo -e "\nAdministration :"
ls -la /librairie/administration
getfacl /librairie/administration
```




## Bonus: Aller plus loin !

- **Compréhension** : Expliquez pourquoi les auteurs sont aussi dans le groupe lecteurs.
- **Analyse** : Que se passe-t-il si un lecteur essaie de modifier un fichier dans le catalogue ?
- **Problème** : Un nouvel auteur emile_zola arrive. Listez toutes les étapes pour l'intégrer.
- **Sécurité** : Proposez une amélioration pour que chaque auteur ne puisse voir que ses propres manuscrits.
- **Pratique** : Créez un dossier archives accessible en lecture seule à tous, mais modifiable uniquement par les libraires.

## Danger zone

### Script de nettoyage (pour recommencer l'exercice)
```bash
#!/bin/bash
# nettoyage_librairie.sh

echo "Suppression des utilisateurs et groupes..."
for user in <username> victor_hugo jules_verne george_sand bibliothecaire; do
    sudo userdel -r $user 2>/dev/null
done

for group in lecteurs auteurs libraires; do
    sudo groupdel $group 2>/dev/null  
done

echo "Suppression des dossiers..."
sudo rm -rf /librairie

echo "Nettoyage terminé. Vous pouvez recommencer l'exercice."
```