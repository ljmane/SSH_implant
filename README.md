# SSH_implant
<h3>Purpose</h3>
Post Exploitation action after accessing an internal target in a network. Enables future access to an internal targets ssh server (Internal target must be able to access the internet). Poor man beaconer.

<h3>Scope</h3>
For use in authorized penetration testing engagements, security research, and training labs (e.g. OSCP-style practice) only, against systems you own or are explicitly authorized to test. Not for use against systems without prior written authorization.

The techniques implemented here (SSH reverse tunneling, chroot-jailed restricted shells, running a script and recovering it from `/proc/<pid>/fd` after deletion) are standard, publicly documented pentesting and OPSEC methodology, not novel evasion tooling.
