# Gera o site publicado (GitHub Pages) com dados CRIPTOGRAFADOS por usuario.
#
# Entrada:
#   lista.json  - saida de: rclone lsjson "gdrive:BackupSCOLA" -R --files-only
#   links.json  - mapa { "Pasta/arquivo.rar": "https://drive.google.com/..." }
#   env USUARIOS - uma linha por usuario:  email;senha;PASTA
#                  PASTA = nome da pasta do municipio, ou "admin" para ver tudo
#   env GERADO_EM - texto de data/hora exibido no painel
#
# Saida (pasta site/):
#   index.html      - painel com tela de login (dados NAO ficam no HTML)
#   dados/<id>.bin  - um bloco AES-256-GCM por usuario; so a senha dele decifra
#
# Sem a senha correta os .bin sao ilegiveis - e as senhas so existem no
# secret USUARIOS do GitHub, que apenas o dono do repositorio acessa.
import json, os, sys, hashlib, secrets
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ITERACOES = 200_000  # PBKDF2 (igual ao painel_template.html)

def chave_do_usuario(email: str, senha: str) -> bytes:
    salt = hashlib.sha256(('sal:' + email).encode()).digest()[:16]
    return hashlib.pbkdf2_hmac('sha256', senha.encode(), salt, ITERACOES, dklen=32)

def id_do_usuario(email: str) -> str:
    return hashlib.sha256(email.encode()).hexdigest()[:24]

def main():
    usuarios_raw = os.environ.get('USUARIOS', '').strip()
    if not usuarios_raw:
        print('ERRO: secret USUARIOS vazio. Crie em Settings > Secrets and variables > Actions.')
        sys.exit(1)

    usuarios = []
    for num, ln in enumerate(usuarios_raw.splitlines(), 1):
        ln = ln.strip()
        if not ln or ln.startswith('#'):
            continue
        partes = [p.strip() for p in ln.split(';')]
        if len(partes) < 3 or not partes[0] or not partes[1] or not partes[2]:
            print(f'AVISO: linha {num} do USUARIOS ignorada (formato: email;senha;PASTA)')
            continue
        usuarios.append((partes[0].lower(), partes[1], partes[2]))
    if not usuarios:
        print('ERRO: nenhum usuario valido no secret USUARIOS.')
        sys.exit(1)

    lista = json.load(open('lista.json', encoding='utf-8'))
    try:
        links = json.load(open('links.json', encoding='utf-8')) or {}
    except Exception:
        links = {}

    arquivos = [{'p': f['Path'], 's': f['Size'], 'm': f['ModTime'],
                 'u': links.get(f['Path'], '')} for f in lista]
    gerado_em = os.environ.get('GERADO_EM', '')

    os.makedirs('site/dados', exist_ok=True)
    for email, senha, pasta in usuarios:
        admin = pasta.lower() in ('admin', '*')
        if admin:
            meus = arquivos
        else:
            meus = [a for a in arquivos if a['p'].split('/')[0].upper() == pasta.upper()]
        payload = json.dumps({'geradoEm': gerado_em, 'erro': False, 'admin': admin,
                              'arquivos': meus}, ensure_ascii=False).encode()
        chave = chave_do_usuario(email, senha)
        nonce = secrets.token_bytes(12)
        cifrado = AESGCM(chave).encrypt(nonce, payload, None)
        nome = id_do_usuario(email) + '.bin'
        with open(os.path.join('site', 'dados', nome), 'wb') as f:
            f.write(nonce + cifrado)
        print(f'usuario {"ADMIN" if admin else pasta}: dados/{nome} ({len(meus)} arquivos)')

    tpl = open('painel_template.html', encoding='utf-8').read()
    open('site/index.html', 'w', encoding='utf-8').write(tpl.replace('__DADOS__', 'null'))
    print('site gerado.')

if __name__ == '__main__':
    main()
