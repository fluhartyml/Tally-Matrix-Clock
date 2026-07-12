//
//  MusicStationCatalog.swift
//  CryoKit
//
//  Created by Michael Fluharty on 3/31/26.
//

import Foundation

public enum StationCategory: String, CaseIterable, Sendable {
    case music = "Music"
    case appleRadio = "Apple Radio"
    case billboard = "Popular Hits"
    case nature = "Sound Machine"
    case focus = "Focus"
}

public enum BillboardDecade: String, CaseIterable, Sendable {
    case d1950s = "1950s"
    case d1960s = "1960s"
    case d1970s = "1970s"
    case d1980s = "1980s"
    case d1990s = "1990s"
    case d2000s = "2000s"
    case d2010s = "2010s"
    case d2020s = "2020s"

    public static func decades(for category: StationCategory) -> [BillboardDecade] {
        category == .billboard ? allCases : []
    }
}

public enum StationSearchType: Sendable {
    case stationFirst
    case stationOnly
    case stationByID
    case playlistFirst
    case albumFirst
}

/// Describes how the station content is sourced — used by apps to group reveals.
public enum StationSourceType: String, CaseIterable, Sendable {
    case appleRadio = "Apple Radio"         // Direct Apple Radio station with ra. ID
    case curatedSearch = "Apple Music"       // Search-based (finds curated playlists/stations)
    case billboard = "Popular Hits"          // Billboard/chart playlists
    case soundscape = "Soundscapes"          // Nature sounds, ASMR, ambient
    case focus = "Focus & Meditation"        // Focus, binaural, meditation
    case library = "My Library"             // User's own library content
    case off = "Off"
}

public enum SleepTimerOption: Int, CaseIterable, Sendable {
    case off = 0
    case thirtyMin = 30
    case sixtyMin = 60
    case twoHours = 120
    case fourHours = 240

    public var displayName: String {
        switch self {
        case .off: return "Off"
        case .thirtyMin: return "30m"
        case .sixtyMin: return "1h"
        case .twoHours: return "2h"
        case .fourHours: return "4h"
        }
    }
}

public enum MusicStationOption: String, CaseIterable, Sendable {
    // Music stations
    case none = "Off"
    case ambient = "Ambient"
    case chillout = "Chill"
    case jazz = "Jazz"
    case country = "Country"
    case electronic = "Electronic"
    case newInPop = "New in Pop"
    case rockStation = "Rock Station"
    case rAndBNow = "R&B Now"
    case spatialAudio = "Hits in Spatial Audio"
    case bigBand = "Big Band & Swing"
    case earlyJazz = "Early Jazz & Swing"
    case jazzAge = "Jazz Age"
    case ragtime = "Ragtime & Classics"

    // Popular Hits
    case top100USA = "Top 100: USA"
    case billboard1958 = "1958"
    case billboard1959 = "1959"
    case billboard1960 = "1960"
    case billboard1961 = "1961"
    case billboard1962 = "1962"
    case billboard1963 = "1963"
    case billboard1964 = "1964"
    case billboard1965 = "1965"
    case billboard1966 = "1966"
    case billboard1967 = "1967"
    case billboard1968 = "1968"
    case billboard1969 = "1969"
    case billboard1970 = "1970"
    case billboard1971 = "1971"
    case billboard1972 = "1972"
    case billboard1973 = "1973"
    case billboard1974 = "1974"
    case billboard1975 = "1975"
    case billboard1976 = "1976"
    case billboard1977 = "1977"
    case billboard1978 = "1978"
    case billboard1979 = "1979"
    case billboard1980 = "1980"
    case billboard1981 = "1981"
    case billboard1982 = "1982"
    case billboard1983 = "1983"
    case billboard1984 = "1984"
    case billboard1985 = "1985"
    case billboard1986 = "1986"
    case billboard1987 = "1987"
    case billboard1988 = "1988"
    case billboard1989 = "1989"
    case billboard1990 = "1990"
    case billboard1991 = "1991"
    case billboard1992 = "1992"
    case billboard1993 = "1993"
    case billboard1994 = "1994"
    case billboard1995 = "1995"
    case billboard1996 = "1996"
    case billboard1997 = "1997"
    case billboard1998 = "1998"
    case billboard1999 = "1999"
    case billboard2000 = "2000"
    case billboard2001 = "2001"
    case billboard2002 = "2002"
    case billboard2003 = "2003"
    case billboard2004 = "2004"
    case billboard2005 = "2005"
    case billboard2006 = "2006"
    case billboard2007 = "2007"
    case billboard2008 = "2008"
    case billboard2009 = "2009"
    case billboard2010 = "2010"
    case billboard2011 = "2011"
    case billboard2012 = "2012"
    case billboard2013 = "2013"
    case billboard2014 = "2014"
    case billboard2015 = "2015"
    case billboard2016 = "2016"
    case billboard2017 = "2017"
    case billboard2018 = "2018"
    case billboard2019 = "2019"
    case billboard2020 = "2020"
    case billboard2021 = "2021"
    case billboard2022 = "2022"
    case billboard2023 = "2023"
    case billboard2024 = "2024"
    case billboard2025 = "2025"

    // Nature sounds
    case infiniteRain = "Infinite Rain"
    case forestSounds = "Forest Sounds"
    case babblingBrook = "Babbling Brook"
    case tropicalThunderstorm = "Tropical Thunderstorm"
    case oceanWavesThunder = "Ocean Waves & Thunder"
    case waterfallAndRain = "Waterfall and Rain"
    case tibetanMonksOm = "Tibetan Monks Chanting Om"
    case tibetanSingingBowls = "Tibetan Singing Bowls"
    case tibetanBowls4Hr = "Singing Bowls 4 Hours"
    case rainSoundsForSleep = "Rain Sounds for Sleep"

    // ASMR (nested under Sound Machine)
    case oscillatingFan = "Oscillating Fan"
    case vacuumCleaner = "Vacuum Cleaner"
    case washingMachine = "Washing Machine"
    case hairDryer = "Hair Dryer"

    // Apple Radio
    case pinkFloydRadio = "Pink Floyd Radio"
    case personalStation = "My Personal Station"
    case discoveryStation = "Discovery Station"
    case tonyBennettRadio = "Tony Bennett Radio"
    case daftPunkRadio = "Daft Punk Radio"
    case enyaRadio = "Enya Radio"
    case novaJazzersRadio = "Nova Jazzers Radio"
    case enigmaRadio = "Enigma Radio"
    case bossaLoungeRadio = "Bossa Lounge Radio"
    case relaxRadio = "Relax"
    case focusRadio = "Focus Radio"
    case energyRadio = "Energy"
    case feelGoodRadio = "Feel Good"
    case appleMusic1 = "Apple Music 1"
    case appleMusicHits = "Apple Music Hits"
    case appleMusicCountry = "Apple Music Country"
    case appleMusicChill = "Apple Music Chill"
    case classicRockStation = "Classic Rock Station"
    case smoothJazzStation = "Smooth Jazz Station"
    case sleepStation = "Sleep"
    case popStation = "Pop Station"
    case eightiesHits = "80s Hits Station"
    case classicalStation = "Classical Station"
    case spaStation = "Spa Station"
    case pianoStation = "Piano Station"
    case danceStation = "Dance Station"
    case adultRockStation = "Adult Rock Station"
    case lofiStation = "Lo-Fi Station"
    case countryHitsStation = "Country Hits Station"
    case jazzStation = "Jazz Station"
    case indieStation = "Indie Station"
    case acousticStation = "Acoustic Station"

    // Focus
    case pureFocus = "Pure Focus"
    case focusFrequency = "Focus Frequency"
    case calmBreathing = "432 Hz Calm Breathing"
    case positiveShift = "432 Hz Positive Shift"
    case lightWork = "432 Hz Light Work"

    /// How this station's content is sourced — used by apps to group reveals.
    public var sourceType: StationSourceType {
        switch self {
        case .none:
            return .off
        case .pinkFloydRadio, .personalStation, .discoveryStation, .tonyBennettRadio,
             .daftPunkRadio, .enyaRadio, .novaJazzersRadio, .enigmaRadio,
             .bossaLoungeRadio, .relaxRadio, .focusRadio, .energyRadio, .feelGoodRadio,
             .appleMusic1, .appleMusicHits, .appleMusicCountry, .appleMusicChill,
             .classicRockStation, .smoothJazzStation, .sleepStation, .popStation,
             .eightiesHits, .classicalStation, .spaStation, .pianoStation,
             .danceStation, .adultRockStation, .lofiStation, .countryHitsStation,
             .jazzStation, .indieStation, .acousticStation:
            return .appleRadio
        case .top100USA,
             .billboard1958, .billboard1959,
             .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969,
             .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979,
             .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989,
             .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999,
             .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009,
             .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019,
             .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025:
            return .billboard
        case .infiniteRain, .forestSounds, .babblingBrook, .tropicalThunderstorm,
             .oceanWavesThunder, .waterfallAndRain, .tibetanMonksOm,
             .tibetanSingingBowls, .tibetanBowls4Hr, .rainSoundsForSleep,
             .oscillatingFan, .vacuumCleaner, .washingMachine, .hairDryer:
            return .soundscape
        case .pureFocus, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .focus
        default:
            return .curatedSearch
        }
    }

    /// Apple Music station ID for direct playback (ra. URLs).
    public var stationID: String? {
        switch self {
        case .pinkFloydRadio: return "ra.487143"
        case .personalStation: return nil // Fetched dynamically via MusicKit personal station API
        case .discoveryStation: return "ra.q-GAI6IDNhNGY4OGQxNzE2YTU1MmUxYWJiNzBmZjc1N2FhOTVm"
        case .tonyBennettRadio: return "ra.484980"
        case .daftPunkRadio: return "ra.5468295"
        case .enyaRadio: return "ra.160847"
        case .novaJazzersRadio: return "ra.882817746"
        case .enigmaRadio: return "ra.3218461"
        case .bossaLoungeRadio: return "ra.882820073"
        case .relaxRadio: return "ra.q-MK3VCQ"
        case .focusRadio: return "ra.q-MMLEBw"
        case .energyRadio: return "ra.q-MI4G"
        case .feelGoodRadio: return "ra.q-MLzEBw"
        // https://music.apple.com/us/station/apple-music-1/ra.978194965
        case .appleMusic1: return "ra.978194965"
        // https://music.apple.com/us/station/apple-music-hits/ra.1498155548
        case .appleMusicHits: return "ra.1498155548"
        // https://music.apple.com/us/station/apple-music-country/ra.1498157166
        case .appleMusicCountry: return "ra.1498157166"
        // https://music.apple.com/us/station/apple-music-chill/ra.1740614260
        case .appleMusicChill: return "ra.1740614260"
        // https://music.apple.com/us/station/classic-rock-station/ra.985500514
        case .classicRockStation: return "ra.985500514"
        // https://music.apple.com/us/station/smooth-jazz-station/ra.985496511
        case .smoothJazzStation: return "ra.985496511"
        // https://music.apple.com/us/station/sleep/ra.1569444987
        case .sleepStation: return "ra.1569444987"
        // https://music.apple.com/us/station/pop-station/ra.686227433
        case .popStation: return "ra.686227433"
        // https://music.apple.com/us/station/80s-hits-station/ra.1055200360
        case .eightiesHits: return "ra.1055200360"
        // https://music.apple.com/us/station/classical-station/ra.985486574
        case .classicalStation: return "ra.985486574"
        // https://music.apple.com/us/station/spa-station/ra.1060251598
        case .spaStation: return "ra.1060251598"
        // https://music.apple.com/us/station/piano-station/ra.1087953681
        case .pianoStation: return "ra.1087953681"
        // https://music.apple.com/us/station/dance-station/ra.985487895
        case .danceStation: return "ra.985487895"
        // https://music.apple.com/us/station/adult-rock-station/ra.1129219098
        case .adultRockStation: return "ra.1129219098"
        // https://music.apple.com/us/station/lo-fi-station/ra.1569482000
        case .lofiStation: return "ra.1569482000"
        // https://music.apple.com/us/station/country-hits-station/ra.985486589
        case .countryHitsStation: return "ra.985486589"
        // https://music.apple.com/us/station/jazz-station/ra.985496180
        case .jazzStation: return "ra.985496180"
        // https://music.apple.com/us/station/indie-station/ra.985496064
        case .indieStation: return "ra.985496064"
        // https://music.apple.com/us/station/acoustic-station/ra.985501172
        case .acousticStation: return "ra.985501172"
        default: return nil
        }
    }

    public var category: StationCategory {
        switch self {
        case .none, .ambient, .chillout, .jazz, .country, .electronic,
             .newInPop, .rockStation, .rAndBNow, .spatialAudio,
             .bigBand, .earlyJazz, .jazzAge, .ragtime:
            return .music
        case .pinkFloydRadio, .personalStation, .discoveryStation, .tonyBennettRadio,
             .daftPunkRadio, .enyaRadio, .novaJazzersRadio, .enigmaRadio,
             .bossaLoungeRadio, .relaxRadio, .focusRadio, .energyRadio, .feelGoodRadio,
             .appleMusic1, .appleMusicHits, .appleMusicCountry, .appleMusicChill,
             .classicRockStation, .smoothJazzStation, .sleepStation, .popStation,
             .eightiesHits, .classicalStation, .spaStation, .pianoStation,
             .danceStation, .adultRockStation, .lofiStation, .countryHitsStation,
             .jazzStation, .indieStation, .acousticStation:
            return .appleRadio
        case .top100USA,
             .billboard1958, .billboard1959,
             .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969,
             .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979,
             .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989,
             .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999,
             .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009,
             .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019,
             .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025:
            return .billboard
        case .infiniteRain, .forestSounds, .babblingBrook, .tropicalThunderstorm,
             .oceanWavesThunder, .waterfallAndRain, .tibetanMonksOm,
             .tibetanSingingBowls, .tibetanBowls4Hr, .rainSoundsForSleep,
             .oscillatingFan, .vacuumCleaner, .washingMachine, .hairDryer:
            return .nature
        case .pureFocus, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .focus
        }
    }

    public var searchTerm: String {
        switch self {
        case .none: return ""
        case .ambient: return "ambient relaxation"
        case .chillout: return "chill vibes"
        case .jazz: return "jazz chill"
        case .country: return "country hits"
        case .electronic: return "pure electronic"
        case .newInPop: return "new in pop"
        case .rockStation: return "rock station"
        case .rAndBNow: return "R&B now"
        case .spatialAudio: return "hits in spatial audio"
        case .bigBand: return "big band swing"
        case .earlyJazz: return "early jazz swing"
        case .jazzAge: return "roaring twenties jazz"
        case .ragtime: return "ragtime classics"
        case .top100USA: return "top 100 usa"
        case .billboard1958: return "pop hits 1958"
        case .billboard1959: return "pop hits 1959"
        case .billboard1960: return "pop hits 1960"
        case .billboard1961: return "pop hits 1961"
        case .billboard1962: return "pop hits 1962"
        case .billboard1963: return "pop hits 1963"
        case .billboard1964: return "pop hits 1964"
        case .billboard1965: return "pop hits 1965"
        case .billboard1966: return "pop hits 1966"
        case .billboard1967: return "pop hits 1967"
        case .billboard1968: return "pop hits 1968"
        case .billboard1969: return "pop hits 1969"
        case .billboard1970: return "pop hits 1970"
        case .billboard1971: return "pop hits 1971"
        case .billboard1972: return "pop hits 1972"
        case .billboard1973: return "pop hits 1973"
        case .billboard1974: return "pop hits 1974"
        case .billboard1975: return "pop hits 1975"
        case .billboard1976: return "pop hits 1976"
        case .billboard1977: return "pop hits 1977"
        case .billboard1978: return "pop hits 1978"
        case .billboard1979: return "pop hits 1979"
        case .billboard1980: return "pop hits 1980"
        case .billboard1981: return "pop hits 1981"
        case .billboard1982: return "pop hits 1982"
        case .billboard1983: return "pop hits 1983"
        case .billboard1984: return "pop hits 1984"
        case .billboard1985: return "pop hits 1985"
        case .billboard1986: return "pop hits 1986"
        case .billboard1987: return "pop hits 1987"
        case .billboard1988: return "pop hits 1988"
        case .billboard1989: return "pop hits 1989"
        case .billboard1990: return "pop hits 1990"
        case .billboard1991: return "pop hits 1991"
        case .billboard1992: return "pop hits 1992"
        case .billboard1993: return "pop hits 1993"
        case .billboard1994: return "pop hits 1994"
        case .billboard1995: return "pop hits 1995"
        case .billboard1996: return "pop hits 1996"
        case .billboard1997: return "pop hits 1997"
        case .billboard1998: return "pop hits 1998"
        case .billboard1999: return "pop hits 1999"
        case .billboard2000: return "pop hits 2000"
        case .billboard2001: return "pop hits 2001"
        case .billboard2002: return "pop hits 2002"
        case .billboard2003: return "pop hits 2003"
        case .billboard2004: return "pop hits 2004"
        case .billboard2005: return "pop hits 2005"
        case .billboard2006: return "pop hits 2006"
        case .billboard2007: return "pop hits 2007"
        case .billboard2008: return "pop hits 2008"
        case .billboard2009: return "pop hits 2009"
        case .billboard2010: return "pop hits 2010"
        case .billboard2011: return "pop hits 2011"
        case .billboard2012: return "pop hits 2012"
        case .billboard2013: return "pop hits 2013"
        case .billboard2014: return "pop hits 2014"
        case .billboard2015: return "pop hits 2015"
        case .billboard2016: return "pop hits 2016"
        case .billboard2017: return "pop hits 2017"
        case .billboard2018: return "pop hits 2018"
        case .billboard2019: return "pop hits 2019"
        case .billboard2020: return "pop hits 2020"
        case .billboard2021: return "pop hits 2021"
        case .billboard2022: return "pop hits 2022"
        case .billboard2023: return "pop hits 2023"
        case .billboard2024: return "pop hits 2024"
        case .billboard2025: return "pop hits 2025"
        case .infiniteRain: return "infinite rain"
        case .forestSounds: return "forest sounds apple music wellbeing"
        case .babblingBrook: return "babbling brook nature sounds nature sound collection"
        case .tropicalThunderstorm: return "thunderstorms"
        case .oceanWavesThunder: return "ocean waves gentle thunder and rain"
        case .waterfallAndRain: return "healing sounds of nature waterfall and rain"
        case .tibetanMonksOm: return "tibetan monks chanting om for deep meditation"
        case .tibetanSingingBowls: return "tibetan singing bowls satiro"
        case .tibetanBowls4Hr: return "tibetan singing bowls 4 hours for relaxation"
        case .rainSoundsForSleep: return "rain sounds for sleep"
        case .oscillatingFan: return "oscillating fan white noise"
        case .vacuumCleaner: return "vacuum cleaner white noise sleep"
        case .washingMachine: return "washing machine sound"
        case .hairDryer: return "hair dryer white noise sleep"
        case .pinkFloydRadio: return "Pink Floyd"
        case .personalStation: return "My Personal Station"
        case .discoveryStation: return "Discovery Station"
        case .tonyBennettRadio: return "Tony Bennett"
        case .daftPunkRadio: return "Daft Punk"
        case .enyaRadio: return "Enya"
        case .novaJazzersRadio: return "Nova Jazzers"
        case .enigmaRadio: return "Enigma"
        case .bossaLoungeRadio: return "Bossa Lounge Project"
        case .relaxRadio: return "Relax"
        case .focusRadio: return "Focus"
        case .energyRadio: return "Energy"
        case .feelGoodRadio: return "Feel Good"
        case .appleMusic1: return "Apple Music 1"
        case .appleMusicHits: return "Apple Music Hits"
        case .appleMusicCountry: return "Apple Music Country"
        case .appleMusicChill: return "Apple Music Chill"
        case .classicRockStation: return "Classic Rock Station"
        case .smoothJazzStation: return "Smooth Jazz Station"
        case .sleepStation: return "Sleep"
        case .popStation: return "Pop Station"
        case .eightiesHits: return "80s Hits Station"
        case .classicalStation: return "Classical Station"
        case .spaStation: return "Spa Station"
        case .pianoStation: return "Piano Station"
        case .danceStation: return "Dance Station"
        case .adultRockStation: return "Adult Rock Station"
        case .lofiStation: return "Lo-Fi Station"
        case .countryHitsStation: return "Country Hits Station"
        case .jazzStation: return "Jazz Station"
        case .indieStation: return "Indie Station"
        case .acousticStation: return "Acoustic Station"
        case .pureFocus: return "pure focus"
        case .focusFrequency: return "focus frequency increase concentration memory"
        case .calmBreathing: return "deep meditation binaural beats vol 9 lightseeds"
        case .positiveShift: return "deep meditation binaural beats vol 9 lightseeds"
        case .lightWork: return "deep meditation binaural beats vol 9 lightseeds"
        }
    }

    public var searchType: StationSearchType {
        switch self {
        case .pinkFloydRadio, .personalStation, .discoveryStation, .tonyBennettRadio,
             .daftPunkRadio, .enyaRadio, .novaJazzersRadio, .enigmaRadio,
             .bossaLoungeRadio, .relaxRadio, .focusRadio, .energyRadio, .feelGoodRadio,
             .appleMusic1, .appleMusicHits, .appleMusicCountry, .appleMusicChill,
             .classicRockStation, .smoothJazzStation, .sleepStation, .popStation,
             .eightiesHits, .classicalStation, .spaStation, .pianoStation,
             .danceStation, .adultRockStation, .lofiStation, .countryHitsStation,
             .jazzStation, .indieStation, .acousticStation:
            return .stationByID
        case .rockStation:
            return .stationOnly
        case .infiniteRain, .forestSounds, .newInPop, .rAndBNow, .spatialAudio,
             .pureFocus, .rainSoundsForSleep,
             .top100USA,
             .billboard1958, .billboard1959,
             .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969,
             .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979,
             .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989,
             .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999,
             .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009,
             .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019,
             .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025:
            return .playlistFirst
        case .babblingBrook, .tropicalThunderstorm, .oceanWavesThunder,
             .waterfallAndRain, .tibetanMonksOm, .tibetanSingingBowls,
             .tibetanBowls4Hr, .oscillatingFan, .vacuumCleaner, .washingMachine, .hairDryer,
             .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .albumFirst
        default:
            return .stationFirst
        }
    }

    public var decade: BillboardDecade? {
        switch self {
        case .billboard1958, .billboard1959: return .d1950s
        case .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969: return .d1960s
        case .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979: return .d1970s
        case .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989: return .d1980s
        case .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999: return .d1990s
        case .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009: return .d2000s
        case .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019: return .d2010s
        case .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025: return .d2020s
        default: return nil
        }
    }

    public var isASMR: Bool {
        switch self {
        case .oscillatingFan, .vacuumCleaner, .washingMachine, .hairDryer:
            return true
        default:
            return false
        }
    }

    public var shouldRepeat: Bool {
        category == .nature || category == .focus
    }

    public static func stations(for category: StationCategory) -> [MusicStationOption] {
        allCases.filter { $0.category == category && $0 != .none && !$0.isASMR }
    }

    public static var asmrStations: [MusicStationOption] {
        allCases.filter { $0.isASMR }
    }

    public static func stations(for decade: BillboardDecade) -> [MusicStationOption] {
        allCases.filter { $0.decade == decade }
    }

    /// Stations grouped by source type — ready for reveal UI sections.
    public static var groupedBySource: [(source: StationSourceType, stations: [MusicStationOption])] {
        let all = allCases.filter { $0 != .none }
        let grouped = Dictionary(grouping: all) { $0.sourceType }
        // Order: Apple Radio, Apple Music, Billboard, Soundscapes, Focus
        let order: [StationSourceType] = [.appleRadio, .curatedSearch, .billboard, .soundscape, .focus]
        return order.compactMap { source in
            guard let stations = grouped[source], !stations.isEmpty else { return nil }
            return (source: source, stations: stations)
        }
    }
}
