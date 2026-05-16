import 'dart:io';

const unixInstallCommand =
    'curl -fsSL https://tui.chessever.com/install.sh | sh';
const windowsInstallCommand =
    'iwr https://tui.chessever.com/install.ps1 -useb | iex';

class UpgradeRunner {
  const UpgradeRunner();

  Future<int> runForeground() async {
    if (Platform.isWindows) {
      await startDetached();
      return 0;
    }

    stdout.writeln('Upgrading Chessever with: $unixInstallCommand');
    final process = await Process.start(
      'sh',
      ['-c', unixInstallCommand],
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
  }

  Future<void> startDetached() async {
    if (Platform.isWindows) {
      final script = 'Start-Sleep -Seconds 1; $windowsInstallCommand';
      await Process.start(
        'powershell.exe',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
        mode: ProcessStartMode.detached,
      );
      return;
    }

    await Process.start(
      'sh',
      ['-c', 'sleep 1; $unixInstallCommand'],
      mode: ProcessStartMode.detached,
    );
  }
}
