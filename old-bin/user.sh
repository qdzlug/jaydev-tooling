 groupadd -g 500 jschmidt
 groupadd -g 501 mbrooks
 useradd -d /home/jschmidt -s /bin/bash -u 500 -g 500 jschmidt
 useradd -d /home/mbrooks -s /bin/bash -u 501 -g 501 mbrooks
 mkdir /home/jschmidt && chown jschmidt:jschmidt /home/jschmidt
 mkdir /home/mbrooks && chown mbrooks:mbrooks /home/mbrooks
 passwd -d jschmidt
 passwd -d mbrooks
