# macOS code signing (self-signed certificate)

This fork builds the macOS app in GitHub Actions on standard `macos-26` runners.
The artifact is signed with a **fixed self-signed code signing certificate**
rather than being ad-hoc signed (`Signature=adhoc`).

## Why

macOS TCC matches Accessibility grants for ad-hoc signed apps by their code
hash (`cdhash`). Every rebuild changes the cdhash, so the system treats the new
build as a new app and the previous grant silently stops applying — running
`osascript` from the terminal then fails with
`osascript is not allowed to send keystrokes (1002)`. TCC matches a
certificate-signed app by its designated requirement instead, which stays
identical across builds as long as the same certificate is used.

The certificate is self-signed and not in Apple's trust chain. This is **not**
Developer ID signing and the app is **not** notarized: Gatekeeper still asks for
confirmation the first time a new build is opened, exactly like before. The
only thing that changes is the signing identity, which is what TCC keys on.

## Secrets used by `.github/workflows/build.yml`

| Secret | Content |
| --- | --- |
| `MACOS_SIGNING_CERTIFICATE` | base64 of the `.p12` (certificate + private key) |
| `MACOS_SIGNING_CERTIFICATE_PASSWORD` | password of that `.p12` |
| `MACOS_SIGNING_IDENTITY` | certificate common name, used as `codesign -s` |
| `MACOS_SIGNING_KEYCHAIN_PASSWORD` | throwaway password for the temporary keychain |

The workflow imports the `.p12` into a temporary keychain, marks the
certificate trusted for the code signing policy only, signs the nested Sparkle
binaries and then the app bundle, verifies the signature and prints the
designated requirement, and finally deletes the keychain. Secrets are not
available to pull requests from forks, so the workflow falls back to ad-hoc
signing there and CI still produces an artifact.

## Do not recreate the certificate

Accessibility grants survive builds only because the signing identity stays the
same. Recreating the certificate means a new identity, which means every
machine has to grant Accessibility again. Rotate it only if the private key is
compromised or the certificate expires, and re-grant Accessibility on every
machine afterwards.

To recreate it (only when rotating), generate a self-signed certificate with
the `codeSigning` extended key usage and no CA bit, export it as `.p12`, and
update the secrets above:

```sh
cat > cert.cnf <<'EOF'
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no

[dn]
CN = Ghostty Fork Self-Signed

[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
EOF

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -keyout key.pem -out cert.pem -config cert.cnf
openssl pkcs12 -export -legacy -inkey key.pem -in cert.pem \
  -name "Ghostty Fork Self-Signed" -out ghostty-selfsigned.p12
```

`-legacy` is required: macOS `security import` only understands the legacy
PKCS#12 algorithms (3DES / SHA-1). OpenSSL 3 and later default to
AES-256-CBC + PBKDF2, which makes the import fail with
`MAC verification failed during PKCS12 import (wrong password?)` — even though
the password is correct. After exporting, verify locally with
`security import <p12> -k <temp keychain> -P <password>`: it must print
`1 identity imported.`

Keep the `.p12` and its password in the maintainer's private backup as well —
GitHub secrets must not be the only copy.