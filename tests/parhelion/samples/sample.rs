//! sample crate
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Item<'a> { name: &'a str, count: u32 }

pub enum Kind { Small, Large(u8) }

pub trait Named { fn name(&self) -> String; }

impl<'a> Named for Item<'a> {
    fn name(&self) -> String { format!("{}:{}", self.name, self.count) }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut seen: HashMap<String, u32> = HashMap::new();
    let kind = Kind::Large(0xff);
    match kind {
        Kind::Small => println!("small"),
        Kind::Large(n) if n > 1 => { seen.insert("large".to_string(), n as u32); }
        _ => unreachable!(),
    }
    Ok(())
}
