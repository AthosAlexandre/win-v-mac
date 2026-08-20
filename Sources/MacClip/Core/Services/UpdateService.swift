import AppKit

/// Informações de uma release publicada no GitHub.
struct ReleaseInfo {
    let version: String     // versão sem o "v" (ex.: "1.1.0")
    let notes: String       // corpo da release (o "que mudou")
    let htmlURL: URL        // página da release no GitHub
    let zipURL: URL?        // asset .zip para download automático (se houver)
}

/// Verifica e aplica atualizações do app usando as **GitHub Releases** como fonte.
///
/// Fluxo: consulta a última release via API do GitHub, compara a versão (semver),
/// e — se houver novidade — permite baixar o `.zip`, trocar o app instalado e reabrir.
/// Não depende de Xcode nem de bibliotecas externas. Ver docs/ATUALIZACOES.md.
final class UpdateService {

    // Repositório onde as releases são publicadas.
    private let owner = "AthosAlexandre"
    private let repo = "win-v-mac"

    /// Versão atual do app (lida do Info.plist).
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Só faz sentido atualizar quando rodando como .app instalado (não em `swift run`).
    var isRunningAsBundle: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    // MARK: - Checagem

    /// Busca a última release. Chama `completion` na main thread (nil em caso de falha).
    func checkLatest(completion: @escaping (ReleaseInfo?) -> Void) {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            completion(nil); return
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            let info = data.flatMap(Self.parseRelease)
            DispatchQueue.main.async { completion(info) }
        }.resume()
    }

    private static func parseRelease(_ data: Data) -> ReleaseInfo? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let htmlString = json["html_url"] as? String,
              let htmlURL = URL(string: htmlString) else {
            return nil
        }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let notes = (json["body"] as? String) ?? ""

        var zipURL: URL?
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String, name.hasSuffix(".zip"),
                   let dl = asset["browser_download_url"] as? String {
                    zipURL = URL(string: dl)
                    break
                }
            }
        }
        return ReleaseInfo(version: version, notes: notes, htmlURL: htmlURL, zipURL: zipURL)
    }

    /// `true` se `latest` for uma versão semver maior que `current`.
    func isNewer(_ latest: String, than current: String) -> Bool {
        let a = latest.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    // MARK: - Download + instalação

    /// Baixa o `.zip` da release, troca o app instalado e agenda a reabertura.
    /// Ao concluir com sucesso, o chamador deve encerrar o app para o helper concluir a troca.
    func downloadAndInstall(_ info: ReleaseInfo, completion: @escaping (Bool) -> Void) {
        guard let zipURL = info.zipURL else {
            // Sem asset .zip: abre a página da release para download manual.
            NSWorkspace.shared.open(info.htmlURL)
            completion(false)
            return
        }

        URLSession.shared.downloadTask(with: zipURL) { [weak self] tempURL, _, error in
            guard let self, let tempURL, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let ok = self.installDownloadedZip(at: tempURL)
            DispatchQueue.main.async { completion(ok) }
        }.resume()
    }

    private func installDownloadedZip(at zip: URL) -> Bool {
        let fm = FileManager.default
        do {
            let workDir = fm.temporaryDirectory
                .appendingPathComponent("MacClipUpdate-\(UUID().uuidString)")
            try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

            let zipDest = workDir.appendingPathComponent("update.zip")
            try fm.moveItem(at: zip, to: zipDest)

            // Descompacta preservando a estrutura do bundle.
            guard run("/usr/bin/ditto", ["-x", "-k", zipDest.path, workDir.path]) == 0 else {
                return false
            }

            // Encontra o .app extraído.
            let entries = try fm.contentsOfDirectory(atPath: workDir.path)
            guard let appName = entries.first(where: { $0.hasSuffix(".app") }) else {
                return false
            }
            let newApp = workDir.appendingPathComponent(appName)

            // Remove o "quarantine" para o app abrir sem novo aviso do Gatekeeper.
            _ = run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", newApp.path])

            // Troca o app atual pelo novo, via helper que roda após este processo sair.
            launchSwapHelper(newAppPath: newApp.path, targetPath: Bundle.main.bundlePath)
            return true
        } catch {
            NSLog("MacClip: falha ao instalar atualização — \(error.localizedDescription)")
            return false
        }
    }

    /// Escreve e dispara (destacado) um script que espera o app sair, troca o bundle e reabre.
    private func launchSwapHelper(newAppPath: String, targetPath: String) {
        let script = """
        #!/bin/bash
        sleep 1
        rm -rf "\(targetPath)"
        /usr/bin/ditto "\(newAppPath)" "\(targetPath)"
        /usr/bin/xattr -dr com.apple.quarantine "\(targetPath)" 2>/dev/null
        open "\(targetPath)"
        """
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("macclip-update-\(UUID().uuidString).sh")
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptURL.path]
            try process.run()   // destacado: não esperamos terminar
        } catch {
            NSLog("MacClip: falha ao iniciar helper de atualização — \(error.localizedDescription)")
        }
    }

    @discardableResult
    private func run(_ launchPath: String, _ args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
