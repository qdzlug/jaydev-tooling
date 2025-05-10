
for domain in mantawang.com virington.com ; do
    certbot certonly \
        --manual \
        --preferred-challenges=dns \
        --email qdzlug@gmail.com \
        --server https://acme-v02.api.letsencrypt.org/directory \
        --agree-tos \
        -d *.$domain
done



