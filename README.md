# HtmlViewer

Visualizador leve de arquivos `.html` locais para Windows. Abre o HTML numa janela própria com WebView2, sem abas, extensões nem interface de navegador. Serve para abrir relatórios e protótipos HTML sem subir um navegador inteiro.

- A pasta do arquivo é servida como `https://app.local/`, então `fetch()`, módulos ES e caminhos relativos funcionam (o Chromium bloqueia isso em `file://`).
- O título da janela segue o `<title>` da página.
- `F12` abre o DevTools.

## Download

Exe único, pronto para usar (sem instalar):

- **Autônomo (~47 MB):** [HtmlViewer.exe](https://github.com/jessicascruz/HtmlViewer/raw/main/dist/portatil-autonomo/HtmlViewer.exe). Roda em qualquer Windows 10/11 x64, sem .NET.
- **Leve (~1,2 MB):** [HtmlViewer.exe](https://github.com/jessicascruz/HtmlViewer/raw/main/dist/portatil-leve/HtmlViewer.exe). Precisa do .NET Desktop Runtime 10.

Na primeira execução, o Windows SmartScreen pode avisar que o app não é reconhecido (o exe não é assinado): clique em "Mais informações" → "Executar assim mesmo". Depois, veja [Uso sem instalar](#uso-sem-instalar).

## Requisitos

- Windows 10/11 x64
- [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) (já vem no Windows 11)
- [.NET Desktop Runtime 10](https://dotnet.microsoft.com/download/dotnet/10.0), exceto na versão autônoma
- Para compilar: .NET SDK 10

## Instalação

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

O script compila, instala em `%LOCALAPPDATA%\HtmlViewer\app` e registra o app no menu "Abrir com" para `.html` e `.htm`. Não precisa de administrador: o registro fica só em `HKCU`.

Para usar como padrão: botão direito num `.html` → Abrir com → Escolher outro aplicativo → HtmlViewer → Sempre. O Windows não deixa um script definir o app padrão.

Para desinstalar (remove registro, app e dados):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## Uso sem instalar

O exe funciona sozinho, sem o `install.ps1`:

- Arraste um `.html` sobre o `HtmlViewer.exe`.
- Dê dois cliques no exe para escolher o arquivo.
- Coloque um atalho do exe em `shell:sendto` para ter "Enviar para → HtmlViewer".
- Pela linha de comando: `HtmlViewer.exe "C:\caminho\arquivo.html"`

Gerar um exe único e portátil:

```powershell
# leve (~1,2 MB), precisa do .NET Desktop Runtime 10
dotnet publish .\HtmlViewer.csproj -c Release -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=none --self-contained false -o .\dist\portatil-leve

# autônomo (~47 MB), não precisa de .NET instalado
dotnet publish .\HtmlViewer.csproj -c Release -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=none --self-contained true -p:EnableCompressionInSingleFile=true -o .\dist\portatil-autonomo
```

Mesmo sem instalar, o WebView2 guarda dados em `%LOCALAPPDATA%\HtmlViewer\WebView2`. Para limpar, basta apagar essa pasta.

## Desenvolvimento

```powershell
dotnet build .\HtmlViewer.csproj -c Release
dotnet run --project .\HtmlViewer.csproj -- "C:\caminho\arquivo.html"
```

Todo o app está em `Program.cs` (WinForms + `Microsoft.Web.WebView2`).

## Limitações e segurança

- **A página lê a pasta inteira.** O HTML tem acesso a todos os arquivos da pasta onde está e das subpastas. Não abra HTML de origem desconhecida (por exemplo, direto de `Downloads`).
- **Origem única.** Todo arquivo aberto usa a origem `https://app.local`, então `localStorage`, IndexedDB e cookies são compartilhados entre arquivos diferentes.
- **Links fora da pasta** (`../`) não funcionam.
- Popups (`window.open`, `target=_blank`) abrem numa janela padrão do WebView2.
