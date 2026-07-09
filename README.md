# Painel de Backups — Google Drive

Painel local (HTML) para monitorar backups enviados a uma pasta do Google Drive,
sem precisar do aplicativo do Drive instalado. Feito para acompanhar os backups
do sistema Scola (SQL Server) de vários clientes, mas funciona com qualquer
estrutura de `PastaRaiz/NomeDoCliente/arquivos`.

## O que ele mostra

- **Resumo geral**: clientes em dia (backup nas últimas 12h), atrasados e espaço usado no Drive
- **Gráficos** de backups recebidos por dia e volume enviado por dia (últimos 7 dias)
- **Cartão por cliente** com status (✓ Em dia / ⚠ Atrasado / ✕ Sem backup recente),
  grade dos últimos 4 dias × 3 períodos diários (feito / faltou) e lista de arquivos
- Tema claro/escuro automático (segue o Windows)

Tudo roda **localmente**: os dados ficam entre o seu PC e o seu Google Drive.
Nada é publicado na internet.

## Instalação

1. Baixe ou clone este repositório em uma pasta (ex.: `C:\PainelBackups`)
2. Execute **`instalar_painel.bat`**. Ele:
   - baixa o [rclone](https://rclone.org) portátil (não instala nada no sistema)
   - abre o navegador para você autorizar o acesso ao Google Drive (uma única vez;
     o escopo `drive.file` só enxerga arquivos criados pelo próprio rclone)
   - cria a tarefa agendada **"Painel Backup Scola"**, que atualiza os dados a cada 30 min
   - gera e abre o painel

Depois, é só usar o **`painel.bat`** para abrir o painel quando quiser — ou deixar
a aba aberta, que ela se recarrega sozinha a cada 5 minutos.

## Configuração

- **Pasta do Drive**: edite `$pastaDrive` no topo de `gerar_painel.ps1`
  (padrão: `BackupSCOLA`)
- **Formato esperado dos arquivos**: `qualquercoisa_pN.rar|zip` marca o período
  N (1, 2 ou 3) do dia na grade; arquivos sem `_pN` contam como "backup manual"
- A data considerada é a data de modificação do arquivo no Drive

## Arquivos

| Arquivo | Função |
|---|---|
| `instalar_painel.bat` / `.ps1` | instalação (rodar uma vez) |
| `painel.bat` | gera o painel com dados atuais e abre no navegador |
| `gerar_painel.ps1` | consulta o Drive via rclone e gera o `painel.html` |
| `painel_template.html` | visual do painel (HTML/CSS/JS puro, sem dependências) |
| `painel_oculto.vbs` | atualização silenciosa usada pela tarefa agendada |

## Site publicado com login (GitHub Pages)

O workflow `.github/workflows/painel.yml` publica o painel no GitHub Pages a
cada 30 minutos, protegido por **login com criptografia real**: os dados de
cada usuário são cifrados com **AES-256-GCM** (chave derivada da senha via
PBKDF2), então os arquivos publicados são ilegíveis sem a senha.

Usuários são definidos no secret **`USUARIOS`** (Settings → Secrets and
variables → Actions), uma linha por usuário:

```
email-do-admin@exemplo.com;SenhaForte;admin
usuario@municipio1.com;OutraSenha;NOME-DA-PASTA-1
usuario@municipio2.com;MaisUmaSenha;NOME-DA-PASTA-2
```

- `admin` no lugar da pasta = vê todos os municípios
- Cada usuário de município vê **apenas** a pasta indicada
- Só quem tem acesso de dono ao repositório consegue ver/editar o secret —
  ou seja, só o dono cria usuários e troca senhas
- Ao clicar no nome de um arquivo no painel, ele abre/baixa pelo link de
  compartilhamento do Google Drive (gerado automaticamente pelo workflow)
- Use senhas fortes: os blocos cifrados são públicos, então senha fraca
  pode ser quebrada por tentativa e erro

## Segurança — IMPORTANTE

O arquivo **`rclone/rclone.conf` contém o token de acesso ao seu Google Drive**.
Ele é criado na instalação e **está no `.gitignore` — nunca faça commit dele**,
nem o compartilhe. O mesmo vale para `painel.html` e os logs (podem conter nomes
de clientes), também ignorados por padrão.

## Requisitos

- Windows 10/11 (PowerShell 5.1+)
- Conta Google com acesso à pasta de backups

## Aviso sobre o rclone

A autorização padrão usa o `client_id` compartilhado do rclone, que o Google vai
desativar ao longo de 2026. Para uso contínuo, [crie o seu próprio client_id](https://rclone.org/drive/#making-your-own-client-id)
(grátis) e refaça a autorização com:

```
rclone\rclone.exe config create gdrive drive scope=drive.file client_id=SEU_ID client_secret=SEU_SECRET --config rclone\rclone.conf
```
