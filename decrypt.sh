#!/bin/bash

# Programme de déchiffrement Vigenère
# Utilise la variable d'environnement "Decrypt_Key" pour déchiffrer un message

# Message chiffré (généré avec la clé "Paul Valery")
ENCRYPTED_MESSAGE="Ae ppit di ccke, cw aafx kcctyc ye gmmpt"

# Vérifier si la variable d'environnement Decrypt_Key est définie
if [[ -z "$Decrypt_Key" ]]; then
    echo "Variable d'environnement 'Decrypt_Key' non définie."
    echo "Message chiffré: $ENCRYPTED_MESSAGE"
    echo "Essayez à nouveau après avoir défini la clé de déchiffrement."
    exit 1
fi

# Fonction de déchiffrement Vigenère
vigenere_decrypt() {
    local message="$1"
    local key="$2"
    local result=""
    local key_index=0
    
    # Normaliser la clé (supprimer espaces et convertir en majuscules)
    key=$(echo "$key" | sed 's/ //g' | tr '[:lower:]' '[:upper:]')
    local key_length=${#key}
    
    for (( i=0; i<${#message}; i++ )); do
        char="${message:$i:1}"
        
        # Traiter uniquement les lettres
        if [[ "$char" =~ [a-zA-Z] ]]; then
            # Déterminer si c'est une majuscule
            if [[ "$char" =~ [A-Z] ]]; then
                is_upper=true
                char_code=$(($(printf '%d' "'$char") - 65)) # A=0, B=1, etc.
            else
                is_upper=false
                char_code=$(($(printf '%d' "'$char") - 97)) # a=0, b=1, etc.
            fi
            
            # Obtenir le caractère de la clé
            key_char="${key:$((key_index % key_length)):1}"
            key_code=$(($(printf '%d' "'$key_char") - 65))
            
            # Déchiffrement: (char_code - key_code + 26) % 26
            decrypted_code=$(((char_code - key_code + 26) % 26))
            
            # Convertir de nouveau en caractère
            if [[ "$is_upper" == true ]]; then
                decrypted_char=$(printf "\\$(printf '%03o' $((decrypted_code + 65)))")
            else
                decrypted_char=$(printf "\\$(printf '%03o' $((decrypted_code + 97)))")
            fi
            
            result+="$decrypted_char"
            key_index=$((key_index + 1))
        else
            # Conserver les caractères non alphabétiques (espaces, ponctuation)
            result+="$char"
        fi
    done
    
    echo "$result"
}

# Effectuer le déchiffrement
echo "Déchiffrement en cours avec la clé: $Decrypt_Key"
echo ""

decrypted=$(vigenere_decrypt "$ENCRYPTED_MESSAGE" "$Decrypt_Key")
echo "Message déchiffré: $decrypted"