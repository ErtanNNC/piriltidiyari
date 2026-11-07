#!/usr/bin/env python3
"""Sign an APK with APK Signature Scheme v2 (RSA 2048, SHA-256).

Used because Google's apksigner (Android SDK build-tools) can't be downloaded
in the cloud build environment. Implements the published v2 format:
https://source.android.com/docs/security/features/apksigning/v2

  tools/sign_apk.py in.apk out.apk --key .tools/debug-key.pem --cert .tools/debug-cert.der
  tools/sign_apk.py --verify out.apk

The key/cert are created on first use (self-signed debug key). Keep the same
key for later builds, otherwise Android asks to uninstall the old app first.
"""
import argparse
import datetime
import hashlib
import os
import struct
import sys
import zipfile

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

V2_BLOCK_ID = 0x7109871A
MAGIC = b"APK Sig Block 42"
RSA_PKCS1_SHA256 = 0x0103
CHUNK = 1024 * 1024


def lp(b: bytes) -> bytes:
    """uint32 length-prefixed bytes."""
    return struct.pack("<I", len(b)) + b


def find_eocd(data: bytes) -> int:
    i = data.rfind(b"PK\x05\x06", max(0, len(data) - 65536 - 22))
    if i < 0:
        sys.exit("ZIP End of Central Directory bulunamadı")
    return i


def sections(data: bytes):
    eocd = find_eocd(data)
    cd_size, cd_off = struct.unpack_from("<II", data, eocd + 12)
    return cd_off, cd_size, eocd


def content_digest(entries: bytes, cd: bytes, eocd: bytes) -> bytes:
    chunks = []
    for section in (entries, cd, eocd):
        for i in range(0, len(section), CHUNK):
            c = section[i:i + CHUNK]
            chunks.append(hashlib.sha256(b"\xa5" + struct.pack("<I", len(c)) + c).digest())
    return hashlib.sha256(b"\x5a" + struct.pack("<I", len(chunks)) + b"".join(chunks)).digest()


def check_alignment(path: str) -> list:
    """Stored (uncompressed) entries must start on a 4-byte boundary."""
    bad = []
    with open(path, "rb") as f, zipfile.ZipFile(path) as z:
        for info in z.infolist():
            if info.compress_type != zipfile.ZIP_STORED:
                continue
            f.seek(info.header_offset + 26)
            name_len, extra_len = struct.unpack("<HH", f.read(4))
            data_off = info.header_offset + 30 + name_len + extra_len
            if data_off % 4 != 0:
                bad.append(info.filename)
    return bad


def load_or_create_key(key_path: str, cert_path: str):
    if os.path.exists(key_path) and os.path.exists(cert_path):
        key = serialization.load_pem_private_key(open(key_path, "rb").read(), None)
        cert = x509.load_der_x509_certificate(open(cert_path, "rb").read())
        return key, cert
    os.makedirs(os.path.dirname(key_path) or ".", exist_ok=True)
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, "Pirilti Diyari Debug"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Just A Game Studios"),
    ])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
            .public_key(key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(now - datetime.timedelta(days=1))
            .not_valid_after(now + datetime.timedelta(days=365 * 30))
            .sign(key, hashes.SHA256()))
    open(key_path, "wb").write(key.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
    open(cert_path, "wb").write(cert.public_bytes(serialization.Encoding.DER))
    os.chmod(key_path, 0o600)
    return key, cert


def sign(src: str, dst: str, key_path: str, cert_path: str) -> None:
    data = open(src, "rb").read()
    cd_off, cd_size, eocd_off = sections(data)
    if data[cd_off - 16:cd_off] == MAGIC:
        sys.exit("APK zaten imzalı (APK Signing Block var)")
    if cd_off + cd_size != eocd_off:
        sys.exit("Beklenmeyen ZIP düzeni")
    bad = check_alignment(src)
    if bad:
        sys.exit("Hizalanmamış sıkıştırılmamış dosyalar: %s" % bad[:5])
    key, cert = load_or_create_key(key_path, cert_path)

    digest = content_digest(data[:cd_off], data[cd_off:eocd_off], data[eocd_off:])
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    signed_data = (
        lp(lp(struct.pack("<I", RSA_PKCS1_SHA256) + lp(digest)))  # digests
        + lp(lp(cert_der))                                           # certificates
        + lp(b"")                                                    # additional attributes
    )
    signature = key.sign(signed_data, padding.PKCS1v15(), hashes.SHA256())
    pub = key.public_key().public_bytes(
        serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    signer = lp(signed_data) + lp(lp(struct.pack("<I", RSA_PKCS1_SHA256) + lp(signature))) + lp(pub)
    v2_value = lp(lp(signer))

    pair = struct.pack("<I", V2_BLOCK_ID) + v2_value
    pairs = struct.pack("<Q", len(pair)) + pair
    block_size = len(pairs) + 8 + 16
    block = struct.pack("<Q", block_size) + pairs + struct.pack("<Q", block_size) + MAGIC

    eocd = bytearray(data[eocd_off:])
    struct.pack_into("<I", eocd, 16, cd_off + len(block))
    with open(dst, "wb") as f:
        f.write(data[:cd_off])
        f.write(block)
        f.write(data[cd_off:eocd_off])
        f.write(eocd)


def verify(path: str) -> None:
    data = open(path, "rb").read()
    cd_off, cd_size, eocd_off = sections(data)
    if data[cd_off - 16:cd_off] != MAGIC:
        sys.exit("İmza bloğu yok")
    size = struct.unpack_from("<Q", data, cd_off - 24)[0]
    start = cd_off - size - 8
    if struct.unpack_from("<Q", data, start)[0] != size:
        sys.exit("İmza bloğu boyutları tutarsız")
    pos, end = start + 8, cd_off - 24
    v2 = None
    while pos < end:
        plen = struct.unpack_from("<Q", data, pos)[0]
        pid = struct.unpack_from("<I", data, pos + 8)[0]
        if pid == V2_BLOCK_ID:
            v2 = data[pos + 12:pos + 8 + plen]
        pos += 8 + plen
    if v2 is None:
        sys.exit("v2 imzası yok")

    def read_lp(b, o):
        n = struct.unpack_from("<I", b, o)[0]
        return b[o + 4:o + 4 + n], o + 4 + n

    signers, _ = read_lp(v2, 0)
    signer, _ = read_lp(signers, 0)
    signed_data, o = read_lp(signer, 0)
    sigs, o = read_lp(signer, o)
    pub_der, _ = read_lp(signer, o)
    sig_entry, _ = read_lp(sigs, 0)
    sig_bytes, _ = read_lp(sig_entry, 4)
    pub = serialization.load_der_public_key(pub_der)
    pub.verify(sig_bytes, signed_data, padding.PKCS1v15(), hashes.SHA256())
    digests, o = read_lp(signed_data, 0)
    certs, _ = read_lp(signed_data, o)
    d_entry, _ = read_lp(digests, 0)
    stored_digest, _ = read_lp(d_entry, 4)
    cert_der, _ = read_lp(certs, 0)
    cert = x509.load_der_x509_certificate(cert_der)
    if cert.public_key().public_bytes(serialization.Encoding.DER,
                                      serialization.PublicFormat.SubjectPublicKeyInfo) != pub_der:
        sys.exit("Sertifika ile açık anahtar uyuşmuyor")
    # Digest is over the APK as it was before the block was inserted.
    eocd = bytearray(data[eocd_off:])
    struct.pack_into("<I", eocd, 16, start)
    if content_digest(data[:start], data[cd_off:eocd_off], bytes(eocd)) != stored_digest:
        sys.exit("İçerik özeti tutmuyor")
    with zipfile.ZipFile(path) as z:
        if z.testzip() is not None:
            sys.exit("ZIP içeriği bozuk")
    print("Doğrulandı: v2 imzası geçerli, %s, SHA-256 sertifika parmak izi %s"
          % (cert.subject.rfc4514_string(), cert.fingerprint(hashes.SHA256()).hex()[:16]))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("apk")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--key", default=".tools/debug-key.pem")
    ap.add_argument("--cert", default=".tools/debug-cert.der")
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        verify(a.apk)
    else:
        sign(a.apk, a.out, a.key, a.cert)
        verify(a.out)
