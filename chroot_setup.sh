#!/bin/bash
#add user to kali box with no shell
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

useradd user
passwd user

mkdir /home/chroot/etc
cp -vf /etc/{passwd,group} /home/chroot/etc/

cat >> /etc/ssh/sshd_config <<EOF
Match User user
  ChrootDirectory /home/chroot
  AuthorizedKeysFile /home/chroot/home/user/.ssh/authorized_keys
  PubkeyAuthentication no #

systemctl restart ssh

cp /usr/bin/mkdir /home/chroot/bin/
cp /usr/bin/cat /home/chroot/bin/

mkdir -p /home/chroot/home/user
chown -R user:user /home/chroot/home/user
chmod -R 0700 /home/chroot/home/user
