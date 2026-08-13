use logos::Logos;

use crate::SourceLocation;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SpannedToken {
    pub token: Token,
    pub location: SourceLocation,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct LexError {
    pub location: SourceLocation,
    pub message: String,
}

#[derive(Clone, Debug, Eq, Logos, PartialEq)]
#[logos(skip r"[ \t\r\f]+")]
pub enum Token {
    #[regex(r";[^\n]*", logos::skip, allow_greedy = true)]
    Comment,

    #[token(",")]
    Comma,

    #[token("\n")]
    Newline,

    #[regex(r"[Rr][0-7]", parse_register)]
    Register(u8),

    #[regex(r"#[+-]?[0-9]+", parse_decimal)]
    #[regex(r"[xX][0-9A-Fa-f]+", parse_hex)]
    Number(i32),

    #[regex(r#""([^"\\]|\\.)*""#, parse_string_literal)]
    StringLiteral(String),

    #[regex(r"\.[A-Za-z][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*", parse_ident)]
    Ident(String),
}

/// Convert LC-3 assembly source text into a stream of located tokens.
///
/// # Errors
///
/// Returns a lexical error when the source contains text that does not match
/// any known token pattern.
pub fn tokenize(source: &str) -> Result<Vec<SpannedToken>, LexError> {
    let mut lexer = Token::lexer(source);
    let mut tokens = Vec::new();

    while let Some(token) = lexer.next() {
        let location = source_location(source, lexer.span().start);
        let token = token.map_err(|()| LexError {
            location,
            message: format!("unexpected token `{}`", lexer.slice()),
        })?;

        tokens.push(SpannedToken { token, location });
    }

    Ok(tokens)
}

fn parse_ident(lexer: &mut logos::Lexer<'_, Token>) -> String {
    lexer.slice().to_string()
}

fn parse_register(lexer: &mut logos::Lexer<'_, Token>) -> Option<u8> {
    lexer.slice()[1..].parse().ok()
}

fn parse_decimal(lexer: &mut logos::Lexer<'_, Token>) -> Option<i32> {
    lexer.slice()[1..].parse().ok()
}

fn parse_hex(lexer: &mut logos::Lexer<'_, Token>) -> Option<i32> {
    i32::from_str_radix(&lexer.slice()[1..], 16).ok()
}

fn parse_string_literal(lexer: &mut logos::Lexer<'_, Token>) -> String {
    lexer.slice().to_string()
}

fn source_location(source: &str, byte_index: usize) -> SourceLocation {
    let mut line = 1;
    let mut column = 1;

    for ch in source[..byte_index].chars() {
        if ch == '\n' {
            line += 1;
            column = 1;
        } else {
            column += 1;
        }
    }

    SourceLocation { line, column }
}

#[cfg(test)]
mod tests {
    use super::{Token, tokenize};

    #[test]
    fn tokenizes_labeled_add_line_and_skips_comment() {
        let tokens = tokenize("START ADD R1, R2, #3 ; comment\n").unwrap();
        let token_kinds = tokens
            .into_iter()
            .map(|spanned| spanned.token)
            .collect::<Vec<_>>();

        assert_eq!(
            token_kinds,
            vec![
                Token::Ident("START".to_string()),
                Token::Ident("ADD".to_string()),
                Token::Register(1),
                Token::Comma,
                Token::Register(2),
                Token::Comma,
                Token::Number(3),
                Token::Newline,
            ]
        );
    }

    #[test]
    fn tokenizes_multiline_assembly_sample() {
        let source = r".ORIG x3000
START ADD R1, R2, R3 ; comment
     TRAP x25
.END
";

        let tokens = tokenize(source).unwrap();
        let token_kinds = tokens
            .into_iter()
            .map(|spanned| spanned.token)
            .collect::<Vec<_>>();

        assert_eq!(
            token_kinds,
            vec![
                Token::Ident(".ORIG".to_string()),
                Token::Number(0x3000),
                Token::Newline,
                Token::Ident("START".to_string()),
                Token::Ident("ADD".to_string()),
                Token::Register(1),
                Token::Comma,
                Token::Register(2),
                Token::Comma,
                Token::Register(3),
                Token::Newline,
                Token::Ident("TRAP".to_string()),
                Token::Number(0x25),
                Token::Newline,
                Token::Ident(".END".to_string()),
                Token::Newline,
            ]
        );
    }
}
