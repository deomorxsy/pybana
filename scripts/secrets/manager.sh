#!/bin/sh

# ////////////////
# ==========================
# replace actions workflow
# syntax with shellscript
# variable expansion
#
# ARC -> ArgoCD context
# ==========================
sed_replace() {

sec_sed="./scripts/secrets/rep-secrets.sed"

if [ -f "$sec_sed" ] && [ -f ./artifacts/sso.sh ]; then

    sed -f "$sec_sed" < "./artifacts/sso.sh" > ./artifacts/replaSED-sso.sh && \
        envsubst < ./artifacts/replaSED-sso.sh > ./artifacts/unsealed-sso.sh
else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now..."
fi



}


# secrets retriever
sret() {
    "read hashed key-value from cloud -> redirect the hashed value to file
read the file using sealed secrets
| then pipe this to openbao to unseal the vault && if this goes right, the vault is unsealed."

Now read an specific value

for item in $(kubectl exec -n=openbao-0 -it openbao-0 -- bao list secrets | grep column | awk '{print $3}' ); do

kubectl exec -n=openbao-0 \
    -it openbao-0 \
    --  bao read cubbyhole/secret-name (the item) \
    >> "redirect to file" ./artifacts/bao-secrets.txt

done

osinfo=$(uname)
if [ -f ./artifacts/bao-secrets.txt ] && [ "$osinfo" = 'Linux' ]; then
# now export the values to the ENVIRONMENT VARIABLES
export $(grep -v '^#' ./artifacts/bao-secrets.txt | xargs -d '\n')

elif [ -f ./artifacts/bao-secrets.txt ] && [ "osinfo" = 'FreeBSD' ] || [ "osinfo" = 'Darwin' ]; then

    export $(grep -v '^#' ./artifacts/bao-secrets.txt | xargs -0)

else
   printf "not on Linux or FreeBSD or Darwin. Exiting now..."
fi

# now replace the github syntax to the shellscript syntax
# ARC -> ArgoCD context
sed -f "$sec_sed" < "./artifacts/sso.sh" > ./artifacts/replaSED-sso.sh && if it goes right \
        envsubst < ./artifacts/replaSED-sso.sh > ./artifacts/unsealed-sso.sh && if it goes right \

# now remove the values from
# ENVIRONMENT VARIABLES (unset )
# and lock the vault
unset $(grep -v '^#' ./artifacts-bao-secrets.txt | sed -E 's/(.*)=.*/\1/' | xargs) && \

if [ -f ./artifacts-bao-secrets.txt]; then
     rm ./artifacts-bao-secrets.txt
else
   echo "could not remove the file ./artifacts-bao-secrets.txt"
fi

# seal the vault
kubectl exec -n=openbao -it openbao-0 -- bao operator seal
}
