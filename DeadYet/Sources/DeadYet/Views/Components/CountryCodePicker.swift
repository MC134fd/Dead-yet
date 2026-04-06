import SwiftUI

struct Country: Identifiable, Sendable {
    let id: String
    let name: String
    let dialCode: String
    let flag: String
}

let countries: [Country] = [
    Country(id: "US", name: "United States", dialCode: "+1", flag: "\u{1F1FA}\u{1F1F8}"),
    Country(id: "GB", name: "United Kingdom", dialCode: "+44", flag: "\u{1F1EC}\u{1F1E7}"),
    Country(id: "AU", name: "Australia", dialCode: "+61", flag: "\u{1F1E6}\u{1F1FA}"),
    Country(id: "CA", name: "Canada", dialCode: "+1", flag: "\u{1F1E8}\u{1F1E6}"),
    Country(id: "IN", name: "India", dialCode: "+91", flag: "\u{1F1EE}\u{1F1F3}"),
    Country(id: "PH", name: "Philippines", dialCode: "+63", flag: "\u{1F1F5}\u{1F1ED}"),
    Country(id: "NZ", name: "New Zealand", dialCode: "+64", flag: "\u{1F1F3}\u{1F1FF}"),
    Country(id: "SG", name: "Singapore", dialCode: "+65", flag: "\u{1F1F8}\u{1F1EC}"),
    Country(id: "MY", name: "Malaysia", dialCode: "+60", flag: "\u{1F1F2}\u{1F1FE}"),
    Country(id: "JP", name: "Japan", dialCode: "+81", flag: "\u{1F1EF}\u{1F1F5}"),
    Country(id: "KR", name: "South Korea", dialCode: "+82", flag: "\u{1F1F0}\u{1F1F7}"),
    Country(id: "CN", name: "China", dialCode: "+86", flag: "\u{1F1E8}\u{1F1F3}"),
    Country(id: "DE", name: "Germany", dialCode: "+49", flag: "\u{1F1E9}\u{1F1EA}"),
    Country(id: "FR", name: "France", dialCode: "+33", flag: "\u{1F1EB}\u{1F1F7}"),
    Country(id: "IT", name: "Italy", dialCode: "+39", flag: "\u{1F1EE}\u{1F1F9}"),
    Country(id: "ES", name: "Spain", dialCode: "+34", flag: "\u{1F1EA}\u{1F1F8}"),
    Country(id: "BR", name: "Brazil", dialCode: "+55", flag: "\u{1F1E7}\u{1F1F7}"),
    Country(id: "MX", name: "Mexico", dialCode: "+52", flag: "\u{1F1F2}\u{1F1FD}"),
    Country(id: "ZA", name: "South Africa", dialCode: "+27", flag: "\u{1F1FF}\u{1F1E6}"),
    Country(id: "NG", name: "Nigeria", dialCode: "+234", flag: "\u{1F1F3}\u{1F1EC}"),
    Country(id: "AE", name: "UAE", dialCode: "+971", flag: "\u{1F1E6}\u{1F1EA}"),
    Country(id: "SA", name: "Saudi Arabia", dialCode: "+966", flag: "\u{1F1F8}\u{1F1E6}"),
    Country(id: "TH", name: "Thailand", dialCode: "+66", flag: "\u{1F1F9}\u{1F1ED}"),
    Country(id: "VN", name: "Vietnam", dialCode: "+84", flag: "\u{1F1FB}\u{1F1F3}"),
    Country(id: "ID", name: "Indonesia", dialCode: "+62", flag: "\u{1F1EE}\u{1F1E9}"),
    Country(id: "PK", name: "Pakistan", dialCode: "+92", flag: "\u{1F1F5}\u{1F1F0}"),
    Country(id: "BD", name: "Bangladesh", dialCode: "+880", flag: "\u{1F1E7}\u{1F1E9}"),
    Country(id: "IE", name: "Ireland", dialCode: "+353", flag: "\u{1F1EE}\u{1F1EA}"),
    Country(id: "SE", name: "Sweden", dialCode: "+46", flag: "\u{1F1F8}\u{1F1EA}"),
    Country(id: "NL", name: "Netherlands", dialCode: "+31", flag: "\u{1F1F3}\u{1F1F1}"),
]

struct PhoneInputField: View {
    @Binding var fullPhone: String
    @State private var selectedCountry: Country
    @State private var nationalNumber: String = ""
    @State private var showCountryPicker = false

    init(fullPhone: Binding<String>) {
        self._fullPhone = fullPhone
        let (country, number) = Self.parseE164(fullPhone.wrappedValue)
        self._selectedCountry = State(initialValue: country)
        self._nationalNumber = State(initialValue: number)
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { showCountryPicker = true }) {
                HStack(spacing: 4) {
                    Text(selectedCountry.flag)
                        .font(.system(size: 20))
                    Text(selectedCountry.dialCode)
                        .font(DeadYetFonts.body(size: 16))
                        .foregroundStyle(DeadYetColors.primaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DeadYetColors.primaryText.opacity(0.2), lineWidth: 1)
                )
            }

            TextField("Phone number", text: $nationalNumber)
                .textFieldStyle(.plain)
                .font(DeadYetFonts.body(size: 16))
                .foregroundStyle(DeadYetColors.primaryText)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DeadYetColors.primaryText.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: nationalNumber) { _, _ in
                    updateFullPhone()
                }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                onSelect: {
                    showCountryPicker = false
                    updateFullPhone()
                }
            )
        }
    }

    private func updateFullPhone() {
        let digits = nationalNumber.filter(\.isNumber)
        if digits.isEmpty {
            fullPhone = ""
        } else {
            fullPhone = selectedCountry.dialCode + digits
        }
    }

    private static func parseE164(_ phone: String) -> (Country, String) {
        let defaultCountry = detectDefaultCountry()
        guard phone.hasPrefix("+") else {
            return (defaultCountry, phone.filter(\.isNumber))
        }
        // Try to match longest dial code first
        let sorted = countries.sorted { $0.dialCode.count > $1.dialCode.count }
        for country in sorted {
            if phone.hasPrefix(country.dialCode) {
                let remaining = String(phone.dropFirst(country.dialCode.count))
                return (country, remaining)
            }
        }
        return (defaultCountry, phone.filter(\.isNumber))
    }

    private static func detectDefaultCountry() -> Country {
        if let regionCode = Locale.current.region?.identifier,
           let match = countries.first(where: { $0.id == regionCode }) {
            return match
        }
        return countries[0] // US fallback
    }
}

struct CountryPickerSheet: View {
    @Binding var selectedCountry: Country
    let onSelect: () -> Void
    @State private var searchText = ""

    private var filtered: [Country] {
        if searchText.isEmpty { return countries }
        let query = searchText.lowercased()
        return countries.filter {
            $0.name.lowercased().contains(query)
                || $0.dialCode.contains(query)
                || $0.id.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                List(filtered) { country in
                    Button(action: {
                        selectedCountry = country
                        onSelect()
                    }) {
                        HStack {
                            Text(country.flag)
                                .font(.system(size: 24))
                            Text(country.name)
                                .font(DeadYetFonts.body(size: 16))
                                .foregroundStyle(DeadYetColors.primaryText)
                            Spacer()
                            Text(country.dialCode)
                                .font(DeadYetFonts.body(size: 14))
                                .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                            if country.id == selectedCountry.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DeadYetColors.accent)
                            }
                        }
                    }
                    .listRowBackground(DeadYetColors.background)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search countries")
            }
            .navigationTitle("Country Code")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSelect() }
                        .foregroundStyle(DeadYetColors.primaryText)
                }
            }
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }
}
