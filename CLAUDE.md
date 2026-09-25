# HtmlViewer

Visualizador leve de arquivos `.html` locais como app desktop no Windows. Abre o HTML numa janela própria com WebView2, sem abas, extensões nem interface de navegador. Serve para abrir relatórios/protótipos HTML sem subir um navegador inteiro.

## Stack

- .NET 10 (`net10.0-windows`), WinForms, `win-x64`, framework-dependent (precisa do .NET Desktop Runtime 10 na máquina).
- `Microsoft.Web.WebView2` (NuGet). Motor = Edge WebView2 Runtime, que já vem no Windows 11. Não distribuir runtime.

## Estrutura

- `Program.cs`: todo o app (um arquivo só, `Main` com `[STAThread]`).
- `HtmlViewer.csproj`: projeto. Contém target `RemoveWebView2Wpf` (ver Regras).
- `install.ps1`: compila, instala e registra no "Abrir com". `-Uninstall` desfaz tudo.
- `.gitignore`: `bin/`, `obj/`.
- `dist/`: builds portáteis **versionados no git** (links de download do README apontam para `dist/portatil-leve` e `dist/portatil-autonomo`). Ao mudar o código, regerar os dois exes antes do commit. Cada rebuild soma ~50 MB ao histórico.

## Funcionamento

1. Recebe o caminho do arquivo em `args[0]`. Sem argumento, abre `OpenFileDialog`.
2. Cria `CoreWebView2Environment` com pasta de dados fixa `%LOCALAPPDATA%\HtmlViewer\WebView2`. Mesma pasta em todas as janelas, então elas compartilham um único processo browser do WebView2.
3. `SetVirtualHostNameToFolderMapping("app.local", <pasta do arquivo>)`: a pasta do HTML vira `https://app.local/`. Isso permite `fetch()`, módulos ES e caminhos relativos, que o Chromium bloqueia em `file://`.
4. Navega para `https://app.local/<nome do arquivo escapado>`.
5. Título da janela = `<title>` da página (fallback: nome do arquivo).
6. Erro na inicialização (ex.: WebView2 Runtime ausente) mostra `MessageBox` e fecha.

## Instalação e registro

`install.ps1` faz:
- `dotnet publish` para `%LOCALAPPDATA%\HtmlViewer\app` (fora do repositório, então o app instalado independe desta pasta).
- Registro **só em HKCU** (sem admin):
  - `HKCU\Software\Classes\HtmlViewer.html`: ProgID com comando `"...\HtmlViewer.exe" "%1"` e ícone.
  - `HKCU\Software\Classes\Applications\HtmlViewer.exe`: `FriendlyAppName`, comando e `SupportedTypes` (`.html`, `.htm`).
  - `HKCU\Software\Classes\.html|.htm\OpenWithProgids`: valor `HtmlViewer.html`.
- Encerra instâncias abertas antes de publicar (senão o exe fica travado).

O script **não** define o app padrão: o Windows protege essa escolha (hash em `UserChoice`). O usuário escolhe em "Abrir com" e marca "Sempre".

## Uso sem instalar (portátil)

O `install.ps1` só serve para aparecer no "Abrir com". O exe funciona sozinho:

- `dotnet publish ... -o .\dist` gera uma pasta portátil (~2 MB, versionada no git) que pode ser copiada para qualquer lugar.
- **Arrastar** um `.html` sobre o `HtmlViewer.exe`: o arquivo chega em `args[0]`.
- **Dois cliques** no exe: abre o seletor de arquivo.
- **"Enviar para"**: atalho do exe em `shell:sendto`. Botão direito no `.html` → Enviar para → HtmlViewer. Não toca no registro.
- **"Abrir com" manual**: Abrir com → Escolher outro aplicativo → Procurar → `dist\HtmlViewer.exe`. O próprio Windows grava a associação, sem o script.

Exe único (ver Comandos): `portatil-leve` (~1,2 MB, exige .NET 10) ou `portatil-autonomo` (~47 MB, não exige nada além do WebView2 Runtime, que já vem no Windows 11). Os dois foram testados copiados sozinhos numa pasta vazia. `IncludeNativeLibrariesForSelfExtract` embute o `WebView2Loader.dll` nativo no exe. `PublishReferencesDocumentationFiles=false` (no `.csproj`) evita copiar os `.xml` de documentação do pacote. Não usar trimming (`PublishTrimmed`): WinForms não suporta.

Mesmo sem instalar, o WebView2 cria `%LOCALAPPDATA%\HtmlViewer\WebView2`. Para limpar, basta apagar essa pasta. A máquina precisa do .NET Desktop Runtime 10 (o SDK já inclui).

## Comandos

```powershell
# build
dotnet build .\HtmlViewer.csproj -c Release

# rodar sem instalar
dotnet run --project .\HtmlViewer.csproj -- "C:\caminho\arquivo.html"

# pasta portátil em .\dist (exe + DLLs, sem registro)
dotnet publish .\HtmlViewer.csproj -c Release -o .\dist

# exe ÚNICO leve (~1,2 MB) - precisa do .NET Desktop Runtime 10 na máquina
dotnet publish .\HtmlViewer.csproj -c Release -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=none --self-contained false -o .\dist\portatil-leve

# exe ÚNICO autônomo (~47 MB) - roda em qualquer Windows 10/11 x64, sem .NET instalado
dotnet publish .\HtmlViewer.csproj -c Release -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=none --self-contained true -p:EnableCompressionInSingleFile=true -o .\dist\portatil-autonomo

# instalar / atualizar (recompila e re-registra)
powershell -ExecutionPolicy Bypass -File .\install.ps1

# desinstalar (remove registro, app e pasta de dados)
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## Teste / depuração

Não há testes automatizados. Teste de fumaça:
1. Criar uma pasta com `data.json` e um HTML (com espaço no nome) que faz `fetch('data.json')` e muda `document.title`.
2. Abrir com a porta de debug ligada e conferir título/URL:

```powershell
$env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = '--remote-debugging-port=9333'
$p = Start-Process .\bin\Release\net10.0-windows\win-x64\HtmlViewer.exe -ArgumentList '"C:\teste\meu teste.html"' -PassThru
Start-Sleep 6
Invoke-RestMethod http://127.0.0.1:9333/json | Select-Object title, url
Stop-Process -Id $p.Id
```

Esperado: `url = https://app.local/meu%20teste.html` e o título alterado pelo script da página.

DevTools: `F12` na janela do app (padrão do WebView2, mantido de propósito).

## Números de referência (medidos em 2026-09-25)

- Pasta publicada: ~2 MB.
- RAM com uma página simples: ~158 MB privados, somando 7 processos (host + processos do WebView2). Esse é o piso do motor e não dá para reduzir.
- Primeira abertura: alguns segundos (WebView2 cria a pasta de dados). Depois abre rápido.

## Regras

- **Objetivo é ser leve.** Não trocar por Electron/CEF (embute Chromium próprio). Não adicionar dependências além do WebView2 sem necessidade clara.
- **Manter mínimo:** um arquivo `Program.cs`, sem camadas/abstrações. Recurso novo só quando pedido.
- **`[STAThread]` obrigatório** em `Main`: WinForms e `OpenFileDialog` exigem STA. Por isso não usar top-level statements.
- **Não remover o target `RemoveWebView2Wpf`** do `.csproj`: o pacote WebView2 referencia a DLL WPF, que gera conflito de `WindowsBase` (warning MSB3277). O app é só WinForms.
- **Registro só em HKCU.** Nunca HKLM/admin. Qualquer chave nova no `install.ps1` deve ser removida também no `-Uninstall`.
- **Não expor APIs nativas à página** (`AddHostObjectToScript`, `WebMessageReceived` com ações de sistema): o app abre HTML arbitrário.
- Build deve terminar com **0 avisos**.

## Limitações conhecidas

- **A página lê a pasta inteira:** o mapeamento dá acesso a todos os arquivos da pasta do HTML e subpastas. Um HTML malicioso em `Downloads` poderia ler outros downloads. Não usar para HTML de origem desconhecida.
- **Origem única:** todo HTML aberto tem a origem `https://app.local`, então `localStorage`/IndexedDB/cookies são compartilhados entre arquivos diferentes, mesmo de pastas diferentes.
- **Uma pasta por janela:** o mapeamento é da pasta do arquivo aberto. Links para `../` fora dela não resolvem.
- Popups (`window.open`, `target=_blank`) abrem em janela padrão do WebView2, sem tratamento próprio.
