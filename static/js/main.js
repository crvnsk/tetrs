// Функция для заполнения списка ВМ из данных сервера
async function populateVmList() {
    const vmList = document.getElementById('vm-list');
    if (!vmList) {
        console.error('Элемент vm-list не найден');
        return;
    }

    console.log('Загрузка списка ВМ...');
    vmList.innerHTML = '<div class="loading">Загрузка списка ВМ...</div>';

    try {
        // Пробуем получить данные из window (переданные из шаблона)
        let virtualMachines = window.virtualMachines;

        // Если данных нет в window, загружаем через API
        if (!virtualMachines || virtualMachines.length === 0) {
            console.log('Данные не найдены в window, загружаем через API...');
            const response = await fetch('/api/virtual_machines');
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            virtualMachines = await response.json();
        }

        console.log('Получены ВМ:', virtualMachines);
        vmList.innerHTML = '';

        if (!virtualMachines || virtualMachines.length === 0) {
            vmList.innerHTML = '<div class="no-vms">ВМ не найдены в inventory файле</div>';
            return;
        }

        virtualMachines.forEach(vm => {
            const vmItem = document.createElement('div');
            vmItem.className = 'vm-item';
            vmItem.innerHTML = `
                <input type="checkbox" name="selected_vms" value="${vm.ip}" id="vm-${vm.ip.replace(/\./g, '-')}">
                <div class="vm-info">
                    <div class="vm-name">${vm.os}</div>
                    <div class="vm-ip">${vm.ip}</div>
                </div>
            `;
            vmList.appendChild(vmItem);
        });

        console.log('Список ВМ успешно заполнен');

    } catch (error) {
        console.error('Ошибка загрузки списка ВМ:', error);
        vmList.innerHTML = '<div class="error">Ошибка загрузки списка ВМ</div>';
    }
}

// Переключение режима выбора ВМ
function toggleVmSelection() {
    const vmListContainer = document.getElementById('vm-list-container');
    if (!vmListContainer) return;

    const selectionType = document.querySelector('input[name="vm_selection"]:checked').value;

    if (selectionType === 'selected') {
        vmListContainer.classList.remove('hidden');
    } else {
        vmListContainer.classList.add('hidden');
    }
}

// Выбрать/снять все ВМ
function toggleSelectAllVms() {
    const selectAll = document.getElementById('select-all-vms');
    const vmCheckboxes = document.querySelectorAll('input[name="selected_vms"]');

    vmCheckboxes.forEach(checkbox => {
        checkbox.checked = selectAll.checked;
    });
}

// Переключение пользовательского инвентаря
function initInventorySelect() {
    const inventorySelect = document.getElementById('inventory-select');
    if (inventorySelect) {
        inventorySelect.addEventListener('change', function() {
            const customInventory = document.getElementById('custom-inventory');
            if (this.value === 'custom') {
                customInventory.classList.remove('hidden');
            } else {
                customInventory.classList.add('hidden');
            }
        });
    }
}

// Сворачиваемые секции
function toggleCollapsible(id) {
    const content = document.getElementById(id);
    content.classList.toggle('hidden');
}

// Подготовка формы перед отправкой
function prepareForm(form) {
    const selectionType = document.querySelector('input[name="vm_selection"]:checked').value;
    const inventorySelect = document.getElementById('inventory-select');
    let inventoryFile;

    // Определяем инвентарный файл
    if (inventorySelect.value === 'custom') {
        inventoryFile = document.getElementById('custom-inventory-path').value;
        if (!inventoryFile) {
            alert('Укажите путь к пользовательскому инвентарному файлу');
            return false;
        }
    } else {
        inventoryFile = inventorySelect.value;
    }

    // Определяем целевые ВМ
    let targetVms;
    if (selectionType === 'all') {
        targetVms = 'all';
    } else {
        const selectedVms = Array.from(document.querySelectorAll('input[name="selected_vms"]:checked'))
            .map(checkbox => checkbox.value);
        if (selectedVms.length === 0) {
            alert('Выберите хотя бы одну виртуальную машину');
            return false;
        }
        targetVms = selectedVms.join(',');
    }

    // Заполняем скрытые поля
    const targetInput = form.querySelector('input[name="target_vms"]');
    const inventoryInput = form.querySelector('input[name="inventory_file"]');
    targetInput.value = targetVms;
    inventoryInput.value = inventoryFile;

    return true;
}

// Мониторинг в реальном времени
let eventSource = null;
let monitoringActive = window.monitoringActive || false;

// Функция для проверки статуса выполнения
function checkJobStatus() {
    fetch('/job_status')
        .then(response => response.json())
        .then(data => {
            if (data.active && data.status === 'running') {
                // Показываем уведомление если его нет
                if (!document.querySelector('.execution-warning')) {
                    showExecutionWarning();
                }
                monitoringActive = true;
            } else {
                // Скрываем уведомление если задание завершено
                if (document.querySelector('.execution-warning')) {
                    hideExecutionWarning();
                }
                monitoringActive = false;
            }
        })
        .catch(error => {
            console.error('Ошибка проверки статуса:', error);
        });
}

// Показ уведомления
function showExecutionWarning() {
    const warning = document.createElement('div');
    warning.className = 'execution-warning';
    warning.innerHTML = `
        <div class="warning-content">
            <div class="warning-icon">⚠️</div>
            <div class="warning-text">
                <strong>ВНИМАНИЕ!</strong> Идет выполнение плейбуков. Подождите завершения...
            </div>
        </div>
    `;
    document.body.insertBefore(warning, document.body.firstChild);

    // Добавляем отступ для контента
    const container = document.querySelector('.container');
    if (container) {
        container.style.marginTop = '60px';
    }
}

// Скрытие уведомления
function hideExecutionWarning() {
    const warning = document.querySelector('.execution-warning');
    if (warning) {
        warning.remove();
        // Убираем отступ
        const container = document.querySelector('.container');
        if (container) {
            container.style.marginTop = '';
        }
    }
}

// Восстановление состояния при загрузке страницы
function restoreJobState() {
    fetch('/job_status')
        .then(response => response.json())
        .then(data => {
            if (data.active !== false && data.status === 'running') {
                monitoringActive = true;
                startMonitoring();
                showExecutionWarning();

                if (data.output && data.output.length > 0) {
                    const output = document.getElementById('monitoring-output');
                    output.innerHTML = '';
                    data.output.forEach(item => {
                        addOutputLine(item.line, item.type);
                    });
                }

                updateStatus('Выполняется...', 'status-running');
                addOutputLine('Восстановлено активное задание', 'info');
            } else {
                monitoringActive = false;
                hideExecutionWarning();
            }
        })
        .catch(error => {
            console.error('Ошибка восстановления состояния:', error);
        });
}

function startMonitoring() {
    if (eventSource) {
        eventSource.close();
    }

    const monitoringPanel = document.getElementById('monitoring-panel');
    const monitoringOutput = document.getElementById('monitoring-output');

    if (monitoringPanel) monitoringPanel.classList.remove('hidden');
    showExecutionWarning();

    eventSource = new EventSource('/events');

    eventSource.onmessage = function(event) {
        const data = JSON.parse(event.data);

        switch(data.type) {
            case 'start':
                addOutputLine(`Запуск плейбука: ${data.data.playbook}`, 'info');
                addOutputLine(`Команда: ${data.data.command}`, 'info');
                updateStatus('Выполняется...', 'status-running');
                break;

            case 'output':
                addOutputLine(data.data.line, 'info');
                break;

            case 'success':
                addOutputLine(`${data.data.message}`, 'success');
                updateStatus('Завершено успешно', 'status-success');
                eventSource.close();
                monitoringActive = false;
                setTimeout(hideExecutionWarning, 2000);
                break;

            case 'error':
                addOutputLine(`${data.data.message}`, 'error');
                if (data.data.output) {
                    addOutputLine(data.data.output, 'error');
                }
                updateStatus('Ошибка выполнения', 'status-error');
                eventSource.close();
                monitoringActive = false;
                setTimeout(hideExecutionWarning, 2000);
                break;

            case 'keepalive':
                break;
        }

        if (monitoringOutput) {
            monitoringOutput.scrollTop = monitoringOutput.scrollHeight;
        }
    };

    eventSource.onerror = function(event) {
        addOutputLine('Ошибка подключения к мониторингу', 'error');
        if (eventSource) eventSource.close();
        monitoringActive = false;
        hideExecutionWarning();
    };
}

function addOutputLine(text, type = 'info') {
    const output = document.getElementById('monitoring-output');
    if (!output) return;

    const line = document.createElement('div');
    line.className = `output-line ${type}`;
    line.textContent = `[${new Date().toLocaleTimeString()}] ${text}`;
    output.appendChild(line);
}

function updateStatus(text, className) {
    const status = document.getElementById('monitoring-status');
    if (!status) return;

    status.textContent = text;
    status.className = `monitoring-status ${className}`;
}

function stopMonitoring() {
    if (eventSource) {
        eventSource.close();
    }

    fetch('/stop_job', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            addOutputLine('Задание остановлено пользователем', 'warning');
            updateStatus('Остановлено', 'status-error');
            setTimeout(hideExecutionWarning, 2000);
        } else {
            addOutputLine(`${data.message}`, 'error');
        }
    })
    .catch(error => {
        addOutputLine('Ошибка остановки задания', 'error');
    });

    monitoringActive = false;
}

function clearMonitoring() {
    const output = document.getElementById('monitoring-output');
    if (output) output.innerHTML = '';
}

// Инициализация при загрузке
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM загружен, инициализация...');
    populateVmList();
    toggleVmSelection();
    initInventorySelect();
    restoreJobState();

    // Обработка изменения чекбоксов ВМ
    document.addEventListener('change', function(e) {
        if (e.target.name === 'selected_vms') {
            const vmCheckboxes = document.querySelectorAll('input[name="selected_vms"]');
            const selectAll = document.getElementById('select-all-vms');
            const checkedCount = Array.from(vmCheckboxes).filter(cb => cb.checked).length;

            if (checkedCount === 0) {
                selectAll.checked = false;
                selectAll.indeterminate = false;
            } else if (checkedCount === vmCheckboxes.length) {
                selectAll.checked = true;
                selectAll.indeterminate = false;
            } else {
                selectAll.checked = false;
                selectAll.indeterminate = true;
            }
        }
    });

    // Проверяем статус при загрузке
    setTimeout(checkJobStatus, 1000);
});

// Предупреждение при перезагрузке страницы во время выполнения
window.addEventListener('beforeunload', function(e) {
    if (monitoringActive) {
        e.preventDefault();
        e.returnValue = 'Идет выполнение задания. Вы уверены, что хотите покинуть страницу?';
        return 'Идет выполнение задания. Вы уверены, что хотите покинуть страницу?';
    }
});

// Периодическая проверка состояния
setInterval(() => {
    if (monitoringActive) {
        checkJobStatus();
    }
}, 5000);