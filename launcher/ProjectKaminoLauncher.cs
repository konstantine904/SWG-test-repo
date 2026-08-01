using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace ProjectKaminoLauncher
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new LauncherForm());
        }
    }

    internal sealed class LauncherForm : Form
    {
        private static readonly Color Background = Color.FromArgb(13, 25, 37);
        private static readonly Color PanelColor = Color.FromArgb(22, 42, 58);
        private static readonly Color Gold = Color.FromArgb(224, 165, 64);
        private static readonly Color Pale = Color.FromArgb(220, 229, 235);
        private static readonly Color Muted = Color.FromArgb(142, 164, 180);

        private readonly TextBox clientPath = new TextBox();
        private readonly TextBox serverAddress = new TextBox();
        private readonly NumericUpDown loginPort = new NumericUpDown();
        private readonly Label status = new Label();
        private readonly Button playButton;
        private readonly string settingsDirectory;
        private readonly string launcherSettingsPath;

        public LauncherForm()
        {
            settingsDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ProjectKamino");
            launcherSettingsPath = Path.Combine(settingsDirectory, "launcher.ini");

            Text = "Project Kamino Launcher";
            ClientSize = new Size(1040, 690);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Background;
            ForeColor = Pale;
            Font = new Font("Segoe UI", 10F);
            BackgroundImageLayout = ImageLayout.Stretch;

            Stream backgroundStream = Assembly.GetExecutingAssembly()
                .GetManifestResourceStream("ProjectKamino.Background.png");
            if (backgroundStream != null) {
                using (backgroundStream)
                using (var loadedBackground = new Bitmap(backgroundStream))
                    BackgroundImage = new Bitmap(loadedBackground);
            }
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);

            var connectionPanel = CreatePanel(new Point(32, 425), new Size(976, 140));
            connectionPanel.Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom;
            Controls.Add(connectionPanel);

            AddLabel(connectionPanel, "CLIENT INSTALLATION", 20, 10);
            ConfigureTextBox(clientPath, 20, 32, 810);
            clientPath.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            connectionPanel.Controls.Add(clientPath);
            var browse = CreateButton("SELECT CLIENT", 840, 30, 116, 33, false);
            browse.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            browse.Click += BrowseClient;
            connectionPanel.Controls.Add(browse);

            AddLabel(connectionPanel, "SERVER ADDRESS", 20, 74);
            ConfigureTextBox(serverAddress, 20, 96, 610);
            connectionPanel.Controls.Add(serverAddress);

            AddLabel(connectionPanel, "LOGIN PORT", 650, 74);
            loginPort.Location = new Point(650, 96);
            loginPort.Size = new Size(120, 29);
            loginPort.Minimum = 1;
            loginPort.Maximum = 65535;
            loginPort.Value = 44453;
            loginPort.BackColor = Color.FromArgb(8, 18, 28);
            loginPort.ForeColor = Pale;
            connectionPanel.Controls.Add(loginPort);

            var save = CreateButton("SAVE CONNECTION", 790, 94, 166, 33, false);
            save.Click += delegate { SaveConnection(true); };
            connectionPanel.Controls.Add(save);

            playButton = CreateButton("PLAY PROJECT KAMINO", 32, 580, 390, 55, true);
            playButton.Anchor = AnchorStyles.Left | AnchorStyles.Bottom;
            playButton.Click += PlayGame;
            Controls.Add(playButton);

            var setupButton = CreateButton("GAME & DISPLAY SETTINGS", 438, 580, 280, 55, false);
            setupButton.Anchor = AnchorStyles.Bottom;
            setupButton.Click += OpenSetup;
            Controls.Add(setupButton);

            var folderButton = CreateButton("OPEN CLIENT FOLDER", 734, 580, 274, 55, false);
            folderButton.Anchor = AnchorStyles.Right | AnchorStyles.Bottom;
            folderButton.Click += OpenClientFolder;
            Controls.Add(folderButton);

            var testButton = CreateButton("CHECK SERVER", 858, 646, 150, 30, false);
            testButton.Anchor = AnchorStyles.Right | AnchorStyles.Bottom;
            testButton.Click += CheckServer;
            Controls.Add(testButton);

            status.Text = "Ready";
            status.ForeColor = Muted;
            status.AutoEllipsis = true;
            status.BackColor = Color.FromArgb(8, 18, 28);
            status.Padding = new Padding(10, 5, 10, 0);
            status.Location = new Point(32, 646);
            status.Size = new Size(810, 30);
            status.Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom;
            Controls.Add(status);

            var hint = new Label {
                Text = "Resolution, fullscreen, windowed, borderless, sound, and graphics are configured through SWGEmu Setup.",
                ForeColor = Muted,
                BackColor = Color.FromArgb(8, 18, 28),
                Padding = new Padding(10, 0, 10, 0),
                AutoSize = false,
                TextAlign = ContentAlignment.MiddleLeft,
                Location = new Point(32, 394),
                Size = new Size(976, 25),
                Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom
            };
            Controls.Add(hint);

            AcceptButton = playButton;
            LoadSettings();
            ValidateClient(false);
            EnsureProjectKaminoClientAssets(false);
        }

        private Panel CreatePanel(Point location, Size size)
        {
            return new Panel {
                Location = location,
                Size = size,
                BackColor = PanelColor
            };
        }

        private static void AddLabel(Control parent, string text, int x, int y)
        {
            parent.Controls.Add(new Label {
                Text = text,
                ForeColor = Muted,
                Font = new Font("Segoe UI Semibold", 8.5F),
                AutoSize = true,
                Location = new Point(x, y)
            });
        }

        private static void ConfigureTextBox(TextBox box, int x, int y, int width)
        {
            box.Location = new Point(x, y);
            box.Size = new Size(width, 29);
            box.BackColor = Color.FromArgb(8, 18, 28);
            box.ForeColor = Pale;
            box.BorderStyle = BorderStyle.FixedSingle;
        }

        private Button CreateButton(string text, int x, int y, int width, int height, bool primary)
        {
            var button = new Button {
                Text = text,
                Location = new Point(x, y),
                Size = new Size(width, height),
                FlatStyle = FlatStyle.Flat,
                BackColor = primary ? Gold : PanelColor,
                ForeColor = primary ? Background : Pale,
                Cursor = Cursors.Hand,
                Font = new Font("Segoe UI Semibold", primary ? 11F : 9.5F),
                UseVisualStyleBackColor = false
            };
            button.FlatAppearance.BorderColor = primary ? Gold : Color.FromArgb(57, 83, 101);
            button.FlatAppearance.MouseOverBackColor = primary
                ? Color.FromArgb(240, 183, 78)
                : Color.FromArgb(35, 61, 79);
            return button;
        }

        private string ClientDirectory
        {
            get { return Environment.ExpandEnvironmentVariables(clientPath.Text.Trim().Trim('"')); }
        }

        private void LoadSettings()
        {
            string defaultClient = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(
                Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            if (!File.Exists(Path.Combine(defaultClient, "SWGEmu.exe")))
                defaultClient = @"C:\ProjectKamino\Client";

            clientPath.Text = defaultClient;
            serverAddress.Text = "127.0.0.1";

            if (File.Exists(launcherSettingsPath)) {
                foreach (string line in File.ReadAllLines(launcherSettingsPath)) {
                    int separator = line.IndexOf('=');
                    if (separator < 1) continue;
                    string key = line.Substring(0, separator).Trim();
                    string value = line.Substring(separator + 1).Trim();
                    if (key.Equals("ClientPath", StringComparison.OrdinalIgnoreCase))
                        clientPath.Text = value;
                }
            }

            ReadConnection();
        }

        private void ReadConnection()
        {
            string config = Path.Combine(ClientDirectory, "swgemu_login.cfg");
            if (!File.Exists(config)) return;
            string content = File.ReadAllText(config);
            Match hostMatch = Regex.Match(content, @"(?im)^\s*loginServerAddress0\s*=\s*(.+?)\s*$");
            Match portMatch = Regex.Match(content, @"(?im)^\s*loginServerPort0\s*=\s*(\d+)\s*$");
            if (hostMatch.Success) serverAddress.Text = hostMatch.Groups[1].Value.Trim();
            decimal parsedPort;
            if (portMatch.Success && Decimal.TryParse(portMatch.Groups[1].Value, out parsedPort)
                && parsedPort >= 1 && parsedPort <= 65535)
                loginPort.Value = parsedPort;
        }

        private bool ValidateClient(bool showMessage)
        {
            string directory = ClientDirectory;
            string[] required = { "SWGEmu.exe", "SWGEmu_Setup.exe", "swgemu.cfg" };
            foreach (string file in required) {
                if (!File.Exists(Path.Combine(directory, file))) {
                    playButton.Enabled = false;
                    SetStatus("Select a valid Project Kamino client folder.", true);
                    if (showMessage)
                        MessageBox.Show(this, "The selected folder is missing " + file + ".",
                            "Invalid client folder", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return false;
                }
            }
            playButton.Enabled = true;
            SetStatus("Client ready • " + directory, false);
            return true;
        }

        private bool EnsureProjectKaminoClientAssets(bool showMessage)
        {
            if (!ValidateClient(showMessage)) return false;

            try {
                int updatedFiles = 0;
                string clientRoot = Path.GetFullPath(ClientDirectory)
                    .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                    + Path.DirectorySeparatorChar;

                using (Stream stream = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream("ProjectKamino.ClientAssets.zip")) {
                    if (stream == null)
                        throw new InvalidOperationException(
                            "The packaged Project Kamino client assets are missing.");

                    using (var archive = new ZipArchive(stream, ZipArchiveMode.Read)) {
                        foreach (ZipArchiveEntry entry in archive.Entries) {
                            if (String.IsNullOrEmpty(entry.Name)) continue;

                            string relativePath = entry.FullName.Replace(
                                '/', Path.DirectorySeparatorChar);
                            string destination = Path.GetFullPath(
                                Path.Combine(clientRoot, relativePath));
                            if (!destination.StartsWith(clientRoot,
                                StringComparison.OrdinalIgnoreCase))
                                throw new InvalidDataException(
                                    "Unsafe client asset path: " + entry.FullName);

                            bool needsUpdate = !File.Exists(destination)
                                || new FileInfo(destination).Length != entry.Length;
                            if (!needsUpdate) {
                                using (Stream packaged = entry.Open())
                                using (Stream installed = File.OpenRead(destination)) {
                                    int packagedByte;
                                    while ((packagedByte = packaged.ReadByte()) >= 0) {
                                        if (installed.ReadByte() != packagedByte) {
                                            needsUpdate = true;
                                            break;
                                        }
                                    }
                                }
                            }

                            if (needsUpdate) {
                                Directory.CreateDirectory(Path.GetDirectoryName(destination));
                                using (Stream packaged = entry.Open())
                                using (Stream installed = File.Create(destination))
                                    packaged.CopyTo(installed);
                                ++updatedFiles;
                            }
                        }
                    }
                }

                if (updatedFiles > 0) {
                    SetStatus("Project Kamino updated " + updatedFiles
                        + " client asset(s) - restart SWG if it was open.", false);
                }

                return true;
            } catch (Exception ex) {
                SetStatus("Project Kamino client data could not be installed.", true);
                if (showMessage)
                    ShowError("Could not install the Project Kamino client data.", ex);
                return false;
            }
        }

        private void BrowseClient(object sender, EventArgs e)
        {
            using (var dialog = new FolderBrowserDialog()) {
                dialog.Description = "Select the folder containing SWGEmu.exe";
                dialog.SelectedPath = Directory.Exists(ClientDirectory) ? ClientDirectory : "";
                if (dialog.ShowDialog(this) == DialogResult.OK) {
                    clientPath.Text = dialog.SelectedPath;
                    ReadConnection();
                    EnsureProjectKaminoClientAssets(true);
                }
            }
        }

        private bool SaveConnection(bool notify)
        {
            if (!EnsureProjectKaminoClientAssets(true)) return false;
            string host = serverAddress.Text.Trim();
            if (host.Length == 0 || host.IndexOfAny(new[] { ' ', '\t', '\r', '\n', '"', '\'' }) >= 0) {
                MessageBox.Show(this, "Enter a valid server IP address or DNS name.",
                    "Invalid server address", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }

            string configPath = Path.Combine(ClientDirectory, "swgemu_login.cfg");
            string content = File.Exists(configPath)
                ? File.ReadAllText(configPath)
                : "[ClientGame]\r\n";
            if (File.Exists(configPath) && !File.Exists(configPath + ".launcher-backup"))
                File.Copy(configPath, configPath + ".launcher-backup");

            content = SetConfigValue(content, "ClientGame", "loginServerAddress0", host);
            content = SetConfigValue(content, "ClientGame", "loginServerPort0",
                Decimal.ToInt32(loginPort.Value).ToString());
            File.WriteAllText(configPath, content, new UTF8Encoding(false));

            Directory.CreateDirectory(settingsDirectory);
            File.WriteAllText(launcherSettingsPath, "ClientPath=" + ClientDirectory + Environment.NewLine,
                new UTF8Encoding(false));
            SetStatus("Connection saved: " + host + ":" + loginPort.Value, false);
            if (notify)
                MessageBox.Show(this, "Project Kamino connection settings were saved.",
                    "Connection saved", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return true;
        }

        private static string SetConfigValue(string content, string section, string key, string value)
        {
            string keyPattern = @"(?im)^(\s*" + Regex.Escape(key) + @"\s*=\s*).*$";
            if (Regex.IsMatch(content, keyPattern))
                return new Regex(keyPattern).Replace(content,
                    delegate(Match match) { return match.Groups[1].Value + value; }, 1);

            string sectionPattern = @"(?im)^\s*\[" + Regex.Escape(section) + @"\]\s*$";
            Match sectionMatch = Regex.Match(content, sectionPattern);
            string newLine = key + "=" + value + "\r\n";
            if (sectionMatch.Success)
                return content.Insert(sectionMatch.Index + sectionMatch.Length, "\r\n" + newLine);
            return content.TrimEnd() + "\r\n\r\n[" + section + "]\r\n" + newLine;
        }

        private void PlayGame(object sender, EventArgs e)
        {
            try {
                if (!SaveConnection(false)) return;
                StartClientProgram("SWGEmu.exe");
                SetStatus("Project Kamino launched.", false);
                WindowState = FormWindowState.Minimized;
            } catch (Exception ex) {
                ShowError("Could not launch the game.", ex);
            }
        }

        private void OpenSetup(object sender, EventArgs e)
        {
            try {
                if (!ValidateClient(true)) return;
                StartClientProgram("SWGEmu_Setup.exe");
                SetStatus("SWGEmu Setup opened. Save your settings there when finished.", false);
            } catch (Exception ex) {
                ShowError("Could not open SWGEmu Setup.", ex);
            }
        }

        private void StartClientProgram(string fileName)
        {
            Process.Start(new ProcessStartInfo {
                FileName = Path.Combine(ClientDirectory, fileName),
                WorkingDirectory = ClientDirectory,
                UseShellExecute = true
            });
        }

        private void OpenClientFolder(object sender, EventArgs e)
        {
            try {
                if (!ValidateClient(true)) return;
                Process.Start(new ProcessStartInfo {
                    FileName = ClientDirectory,
                    UseShellExecute = true
                });
            } catch (Exception ex) {
                ShowError("Could not open the client folder.", ex);
            }
        }

        private void CheckServer(object sender, EventArgs e)
        {
            string host = serverAddress.Text.Trim();
            int port = Decimal.ToInt32(loginPort.Value);
            SetStatus("Resolving " + host + "…", false);
            Application.DoEvents();
            try {
                IPAddress[] addresses = Dns.GetHostAddresses(host);
                if (addresses.Length == 0) throw new SocketException();
                SetStatus("Server address resolved • UDP login " + host + ":" + port
                    + " (final reachability is checked when the game connects)", false);
            } catch (Exception ex) {
                SetStatus("Server address could not be resolved.", true);
                MessageBox.Show(this, ex.Message, "Server check failed",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void SetStatus(string text, bool error)
        {
            status.Text = text;
            status.ForeColor = error ? Color.FromArgb(239, 115, 105) : Muted;
        }

        private void ShowError(string message, Exception ex)
        {
            SetStatus(message, true);
            MessageBox.Show(this, message + Environment.NewLine + Environment.NewLine + ex.Message,
                "Project Kamino Launcher", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
