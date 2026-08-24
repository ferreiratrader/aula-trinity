# ═══════════════════════════════════════════════════════════════
#  Publicar a aula do dia — Trinity
#  Rode pelo atalho "Publicar aula.cmd" (duplo clique).
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = 'Stop'
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $pasta

$SITE = 'https://ferreiratrader.github.io/aula-trinity/'

function Titulo($t) {
  Write-Host ''
  Write-Host "  $t" -ForegroundColor Yellow
  Write-Host ('  ' + ('-' * 58)) -ForegroundColor DarkGray
}

function Fim($msg, $cor) {
  Write-Host ''
  Write-Host "  $msg" -ForegroundColor $cor
  Write-Host ''
  Read-Host '  Pressione ENTER para fechar'
  exit
}

Clear-Host
Write-Host ''
Write-Host '   TRINITY — PUBLICAR A AULA DE HOJE' -ForegroundColor Yellow
Write-Host '   ══════════════════════════════════════════════════════════' -ForegroundColor DarkYellow

# ── lê a aula que está no ar ───────────────────────────────────
$arquivo = Join-Path $pasta 'aula.json'
if (-not (Test-Path $arquivo)) { Fim 'Não encontrei o arquivo aula.json nesta pasta.' 'Red' }
$atual = Get-Content $arquivo -Raw -Encoding UTF8 | ConvertFrom-Json

Titulo 'NO AR AGORA'
if ($atual.videoId) {
  Write-Host "   Aula $($atual.numero)  ·  video $($atual.videoId)"
} else {
  Write-Host '   Nenhuma aula publicada ainda.'
}

# ── link do novo video ─────────────────────────────────────────
Titulo 'LINK DA AULA NOVA'
Write-Host '   Cole o link do YouTube e aperte ENTER.'
Write-Host '   (ENTER vazio = cancelar)' -ForegroundColor DarkGray
Write-Host ''
$link = Read-Host '   Link'
if ([string]::IsNullOrWhiteSpace($link)) { Fim 'Cancelado. Nada foi publicado.' 'DarkGray' }

$id = $null
foreach ($padrao in @('[?&]v=([\w-]{11})', 'youtu\.be/([\w-]{11})', '/live/([\w-]{11})', '/embed/([\w-]{11})', '/shorts/([\w-]{11})', '^([\w-]{11})$')) {
  $m = [regex]::Match($link.Trim(), $padrao)
  if ($m.Success) { $id = $m.Groups[1].Value; break }
}
if (-not $id) { Fim 'Não reconheci o código do vídeo nesse link. Confira e rode de novo.' 'Red' }
if ($id -eq $atual.videoId) { Fim 'Esse vídeo já é o que está no ar. Nada mudou.' 'DarkGray' }

Write-Host "   Vídeo identificado: $id" -ForegroundColor Green

# ── numero da aula ─────────────────────────────────────────────
$sugerido = [int]$atual.numero + 1
Titulo 'NÚMERO DA AULA'
$resp = Read-Host "   Número desta aula [ENTER = $sugerido]"
if ([string]::IsNullOrWhiteSpace($resp)) { $numero = $sugerido }
elseif ($resp -match '^\d+$') { $numero = [int]$resp }
else { Fim 'Número inválido. Rode de novo e digite apenas números.' 'Red' }

# ── grava a aula nova ──────────────────────────────────────────
$nova = [ordered]@{
  videoId       = $id
  numero        = $numero
  linkGrupo     = $atual.linkGrupo
  videoAnterior = $atual.videoId
  publicadaEm   = (Get-Date -Format 'yyyy-MM-dd')
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($arquivo, (($nova | ConvertTo-Json) + "`n"), $utf8)

# a previa do WhatsApp le o HTML, entao a imagem tem de ir junto
$html = Get-Content (Join-Path $pasta 'index.html') -Raw -Encoding UTF8
$html = [regex]::Replace($html, 'https://i\.ytimg\.com/vi/[\w-]{11}/maxresdefault\.jpg', "https://i.ytimg.com/vi/$id/maxresdefault.jpg")
$html = [regex]::Replace($html, 'videoId: "[\w-]*"', "videoId: `"$id`"")
$html = [regex]::Replace($html, 'numero: \d+', "numero: $numero")
[System.IO.File]::WriteAllText((Join-Path $pasta 'index.html'), $html, $utf8)

# ── publica ────────────────────────────────────────────────────
Titulo 'PUBLICANDO'
git add aula.json index.html | Out-Null
git commit -m "Aula $numero no ar" -m "Vídeo $id" | Out-Null
if ($LASTEXITCODE -ne 0) { Fim 'Não consegui registrar a alteração (git commit).' 'Red' }
git push --quiet
if ($LASTEXITCODE -ne 0) {
  Fim 'Falhou ao enviar para o site. Verifique a internet e rode de novo.' 'Red'
}
Write-Host '   Enviado. O site atualiza em até 1 minuto.' -ForegroundColor Green

# ── o que fazer agora ──────────────────────────────────────────
$linkGrupo = "$SITE`?aula=$numero"
Set-Clipboard -Value $linkGrupo

Titulo 'PRONTO — FALTAM 2 PASSOS SEUS'
Write-Host '   1. No YouTube, coloque a aula anterior como PRIVADA:' -ForegroundColor White
if ($atual.videoId) {
  Write-Host "      https://studio.youtube.com/video/$($atual.videoId)/edit" -ForegroundColor DarkGray
} else {
  Write-Host '      (não havia aula anterior)' -ForegroundColor DarkGray
}
Write-Host ''
Write-Host '   2. Mande no grupo o link abaixo (já copiado):' -ForegroundColor White
Write-Host "      $linkGrupo" -ForegroundColor Yellow
Write-Host ''
Write-Host '   Obs: o número no fim do link faz o WhatsApp mostrar a capa nova.' -ForegroundColor DarkGray

Fim 'Aula publicada.' 'Green'
