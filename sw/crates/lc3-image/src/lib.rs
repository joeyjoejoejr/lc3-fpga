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

    /// Convert this image to a zero-filled, 64K-word, big-endian memory dump.
    ///
    /// # Errors
    ///
    /// Returns an error if the image extends past the LC-3 address space.
    pub fn to_dense_be_bytes(&self) -> Result<Vec<u8>, String> {
        let mut bytes = vec![0u8; 65_536 * 2];
        let mut offset = usize::from(self.origin) * 2;

        if usize::from(self.origin) + self.words().len() > 65_536 {
            return Err("memory image exceeds lc3 address space".to_owned());
        }

        for word in &self.words {
            let [hi, lo] = word.to_be_bytes();

            bytes[offset] = hi;
            bytes[offset + 1] = lo;
            offset += 2;
        }

        Ok(bytes)
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

    #[test]
    fn writes_dense_big_endian_memory_image() {
        let image = MemoryImage::new(0x3000, vec![0x1021, 0xF025], HashMap::new());

        let bytes = image
            .to_dense_be_bytes()
            .expect("image should fit in LC-3 memory");

        assert_eq!(bytes.len(), 65_536 * 2);
        assert_eq!(&bytes[0..4], &[0x00, 0x00, 0x00, 0x00]);
        assert_eq!(
            &bytes[(0x3000 * 2)..(0x3000 * 2 + 4)],
            &[0x10, 0x21, 0xF0, 0x25]
        );
        assert_eq!(
            &bytes[(0x3002 * 2)..(0x3002 * 2 + 4)],
            &[0x00, 0x00, 0x00, 0x00]
        );
    }

    #[test]
    fn writes_last_address_in_dense_memory_image() {
        let image = MemoryImage::new(0xFFFF, vec![0xABCD], HashMap::new());

        let bytes = image
            .to_dense_be_bytes()
            .expect("last LC-3 address should fit");

        assert_eq!(&bytes[(0xFFFF * 2)..], &[0xAB, 0xCD]);
    }

    #[test]
    fn reports_dense_memory_image_overflow() {
        let image = MemoryImage::new(0xFFFF, vec![0xABCD, 0x1234], HashMap::new());

        assert!(image.to_dense_be_bytes().is_err());
    }
}
