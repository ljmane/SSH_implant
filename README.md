# SSH_implant
<h3>Purpose</h3>
Access an internal device's ssh server
<h5>Step One</h5>
Setup chroot and user on Opstation, use chroot_setup.sh
<h5>Step Two</h5>
<h3>On Target</h3> <br />
#Verify target can reach the CHK_IP <br />
ping -c 1 [CHK_IP] <br />
#Verify target has nc with the following options: -z, -n, -w <br />
which nc || which netcat || which wget <br />
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
