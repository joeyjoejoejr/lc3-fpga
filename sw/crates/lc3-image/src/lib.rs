use std::collections::HashMap;
use std::fmt::Write;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MemoryImage {
    origin: u16,
    words: Vec<u16>,
    symbols: HashMap<String, u32>,
}

impl MemoryImage {
    #[must_use]
    pub fn new(origin: u16, words: Vec<u16>, symbols: HashMap<String, u32>) -> Self {
        Self {
            origin,
            words,
            symbols,
        }
    }

    #[must_use]
    pub const fn origin(&self) -> u16 {
        self.origin
    }

    #[must_use]
    pub fn words(&self) -> &[u16] {
        &self.words
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.words.is_empty()
    }

    #[must_use]
    pub fn symbol_string(&self) -> String {
        let mut sym = String::new();
        let mut symbols = self.symbols.iter().collect::<Vec<_>>();
        symbols.sort_by_key(|(name, _)| *name);
        writeln!(sym, "// Symbol table").unwrap();
        writeln!(sym, "// Scope level 0:").unwrap();
        writeln!(sym, "//\tSymbol Name       Page Address").unwrap();
        writeln!(sym, "//\t----------------  ------------").unwrap();

        for (name, address) in symbols {
            writeln!(sym, "//\t{name:<16}  {address:04X}").unwrap();
        }

        writeln!(sym, "//\t$               {:04X}", self.origin).unwrap();
        sym
    }
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::MemoryImage;

    #[test]
    fn stores_origin_and_words() {
        let image = MemoryImage::new(0x3000, vec![0x1021, 0xF025], HashMap::new());

        assert_eq!(image.origin(), 0x3000);
        assert_eq!(image.words(), &[0x1021, 0xF025]);
        assert!(!image.is_empty());
    }
}
