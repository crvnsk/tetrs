from flask import render_template, request, flash, redirect, url_for
from services.build_service import BuildService
from utils.web_utils import browse_directory, get_parent_path

build_service = BuildService()

def init_build_routes(app):
    @app.route('/browse/<server>')
    def browse_builds(server):
        """Файловый браузер для навигации по билд-серверу"""
        try:
            ansible_vars = build_service.load_ansible_vars()

            if server == "cf_server":
                base_uri = ansible_vars['product']['cf_server']['linux']['base_uri']
                server_name = "CF Server"
            elif server == "gw_server":
                base_uri = ansible_vars['product']['gw_server']['linux']['base_uri']
                server_name = "GW Server"
            else:
                flash('Неверный сервер', 'error')
                return redirect(url_for('index'))

            current_path = request.args.get('path', '')
            items, current_url, error = browse_directory(base_uri, current_path)
            parent_path = get_parent_path(current_path)

            return render_template('browse.html',
                                 server=server,
                                 server_name=server_name,
                                 items=items,
                                 current_path=current_path,
                                 current_url=current_url,
                                 parent_path=parent_path,
                                 base_uri=base_uri,
                                 error=error)

        except Exception as e:
            flash(f'Ошибка: {str(e)}', 'error')
            return redirect(url_for('index'))

    @app.route('/select_build/<server>', methods=['GET', 'POST'])
    def select_build(server):
        """Быстрый выбор билда"""
        try:
            ansible_vars = build_service.load_ansible_vars()

            if server == "cf_server":
                base_uri = ansible_vars['product']['cf_server']['linux']['base_uri']
                current_version = ansible_vars['product']['cf_server']['linux'].get('version_cf_server', 'Не установлена')
                server_name = "CF Server"
            elif server == "gw_server":
                base_uri = ansible_vars['product']['gw_server']['linux']['base_uri']
                current_version = ansible_vars['product']['gw_server']['linux'].get('version_gw_server', 'Не установлена')
                server_name = "GW Server"
            else:
                flash('Неверный сервер', 'error')
                return redirect(url_for('index'))

            if request.method == 'POST':
                selected_build = request.form['build']
                build_service.update_build_selection(server, selected_build)
                flash(f'Выбран билд {selected_build} для {server_name}', 'success')
                return redirect(url_for('index'))

            items, current_url, error = browse_directory(base_uri)
            builds = [item['path'] for item in items if item['type'] == 'directory']

            return render_template('select_build.html',
                                 builds=builds,
                                 server=server,
                                 server_name=server_name,
                                 current_version=current_version)

        except Exception as e:
            flash(f'Ошибка: {str(e)}', 'error')
            return redirect(url_for('index'))

    @app.route('/select_local_build/<server>', methods=['GET', 'POST'])
    def select_local_build(server):
        """Выбор локального билда"""
        try:
            if server == "cf_server":
                server_name = "CF Server"
            elif server == "gw_server":
                server_name = "GW Server"
            else:
                flash('Неверный сервер', 'error')
                return redirect(url_for('index'))

            local_builds = build_service.get_local_builds()
            builds = local_builds.get(server, [])

            return render_template('select_local_build.html',
                                 builds=builds,
                                 server=server,
                                 server_name=server_name)

        except Exception as e:
            flash(f'Ошибка: {str(e)}', 'error')
            return redirect(url_for('index'))

    @app.route('/select_from_browse', methods=['POST'])
    def select_from_browse():
        """Выбор билда из файлового браузера"""
        try:
            selected_path = request.form['selected_path']
            server = request.form['server']
            build_service.update_build_selection(server, selected_path)
            flash(f'Выбран путь {selected_path} для {server}', 'success')
            return redirect(url_for('index'))
        except Exception as e:
            flash(f'Ошибка выбора: {str(e)}', 'error')
            return redirect(url_for('index'))
