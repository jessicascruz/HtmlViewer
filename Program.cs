using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        var path = args.FirstOrDefault();
        if (path is null)
        {
            using var dlg = new OpenFileDialog { Filter = "HTML|*.html;*.htm|Todos|*.*" };
            if (dlg.ShowDialog() != DialogResult.OK) return;
            path = dlg.FileName;
        }
        path = Path.GetFullPath(path);

        var form = new Form
        {
            Text = Path.GetFileName(path),
            Width = 1200,
            Height = 800,
            StartPosition = FormStartPosition.CenterScreen,
            Icon = Icon.ExtractAssociatedIcon(Environment.ProcessPath!),
        };
        var web = new WebView2 { Dock = DockStyle.Fill };
        form.Controls.Add(web);

        form.Load += async (_, _) =>
        {
            try
            {
                // Mesmo diretório de dados em todas as janelas => compartilham um único processo browser do WebView2.
                var dataDir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HtmlViewer", "WebView2");
                var env = await CoreWebView2Environment.CreateAsync(null, dataDir);
                await web.EnsureCoreWebView2Async(env);
                var core = web.CoreWebView2;

                // Serve a pasta do arquivo como https://app.local/ para fetch()/módulos ES funcionarem (file:// bloqueia).
                core.SetVirtualHostNameToFolderMapping(
                    "app.local", Path.GetDirectoryName(path)!, CoreWebView2HostResourceAccessKind.Allow);
                core.DocumentTitleChanged += (_, _) =>
                {
                    if (!string.IsNullOrWhiteSpace(core.DocumentTitle) && !core.DocumentTitle.StartsWith("https://app.local/"))
                        form.Text = core.DocumentTitle;
                };
                core.Navigate("https://app.local/" + Uri.EscapeDataString(Path.GetFileName(path)));
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "HtmlViewer", MessageBoxButtons.OK, MessageBoxIcon.Error);
                form.Close();
            }
        };

        Application.Run(form);
    }
}
