from pathlib import Path
import zipfile
from lxml import etree
import tempfile
from datetime import datetime
import json
import shutil


def main(odt_file: Path):
    temp_path = Path(tempfile.mkdtemp())
    try:
        # Extract the ODT file contents
        with zipfile.ZipFile(odt_file, "r") as odt_zip:
            odt_zip.extractall(temp_path)

        # Load content.xml
        content_xml_path = temp_path / "content.xml"
        if not content_xml_path.exists():
            raise FileNotFoundError("content.xml not found in the ODT file.")

        with open(content_xml_path, "rb") as f:
            content_tree = etree.parse(f)

        namespaces = {
            "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
            "office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
        }

        # Extract paragraphs and comments
        paragraphs_data = extract_paragraphs_with_comments(content_tree, namespaces)

        paragraphs_data = {
            k: v for k, v in paragraphs_data.items() if len(v["comments"]) > 0
        }

        # Write results to JSON file
        output_file = Path(odt_file).with_suffix(".comments.json")
        with open(output_file, "w", encoding="utf-8") as json_file:
            json.dump(paragraphs_data, json_file, indent=4, ensure_ascii=False)

        print(f"Comments and paragraphs saved to {output_file}")

    finally:
        # Clean up temporary directory
        shutil.rmtree(temp_path)


def extract_paragraphs_with_comments(content_tree, namespaces):
    """Extract paragraphs and their associated comments."""
    paragraphs_data = {}

    for i, paragraph in enumerate(
        content_tree.xpath("//text:p", namespaces=namespaces)
    ):
        paragraph_text = "".join(
            paragraph.xpath(".//text()", namespaces=namespaces)
        ).strip()
        comments = []

        for annotation in paragraph.xpath(
            ".//office:annotation", namespaces=namespaces
        ):
            annotation_text = "".join(
                annotation.xpath(".//text:p//text()", namespaces=namespaces)
            ).strip()
            author = annotation.find(".//{http://purl.org/dc/elements/1.1/}creator")
            date = annotation.find(".//{http://purl.org/dc/elements/1.1/}date")
            author = author.text if author is not None else "Unknown"
            date = date.text if date is not None else datetime.now().isoformat()
            # Approximate position
            pos_start = paragraph_text.find(annotation_text[:10])
            pos_end = pos_start + len(annotation_text) if pos_start != -1 else -1

            if annotation_text in paragraph_text:
                paragraph_text = paragraph_text.replace(annotation_text, "")

            comments.append(
                {
                    "pos_start": pos_start,
                    "pos_end": pos_end,
                    "text": annotation_text,
                    "author": author,
                    "date": date,
                }
            )

        # Keep only significant paragraphs?
        if len(paragraph_text) > 0:
            paragraphs_data[i] = {
                "text": paragraph_text,
                "comments": comments,
            }

    return paragraphs_data
