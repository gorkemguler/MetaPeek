import Foundation

/// App-chrome strings only. Metadata section titles and field keys (EXIF,
/// GPS, MD5) stay in English everywhere, matching every other metadata tool
/// (exiftool, ffprobe) so CTF/OSINT output stays recognizable.
enum L10n {
    static let isTurkish = Locale.preferredLanguages.first?.hasPrefix("tr") ?? false

    private static func t(_ turkish: String, _ english: String) -> String {
        isTurkish ? turkish : english
    }

    static var open: String { t("Aç", "Open") }
    static var clear: String { t("Temizle", "Clear") }
    static var remove: String { t("Kaldır", "Remove") }
    static var processing: String { t("İşleniyor…", "Processing…") }
    static var selectFileTitle: String { t("Bir dosya seçin", "Select a file") }
    static var selectFileSubtitle: String { t("Soldaki listeden bir dosya seçin ya da yeni dosya ekleyin", "Choose a file from the list on the left, or add a new one") }
    static var dropOrOpenTitle: String { t("Dosya sürükleyin\nveya açın", "Drag a file\nor open one") }
    static var dropOrOpenSubtitle: String { t("Herhangi bir dosya uzantısı desteklenir", "Any file extension is supported") }
    static var searchPlaceholder: String { t("Metadata içinde ara", "Search metadata") }
    static var copy: String { t("Kopyala", "Copy") }
    static var exportJSON: String { t("JSON Dışa Aktar", "Export JSON") }
    static var openInMaps: String { t("Haritalar'da Aç", "Open in Maps") }
    static var entropyLow: String { t("Düşük: muhtemelen düz metin veya yapısal veri", "Low: likely plain text or structured data") }
    static var entropyMedium: String { t("Orta", "Medium") }
    static var entropyHigh: String { t("Yüksek: sıkıştırılmış, şifrelenmiş veya paketlenmiş olabilir", "High: possibly compressed, encrypted, or packed") }

    static var elaTitle: String { t("Hata Seviyesi Analizi (ELA)", "Error Level Analysis (ELA)") }
    static var elaExplanation: String {
        t("Görsel JPEG olarak yeniden sıkıştırılıp orijinaliyle farkı alındı. Sonradan düzenlenen veya yapıştırılan bölgeler çevresinden daha parlak çıkma eğilimindedir. En anlamlı sonucu JPEG dosyalarda verir.",
          "The image was re-compressed as JPEG and compared against the original. Regions that were edited or pasted in tend to show up brighter than their surroundings. Most meaningful on JPEG files.")
    }
    static var hiddenPixelsTitle: String { t("Gizli Pikseller (LSB)", "Hidden Pixels (LSB)") }
    static var hiddenPixelsExplanation: String {
        t("Her renk kanalının en düşük anlamlı biti görüntüye çevrildi. Rastgele gürültü normaldir; yazı, şekil veya keskin bloklar görünmesi gömülü veri (steganografi) işareti olabilir.",
          "The least significant bit of each colour channel is rendered as an image. Random noise is normal; visible text, shapes or sharp blocks can indicate embedded data (steganography).")
    }
    static var hiddenDataSuspected: String { t("veri gizlenmiş olabilir", "data may be hidden here") }

    static func sections(_ count: Int) -> String {
        t("\(count) bölüm", count == 1 ? "1 section" : "\(count) sections")
    }
}
