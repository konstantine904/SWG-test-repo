use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::Path;

use swg_tre::TreArchive;

const TARGET: &str = "object/tangible/wearables/robe/shared_robe_jedi_padawan.iff";

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let tre_dir = Path::new("/tre");
    let output = Path::new("/tmp/shared_robe_jedi_padawan.iff");

    for entry in fs::read_dir(tre_dir)? {
        let path = entry?.path();
        if path.extension().and_then(|value| value.to_str()) != Some("tre") {
            continue;
        }

        let file = File::open(&path)?;
        let mut archive = match TreArchive::new(file) {
            Ok(archive) => archive,
            Err(_) => continue,
        };

        if archive.index_for_name(TARGET).is_some() {
            let mut source = archive.by_name(TARGET)?;
            let mut data = Vec::new();
            source.read_to_end(&mut data)?;
            File::create(output)?.write_all(&data)?;
            println!("Extracted {TARGET} from {} ({} bytes)", path.display(), data.len());
            return Ok(());
        }
    }

    Err(format!("{TARGET} was not found in /tre").into())
}
