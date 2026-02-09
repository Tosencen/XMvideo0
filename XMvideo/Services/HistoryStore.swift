import Foundation
import Combine

class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    @Published var records: [HistoryRecord] = []
    
    private let maxRecords = 100
    private let storageKey = "compressionHistory"
    
    private init() {
        loadFromDisk()
    }
    
    func addRecord(_ record: HistoryRecord) {
        records.insert(record, at: 0) // Add to beginning (most recent first)
        
        // Enforce max records limit
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        
        saveToDisk()
    }
    
    func clearAll() {
        records.removeAll()
        saveToDisk()
    }
    
    func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            records = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            records = try decoder.decode([HistoryRecord].self, from: data)
            
            // Enforce max records limit on load
            if records.count > maxRecords {
                records = Array(records.prefix(maxRecords))
                saveToDisk()
            }
        } catch {
            print("Error loading history: \(error)")
            records = []
        }
    }
    
    func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Error saving history: \(error)")
        }
    }
    
    func getRecord(by id: UUID) -> HistoryRecord? {
        return records.first { $0.id == id }
    }
    
    func deleteRecord(by id: UUID) {
        records.removeAll { $0.id == id }
        saveToDisk()
    }
    
    var totalOriginalSize: Int64 {
        return records.reduce(0) { $0 + $1.originalSize }
    }
    
    var totalCompressedSize: Int64 {
        return records.reduce(0) { $0 + $1.compressedSize }
    }
    
    var totalSavedSize: Int64 {
        return totalOriginalSize - totalCompressedSize
    }
    
    var averageCompressionRatio: Double {
        guard !records.isEmpty else { return 0.0 }
        let sum = records.reduce(0.0) { $0 + $1.compressionRatio }
        return sum / Double(records.count)
    }
}
