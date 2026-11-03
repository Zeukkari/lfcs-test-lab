# Essential Commands — SSL certificates

Domain: Essential Commands ("Work with SSL certificates"). openssl
subcommands are family-identical; the only family delta is the CA
trust-store path + update tool (table below). Lab history with trust
stores: [learning-log.md §7](../../lab/learning-log.md).

## Create

```
# Self-signed cert + key in one shot (exam staple):
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout key.pem -out cert.pem -days 365 \
  -subj "/CN=www.example.com" \
  -addext "subjectAltName=DNS:www.example.com,DNS:example.com"

# CSR + key (to be signed by a CA):
openssl req -new -newkey rsa:4096 -nodes -keyout key.pem \
  -out site.csr -subj "/C=FI/O=Org/CN=www.example.com"
```

- `-nodes` = unencrypted key (no passphrase prompt at service start —
  usually what the task wants).
- **Trap:** modern clients validate the SAN, not the CN — without
  `-addext "subjectAltName=DNS:..."` curl/browsers reject the cert
  even when the CN is correct.

## Inspect

```
openssl req  -in site.csr -noout -text        # CSR: subject, key size, SANs
openssl x509 -in cert.pem -noout -text        # everything
openssl x509 -in cert.pem -noout -subject -issuer -dates -serial -fingerprint
openssl x509 -in cert.pem -noout -enddate     # expiry check
```

## Verify

```
openssl verify -CAfile ca.pem cert.pem        # chain check → "cert.pem: OK"

# Live endpoint — what is actually served, and its validity window:
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null |
  openssl x509 -noout -dates
```

Key ↔ cert pair check — identical output = matching pair:

```
openssl x509 -noout -modulus -in cert.pem | openssl md5   # RSA modulus route
openssl rsa  -noout -modulus -in key.pem  | openssl md5
# any key type — compare public keys instead:
openssl x509 -noout -pubkey -in cert.pem | openssl md5
openssl pkey -pubout      -in key.pem    | openssl md5
```

## Convert

```
openssl x509 -in cert.pem -outform der -out cert.der      # PEM → DER
openssl x509 -inform der -in cert.der -out cert.pem       # DER → PEM
openssl pkcs12 -export -out bundle.p12 -inkey key.pem -in cert.pem   # → PKCS12
openssl pkcs12 -in bundle.p12 -nodes -out extracted.pem              # ← PKCS12
```

## Trust a CA system-wide — per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| drop CA into | /usr/local/share/ca-certificates/ | /etc/pki/ca-trust/source/anchors/ | /etc/pki/trust/anchors/ |
| then run | `update-ca-certificates` | `update-ca-trust` | `update-ca-certificates` (SUSE's own tool, same name) |

**Trap (deb):** `update-ca-certificates` only picks up files with a
`.crt` extension — a `.pem` dropped into
/usr/local/share/ca-certificates/ is silently ignored:
`cp ca.pem /usr/local/share/ca-certificates/ca.crt`.

## Grader-style verification

```
openssl x509 -in cert.pem -noout -subject -dates   # right CN/SAN, right window
openssl verify -CAfile ca.pem cert.pem             # chain OK
trust list | grep -i "my ca"                       # rpm/suse: CA in the store
curl https://host/                                 # no -k needed = trusted
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null |
  openssl x509 -noout -enddate                     # service serves the new cert
```
