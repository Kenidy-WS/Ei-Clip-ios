import Darwin
import Foundation

@_silgen_name("swift_demangle")
fileprivate func swiftDemangleC(
    _ mangledName: UnsafePointer<CChar>?, _ mangledNameLength: UInt, _ outputBuffer: UnsafeMutablePointer<CChar>?,
    _ outputBufferSize: UnsafeMutablePointer<UInt>?, _ flags: UInt32
) -> UnsafeMutablePointer<CChar>?

/// v0.6.22: fotografia (pilha) de cada linha de execução do app, usada pelo vigia SÓ quando a tela principal já está
/// travada. Cada linha é suspensa por instantes, lida e liberada; nada é alocado enquanto uma linha está suspensa (senão
/// o vigia poderia travar junto, esperando uma trava de memória que a linha suspensa segura). Os endereços viram nomes
/// depois, com tudo já liberado. Não muda nada do comportamento do app.
enum ThreadSampler {
    private static let maxFrames = 14
    /// Tira os bits de assinatura de ponteiro dos endereços de retorno.
    private static let stripMask: UInt = 0x0000_000F_FFFF_FFFF

    struct Captured {
        let isMain: Bool
        let index: Int
        let name: String
        let addresses: [UInt]
    }

    /// Linhas de texto prontas para o Diagnóstico (a da tela principal primeiro).
    static func dumpLines() -> [String] {
        let captured = capture()
        var lines: [String] = []
        var idle = 0
        for t in captured.sorted(by: { $0.isMain && !$1.isMain }) {
            let symbols = t.addresses.map { symbol(for: $0) }
            if !t.isMain, let top = symbols.first, StackText.isIdle(topSymbol: top) {
                idle += 1
                continue
            }
            let label = t.isMain ? "principal" : "thread \(t.index)" + (t.name.isEmpty ? "" : " \"\(t.name)\"")
            lines.append(StackText.line(label: label, symbols: symbols))
        }
        if idle > 0 { lines.append("(\(idle) linhas de execução ociosas omitidas)") }
        return lines
    }

    // MARK: - Captura

    private static func capture() -> [Captured] {
        #if arch(arm64)
        var list: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &list, &count) == KERN_SUCCESS, let threads = list else { return [] }
        let mainPort = pthread_mach_thread_np(pthread_main_thread_np())
        let selfPort = pthread_mach_thread_np(pthread_self())
        // Memória reservada ANTES de suspender qualquer linha de execução.
        let frames = UnsafeMutablePointer<UInt>.allocate(capacity: maxFrames)
        let scratch = UnsafeMutablePointer<UInt>.allocate(capacity: 2)
        defer {
            frames.deallocate()
            scratch.deallocate()
            for i in 0..<Int(count) { mach_port_deallocate(mach_task_self_, threads[i]) }
            vm_deallocate(
                mach_task_self_, vm_address_t(UInt(bitPattern: threads)),
                vm_size_t(Int(count) * MemoryLayout<thread_t>.size))
        }
        var result: [Captured] = []
        result.reserveCapacity(Int(count))
        for i in 0..<Int(count) {
            let port = threads[i]
            if port == selfPort { continue }
            let n = sampleOne(port, frames: frames, scratch: scratch)  // devolve com a linha já liberada
            var addresses: [UInt] = []
            addresses.reserveCapacity(n)
            for k in 0..<n { addresses.append(frames[k]) }
            result.append(Captured(isMain: port == mainPort, index: i, name: threadName(port), addresses: addresses))
        }
        return result
        #else
        return []
        #endif
    }

    #if arch(arm64)
    /// Suspende a linha, lê pc, lr e a cadeia de fp, e a libera. SEM alocação de memória aqui dentro.
    private static func sampleOne(_ port: thread_act_t, frames: UnsafeMutablePointer<UInt>, scratch: UnsafeMutablePointer<UInt>) -> Int {
        guard thread_suspend(port) == KERN_SUCCESS else { return 0 }
        var n = 0
        var state = arm_thread_state64_t()
        var stateCount = mach_msg_type_number_t(MemoryLayout<arm_thread_state64_t>.size / MemoryLayout<UInt32>.size)
        let capacity = Int(stateCount)
        let kr = withUnsafeMutablePointer(to: &state) { statePtr in
            statePtr.withMemoryRebound(to: natural_t.self, capacity: capacity) { raw in
                thread_get_state(port, thread_state_flavor_t(ARM_THREAD_STATE64), raw, &stateCount)
            }
        }
        if kr == KERN_SUCCESS {
            frames[0] = UInt(state.__pc) & stripMask
            n = 1
            frames[n] = UInt(state.__lr) & stripMask
            n += 1
            var fp = UInt(state.__fp)
            while n < maxFrames, fp != 0, fp & 0x7 == 0 {
                var outSize: vm_size_t = 0
                let rc = vm_read_overwrite(mach_task_self_, vm_address_t(fp), 16, vm_address_t(UInt(bitPattern: scratch)), &outSize)
                guard rc == KERN_SUCCESS, outSize == 16 else { break }
                let next = scratch[0]
                let ret = scratch[1] & stripMask
                if ret == 0 { break }
                frames[n] = ret
                n += 1
                if next <= fp { break }
                fp = next
            }
        }
        thread_resume(port)
        return n
    }
    #endif

    private static func threadName(_ port: thread_act_t) -> String {
        guard let pt = pthread_from_mach_thread_np(port) else { return "" }
        var buffer = [CChar](repeating: 0, count: 64)
        guard pthread_getname_np(pt, &buffer, 64) == 0 else { return "" }
        return String(cString: buffer)
    }

    // MARK: - Nomes

    private static func symbol(for address: UInt) -> String {
        guard let pointer = UnsafeRawPointer(bitPattern: address) else { return "?" }
        var info = Dl_info()
        guard dladdr(pointer, &info) != 0 else { return "0x" + String(address, radix: 16) }
        if let raw = info.dli_sname {
            return demangle(String(cString: raw))
        }
        let image = info.dli_fname.map { URL(fileURLWithPath: String(cString: $0)).lastPathComponent } ?? "?"
        let offset = address &- UInt(bitPattern: info.dli_fbase)
        return "\(image)+0x" + String(offset, radix: 16)
    }

    private static func demangle(_ name: String) -> String {
        guard name.hasPrefix("$s") || name.hasPrefix("_$s") || name.hasPrefix("$S") else { return name }
        return name.withCString { cString -> String in
            guard let out = swiftDemangleC(cString, UInt(strlen(cString)), nil, nil, 0) else { return name }
            defer { free(out) }
            return String(cString: out)
        }
    }
}
