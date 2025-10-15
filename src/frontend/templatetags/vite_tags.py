import json
import logging

from pathlib import Path

from django import template
from django.conf import settings
from django.templatetags.static import static
from django.utils.safestring import mark_safe

register = template.Library()

logger = logging.getLogger(__name__)


@register.simple_tag
def vite_asset(entry) -> str:
    """
    Load Vite assets from manifest.json
    Usage: {% vite_asset 'src/index.jsx' %}
    """
    manifest_path = (
        Path(settings.BASE_DIR).parent / "frontend/dist/.vite/manifest.json"
    )

    if not manifest_path.exists():
        logger.debug(f"Manifest not found at path {manifest_path}")
        return ""

    try:
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
    except json.JSONDecodeError:
        logger.debug("Invalid manifest.json")
        return ""

    if entry not in manifest:
        logger.debug(f"Entry '{entry}' not found in manifest")
        return ""

    entry_data = manifest[entry]
    tags = []

    # Add css files
    if 'css' in entry_data:
        for css_file in entry_data['css']:
            css_url = static(css_file)
            tags.append(f'<link rel="stylesheet" href="{css_url}">')

    # Add main js file
    js_file = entry_data['file']
    js_url = static(js_file)
    tags.append(f'<script type="module" src="{js_url}"></script>')

    return mark_safe('\n '.join(tags))
