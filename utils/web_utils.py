import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

def browse_directory(base_uri, path=''):
    """Функция для навигации по директориям"""
    try:
        if path:
            current_url = urljoin(base_uri + '/', path)
        else:
            current_url = base_uri

        response = requests.get(current_url, timeout=10)
        response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        items = []

        for link in soup.find_all('a'):
            href = link.get('href')
            text = link.text.strip()

            if href and href not in ('../', './'):
                full_url = urljoin(current_url, href)

                if href.endswith('/'):
                    item_type = 'directory'
                    display_name = text
                else:
                    item_type = 'file'
                    display_name = text

                if item_type == 'directory':
                    relative_path = full_url.replace(base_uri, '').rstrip('/')
                else:
                    relative_path = href

                items.append({
                    'name': text,
                    'type': item_type,
                    'display_name': display_name,
                    'path': relative_path,
                    'full_url': full_url
                })

        return items, current_url, None

    except requests.RequestException as e:
        return [], current_url, str(e)

def get_parent_path(current_path):
    """Получает путь к родительской директории"""
    if not current_path:
        return ''

    parts = current_path.rstrip('/').split('/')
    if len(parts) > 1:
        return '/'.join(parts[:-1])
    else:
        return ''