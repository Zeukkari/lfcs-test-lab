# Networking — reverse proxies and load balancers (nginx, haproxy)

Domain: Networking ("Implement reverse proxies and load balancers").

## nginx install + vhost path per family

| | deb | rpm | suse (low exam ROI) |
| --- | --- | --- | --- |
| Install | `apt install nginx` | `dnf install nginx` | `zypper in nginx` |
| vhost files | `/etc/nginx/sites-available/` + symlink in `sites-enabled/` | `/etc/nginx/conf.d/*.conf` | `/etc/nginx/vhosts.d/*.conf` |
| Default-site conflict | remove the `default` symlink | default server block in nginx.conf | — |

**Trap (deb):** a vhost in `sites-available/` is inert until symlinked
into `sites-enabled/` — and the shipped `default` site keeps answering
on :80 until its symlink is removed:

```bash
ln -s /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
```

## Reverse proxy (minimal server block)

```nginx
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Load balancer (upstream)

```nginx
upstream backend {
    least_conn;                        # or ip_hash; — default is round-robin
    server n1.example.com:8080 weight=2;
    server n2.example.com:8080;
    server n3.example.com:8080 backup; # used only when the others are down
}
server {
    listen 80;
    location / { proxy_pass http://backend; }
}
```

Per-server flags: `weight=N`, `backup`, `down`.

## Test, reload, verify — every time

```bash
nginx -t                           # syntax check BEFORE reload
systemctl reload nginx
curl -s http://localhost/ | head   # verify from the right vantage point
```

## SELinux on rpm — the 502 generator

Default policy blocks the proxy from opening outbound connections to
backends:

```bash
setsebool -P httpd_can_network_connect on      # nginx → network backends
semanage port -a -t http_port_t -p tcp 8081    # nginx listens on a non-standard port
setsebool -P haproxy_connect_any on            # haproxy equivalent
```

**Trap:** `nginx -t` passes, the service runs, yet every proxied
request 502s under enforcing SELinux — that is
`httpd_can_network_connect`, not an nginx bug. Booleans need `-P` to
survive reboot. Theory and triage:
[selinux.md](../operations-deployment/selinux.md).

firewalld (rpm/suse):

```bash
firewall-cmd --add-service=http --permanent && firewall-cmd --reload
```

## haproxy

Package `haproxy` on all families — no family delta in config path.
Append to the packaged `/etc/haproxy/haproxy.cfg` (keep its
global/defaults sections):

```
frontend fe
    bind *:80
    default_backend be

backend be
    balance roundrobin
    server n1 10.0.0.11:8080 check
    server n2 10.0.0.12:8080 check
```

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg    # config check, = nginx -t
systemctl enable --now haproxy
```

## Verification (grader-style)

```bash
curl -s http://localhost/            # body must come from the backend
ss -tlnp | grep -E 'nginx|haproxy'   # listener on the asked port
systemctl is-enabled nginx haproxy   # reboot survivability
```

Reboot survivability: configs are files, so the grader checks that the
service is **enabled** and still answers after reboot — `enable --now`,
then re-curl post-reboot. On rpm also confirm the boolean persisted:
`getsebool httpd_can_network_connect`.
