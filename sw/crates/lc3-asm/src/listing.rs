#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct ProgramListing {
    pub rows: Vec<ListingRow>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ListingRow {
    pub line: usize,
    pub address: Option<u16>,
    pub word_count: usize,
}
