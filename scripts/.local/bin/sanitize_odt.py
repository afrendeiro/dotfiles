"""
Cleanup time from document comments.

Usage:
uv run python -m fire clean_odt_dates.py main file.odt --date '1900-01-01T00:00:00'
"""

from pathlib import Path
import zipfile
from lxml import etree
import tempfile

def main(odt_file_path: Path, date: str = '1900-01-01T00:00:00', author: str = None) -> None:
    """
    Sanitize comments in an ODT file by updating their date to a specified value.

    This script modifies the dates of all comments in an ODT file. Optionally, it
    can filter comments by a specific author before applying the date change. The
    sanitized file is saved with the suffix `.sanitized.odt` appended to the original filename.

    Args:
        odt_file_path (Path): The path to the ODT file to process.
        date (str): The new date to set for the comments, in ISO 8601 format. Default is '1900-01-01T00:00:00'.
        author (str, optional): The author whose comments should be updated. If None, all comments are updated.

    Usage:
        Run the script using the following command:

        python -m afire /path/to/odt/file.odt --date 2000-01-01T00:00:00 --author "Author Name"

        Replace `/path/to/odt/file.odt` with the path to your ODT file. The `--date` and `--author`
        arguments are optional. If not specified, the default date and all authors will be considered.
    """
    # Step 1: Extract the ODT file into a temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        with zipfile.ZipFile(odt_file_path, 'r') as odt_zip:
            odt_zip.extractall(temp_path)

        # Step 2: Modify content.xml
        content_xml_path = temp_path / "content.xml"
        if not content_xml_path.exists():
            raise FileNotFoundError("content.xml not found in the ODT file.")

        # Parse the content.xml file
        tree = etree.parse(content_xml_path)
        root = tree.getroot()
        namespace = {"office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
                     "dc": "http://purl.org/dc/elements/1.1/"}

        # Find all comments and modify their dates
        annotations = root.findall(".//office:annotation", namespaces=namespace)
        if not annotations:
            raise ValueError("No comments found in the ODT file.")

        for annotation in annotations:
            # Check the author if specified
            author_element = annotation.find(".//dc:creator", namespaces=namespace)
            if author and (author_element is None or author_element.text != author):
                continue

            # Modify the date
            date_element = annotation.find(".//dc:date", namespaces=namespace)
            if date_element is not None:
                date_element.text = date
            else:
                # If no date exists, add a new one
                new_date_element = etree.Element("{http://purl.org/dc/elements/1.1/}date")
                new_date_element.text = date
                annotation.append(new_date_element)

        # Write the changes back to content.xml
        tree.write(content_xml_path, xml_declaration=True, encoding="UTF-8")

        # Step 3: Repackage the ODT file
        sanitized_odt_path = odt_file_path.with_suffix(".sanitized.odt")
        with zipfile.ZipFile(sanitized_odt_path, 'w', zipfile.ZIP_DEFLATED) as new_odt_zip:
            for file_path in temp_path.rglob("*"):
                arcname = file_path.relative_to(temp_path)
                new_odt_zip.write(file_path, arcname)

        print(f"Sanitized ODT file saved as {sanitized_odt_path}")
