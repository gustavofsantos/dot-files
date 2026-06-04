#!/usr/bin/env python3
import os
import re
from pathlib import Path
import yaml 

SRC_ROOT = Path.home() / ".dot-files" / ".claude"

def translate_gemini_metadata(metadata):
    if not isinstance(metadata, dict):
        return None
    clean_meta = {}
    for key, value in metadata.items():
        if key not in ["allowed-tools"]:
            clean_meta[key] = value
    return clean_meta if clean_meta else None

TARGETS = {
    "gemini": {
        "base_dir": Path.home() / ".gemini",
        "format": "yaml_frontmatter",
        "filename_skill": "SKILL.md", 
        "filename_agent": "{name}.md", 
        "supported_fields": ["name", "description", "license", "metadata", "system_prompt"],
        "translators": {
            "metadata": translate_gemini_metadata
        }
    },
    "cursor": {
        "base_dir": Path.home() / ".cursor",
        "format": "flat_markdown",
        "filename_skill": "{name}.mdc", 
        "filename_agent": "{name}.mdc", 
        "supported_fields": [], 
        "translators": {}
    }
}

def parse_markdown(filepath):
    content = filepath.read_text(encoding="utf-8")
    match = re.match(r'^---\n(.*?)\n---\n(.*)', content, re.DOTALL)
    if match:
        fm_text, body = match.groups()
        return yaml.safe_load(fm_text) or {}, body.strip()
    return {}, content.strip()

def process_entity(entity_type, entity_path):
    # Handle both directory-based structures (skills) and flat files (agents)
    if entity_path.is_file():
        name = entity_path.stem
        src_file = entity_path
    else:
        name = entity_path.name
        src_file = entity_path / "SKILL.md" if (entity_path / "SKILL.md").exists() else entity_path / f"{name}.md"
        if not src_file.exists():
            return

    front_matter, body = parse_markdown(src_file)

    for target_name, config in TARGETS.items():
        translated_fm = {}
        for key, value in front_matter.items():
            if key in config["supported_fields"]:
                translator = config["translators"].get(key)
                processed_value = translator(value) if translator else value
                if processed_value is not None:
                    translated_fm[key] = processed_value

        target_dir = config["base_dir"] / entity_type
        
        # entity_type[:-1] chops the 's' off 'skills'/'agents' to match keys
        filename_key = f"filename_{entity_type[:-1]}" 
        filename = config.get(filename_key, "{name}.md").format(name=name)
        
        if config["format"] == "yaml_frontmatter":
            if filename == "SKILL.md":
                out_dir = target_dir / name
                out_dir.mkdir(parents=True, exist_ok=True)
                out_file = out_dir / filename
            else:
                target_dir.mkdir(parents=True, exist_ok=True)
                out_file = target_dir / filename
                
            fm_yaml = yaml.dump(translated_fm, sort_keys=False, width=80)
            out_file.write_text(f"---\n{fm_yaml}---\n\n{body}")
            
        elif config["format"] == "flat_markdown":
            target_dir.mkdir(parents=True, exist_ok=True)
            out_file = target_dir / filename
            out_file.write_text(body)

def main():
    for entity_type in ["skills", "agents"]:
        src_dir = SRC_ROOT / entity_type
        if src_dir.exists():
            for entity_path in src_dir.iterdir():
                # Process both directories and .md files
                if entity_path.is_dir() or entity_path.suffix == '.md':
                    process_entity(entity_type, entity_path)
    print("Pipeline complete: All skills and agents translated and dispatched.")

if __name__ == "__main__":
    main()
