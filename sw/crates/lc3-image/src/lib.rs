use std::collections::HashMap;
use std::fmt::Write;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DenseMemoryImage {
    bytes: Box<[u8; 65_536 * 2]>,
    occupied: Box<[bool; 65_536]>,
}

impl DenseMemoryImage {
    /// Create an empty, zero-filled dense memory image.
    ///
    /// # Panics
    ///
    /// Panics only if the internal dense memory constants do not match their
    /// fixed-size buffer types.
    #[must_use]
    pub fn new() -> Self {
        Self {
            bytes: vec![0u8; 65_536 * 2]
                .into_boxed_slice()
                .try_into()
                .expect("dense memory byte buffer should have fixed size"),
            occupied: vec![false; 65_536]
                .into_boxed_slice()
                .try_into()
                .expect("dense memory occupancy buffer should have fixed size"),
        }
    }

    #[must_use]
    pub fn be_bytes(&self) -> &[u8] {
        self.bytes.as_slice()
    }

    /// Compose one or more origin-addressed memory images into one dense image.
    ///
    /// # Errors
    ///
    /// Returns an error if any image extends past the LC-3 address space or if
    /// two images write to the same address.
    pub fn from_memory_images(images: &[MemoryImage]) -> Result<Self, String> {
        let mut dense_image = Self::new();

        for image in images {
            if usize::from(image.origin) + image.words().len() > 65_536 {
                return Err("memory image exceeds lc3 address space".to_owned());
            }

            for (i, word) in image.words.iter().enumerate() {
                let addr = usize::from(image.origin) + i;
                let offset = addr * 2;
                if dense_image.occupied[addr] {
                    return Err("memory images overlap".to_owned());
                }

                let [hi, lo] = word.to_be_bytes();

                dense_image.bytes[offset] = hi;
                dense_image.bytes[offset + 1] = lo;
                dense_image.occupied[addr] = true;
            }
        }

        Ok(dense_image)
    }
}

impl Default for DenseMemoryImage {
    fn default() -> Self {
        Self::new()
    }
}

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

impl TryFrom<Vec<u8>> for MemoryImage {
    type Error = String;

    fn try_from(bytes: Vec<u8>) -> Result<Self, Self::Error> {
        let [addr_hi, addr_lo, rest @ ..] = bytes.as_slice() else {
            return Err("invalid object file, expected 16 bit origin".to_owned());
        };
        let origin = u16::from_be_bytes([*addr_hi, *addr_lo]);
        let words = rest.chunks_exact(2);

        if !words.remainder().is_empty() {
            return Err("invalid object file, expected 16 bit words".to_owned());
        }

        let words = words
            .map(|chunk| u16::from_be_bytes([chunk[0], chunk[1]]))
            .collect();

        Ok(MemoryImage::new(origin, words, HashMap::new()))
    }
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::{DenseMemoryImage, MemoryImage};

    fn assert_be_word(bytes: &[u8], address: usize, word: u16) {
        assert_eq!(
            &bytes[(address * 2)..(address * 2 + 2)],
            &word.to_be_bytes()
        );
    }

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

        let dense = DenseMemoryImage::from_memory_images(&[image])
            .expect("image should fit in LC-3 memory");
        let bytes = dense.be_bytes();

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

        let dense =
            DenseMemoryImage::from_memory_images(&[image]).expect("last LC-3 address should fit");
        let bytes = dense.be_bytes();

        assert_eq!(&bytes[(0xFFFF * 2)..], &[0xAB, 0xCD]);
    }

    #[test]
    fn reports_dense_memory_image_overflow() {
        let image = MemoryImage::new(0xFFFF, vec![0xABCD, 0x1234], HashMap::new());

        assert!(DenseMemoryImage::from_memory_images(&[image]).is_err());
    }

    #[test]
    fn writes_dense_big_endian_memory_image_from_multiple_images() {
        let os = MemoryImage::new(0x0200, vec![0x1021, 0xF025], HashMap::new());
        let program = MemoryImage::new(0x3000, vec![0x5020, 0x1261], HashMap::new());

        let dense = DenseMemoryImage::from_memory_images(&[os, program])
            .expect("non-overlapping images should fit");
        let bytes = dense.be_bytes();

        assert_eq!(bytes.len(), 65_536 * 2);
        assert_be_word(bytes, 0x0200, 0x1021);
        assert_be_word(bytes, 0x0201, 0xF025);
        assert_be_word(bytes, 0x3000, 0x5020);
        assert_be_word(bytes, 0x3001, 0x1261);
        assert_be_word(bytes, 0x01FF, 0x0000);
        assert_be_word(bytes, 0x0202, 0x0000);
        assert_be_word(bytes, 0x2FFF, 0x0000);
        assert_be_word(bytes, 0x3002, 0x0000);
    }

    #[test]
    fn writes_adjacent_images_to_dense_memory_image() {
        let first = MemoryImage::new(0x3000, vec![0x1021, 0xF025], HashMap::new());
        let second = MemoryImage::new(0x3002, vec![0xD000], HashMap::new());

        let dense = DenseMemoryImage::from_memory_images(&[first, second])
            .expect("adjacent images should not overlap");
        let bytes = dense.be_bytes();

        assert_be_word(bytes, 0x3000, 0x1021);
        assert_be_word(bytes, 0x3001, 0xF025);
        assert_be_word(bytes, 0x3002, 0xD000);
    }

    #[test]
    fn reports_overlapping_images_in_dense_memory_image() {
        let first = MemoryImage::new(0x3000, vec![0x1021, 0xF025], HashMap::new());
        let second = MemoryImage::new(0x3001, vec![0xD000], HashMap::new());

        assert!(DenseMemoryImage::from_memory_images(&[first, second]).is_err());
    }

    #[test]
    fn reports_images_with_same_origin_as_overlapping() {
        let first = MemoryImage::new(0x3000, vec![0x1021], HashMap::new());
        let second = MemoryImage::new(0x3000, vec![0xF025], HashMap::new());

        assert!(DenseMemoryImage::from_memory_images(&[first, second]).is_err());
    }

    #[test]
    fn reports_overflowing_image_in_dense_memory_image_collection() {
        let first = MemoryImage::new(0x0200, vec![0x1021], HashMap::new());
        let overflowing = MemoryImage::new(0xFFFF, vec![0xABCD, 0x1234], HashMap::new());

        assert!(DenseMemoryImage::from_memory_images(&[first, overflowing]).is_err());
    }
}
