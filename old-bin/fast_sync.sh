rsync -aHAxv --numeric-ids --delete --progress -e "ssh -T -c arcfour -o Compression=no -x" root@bigfish.virington.com:/data/Backups/ /home/backups
