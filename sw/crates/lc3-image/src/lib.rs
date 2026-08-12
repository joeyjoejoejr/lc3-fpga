#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MemoryImage {
    origin: u16,
    words: Vec<u16>,
}

impl MemoryImage {
    #[must_use]
    pub fn new(origin: u16, words: Vec<u16>) -> Self {
        Self { origin, words }
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
}

#[cfg(test)]
mod tests {
    use super::MemoryImage;

    #[test]
    fn stores_origin_and_words() {
        let image = MemoryImage::new(0x3000, vec![0x1021, 0xF025]);

        assert_eq!(image.origin(), 0x3000);
        assert_eq!(image.words(), &[0x1021, 0xF025]);
        assert!(!image.is_empty());
    }
}
