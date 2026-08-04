#RUN THIS IN GIT BASH!!!

# 1. Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt

# 2. Extract public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

# 3. Extract Clean Public Key
grep -v -- '-----' rsa_key.pub | tr -d '\n'