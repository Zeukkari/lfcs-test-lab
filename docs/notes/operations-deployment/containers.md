# Operations Deployment — Containers (podman)

Domain: Operations Deployment ("Configure container engines, create and
manage containers").

## Engine availability per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| engines in base repos | both `docker.io` and `podman` | podman only (docker needs a third-party repo) | podman in main repo |
| podman in lab | 3.4.4 (Ubuntu 22.04) — **no Quadlet**, generate systemd only | 5.8.2 (Rocky 9.8) — Quadlet native, generate systemd deprecated | verify in lab (`podman --version`) |

podman is a drop-in docker CLI: `alias docker=podman`. If the exam host
is Ubuntu 24.04 (podman 4.9), Quadlet works there too — drill Quadlet
on Rocky, `generate systemd` on Ubuntu 22.04, know both.

## Basics to drill

```
podman run -d --name web -p 8080:80 \
  -v /srv/web:/usr/share/nginx/html:Z --restart=always docker.io/nginx
podman ps -a / images / logs web / inspect web
podman exec -it web sh
podman pull IMG / tag IMG NEW / push NEW
podman login registry.example.com
```

**Trap:** on rpm with SELinux enforcing, a volume mounted without `:Z`
(private relabel) or `:z` (shared) fails with permission denied inside
the container. Theory in [selinux.md](selinux.md).

Unqualified-search registries: /etc/containers/registries.conf.

## Rootless containers

- /etc/subuid and /etc/subgid must have entries for the user (modern
  useradd creates them; check when containers fail to start).
- `loginctl enable-linger alice` — the user's services keep running
  after logout and start at boot.
- Ports below 1024 need `net.ipv4.ip_unprivileged_port_start` lowered —
  sysctl persistence in [kernel-parameters.md](kernel-parameters.md).

## Reboot-surviving units, path 1: Quadlet (podman ≥ 4.4 — Rocky 9)

Drop `web.container` into /etc/containers/systemd/ (root) or
~/.config/containers/systemd/ (rootless user):

```
[Container]
Image=docker.io/nginx
PublishPort=8080:80
Volume=/srv/web:/usr/share/nginx/html:Z

[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
systemctl start web.service        # unit name = file stem + .service
```

Boot activation comes from the `[Install]` section in the .container
file (the generated unit is not enabled with `systemctl enable`).

## Path 2: podman generate systemd (podman 3.4 — Ubuntu 22.04)

```
podman create --name web -p 8080:80 docker.io/nginx
podman generate systemd --new --files --name web
mv container-web.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now container-web.service
```

Deprecated in podman ≥ 4.7 (prints a warning) but the **only** unit
path on Ubuntu 22.04's podman 3.4.4. `--new` makes the unit create a
fresh container each start; `--files` writes the unit next to you
instead of stdout.

## Exam shape

Run a container with a specific name/port/volume that survives reboot —
Quadlet file or generated unit, plus boot activation, then prove it.

## Grader-style verification

```
podman ps                                     # running, right name/ports
curl -s localhost:8080 | head                 # actually serving
systemctl status web.service                  # Quadlet unit active
systemctl is-enabled container-web.service    # generate-systemd path enabled
loginctl show-user alice | grep Linger        # rootless: linger on
```

The real proof is the reboot: after it, `podman ps` must show the
container running and `curl` must answer — a `--restart=always` run
without a unit/linger does not survive on its own.
