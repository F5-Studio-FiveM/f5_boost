(function () {
    'use strict';

    var app = document.getElementById('app');
    var fpsEl = document.getElementById('fps-value');
    var screenHints = document.getElementById('screen-hints');
    var toggleKeyEl = document.getElementById('toggle-key');

    var profileListEl = document.getElementById('profile-list');
    var profileEmptyEl = document.getElementById('profile-empty');
    var profileCounterEl = document.getElementById('profile-counter');
    var profileNameInput = document.getElementById('profile-name-input');
    var profileSaveBtn = document.getElementById('profile-save-btn');
    var profileSaveSection = document.getElementById('profile-save-section');
    var maxProfiles = 5;
    var profileCodeInput = document.getElementById('profile-code-input');
    var notifyContainer = document.getElementById('notify-container');
    var currentSettings = {};

    var L = {};

    function t(key) { return L[key] || key; }

    function applyLocales() {
        document.querySelectorAll('[data-locale]').forEach(function (el) {
            el.textContent = t(el.getAttribute('data-locale'));
        });
        document.querySelectorAll('[data-locale-html]').forEach(function (el) {
            el.innerHTML = t(el.getAttribute('data-locale-html'));
        });
        document.querySelectorAll('[data-locale-tip]').forEach(function (el) {
            el.setAttribute('data-tip', t(el.getAttribute('data-locale-tip')));
        });
        document.querySelectorAll('[data-locale-placeholder]').forEach(function (el) {
            el.placeholder = t(el.getAttribute('data-locale-placeholder'));
        });
    }

    fetch('https://f5_boost/requestLocales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}'
    }).then(function (r) { return r.json(); }).then(function (data) {
        L = data || {};
        applyLocales();
    }).catch(function () {});

    function closeUI() {
        app.classList.add('hidden');
        screenHints.classList.remove('visible');
        tooltipEl.classList.remove('visible');
    }

    function escapeHtml(text) {
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function notify(message, type) {
        type = type || 'success';
        var icon = type === 'error' ? 'error' : type === 'info' ? 'info' : 'check_circle';
        var el = document.createElement('div');
        el.className = 'notify ' + type;
        el.innerHTML = '<span class="material-symbols-rounded">' + icon + '</span>' + escapeHtml(message);
        notifyContainer.appendChild(el);
        setTimeout(function () {
            el.classList.add('out');
            setTimeout(function () { el.remove(); }, 250);
        }, 2500);
    }

    var tooltipEl = document.getElementById('tooltip');

    document.addEventListener('mouseover', function (e) {
        var target = e.target.closest('[data-tip]');
        if (!target) { tooltipEl.classList.remove('visible'); return; }

        tooltipEl.textContent = target.getAttribute('data-tip');
        tooltipEl.style.left = '0px';
        tooltipEl.style.top = '0px';
        tooltipEl.classList.add('visible');

        var rect = target.getBoundingClientRect();
        var tw = tooltipEl.offsetWidth;
        var th = tooltipEl.offsetHeight;

        var x = rect.left + rect.width / 2 - tw / 2;
        var y = rect.top - th - 6;

        if (y < 4) y = rect.bottom + 6;
        x = Math.max(4, Math.min(x, window.innerWidth - tw - 4));

        tooltipEl.style.left = x + 'px';
        tooltipEl.style.top = y + 'px';
    });

    window.addEventListener('message', function (e) {
        var d = e.data;
        if (d.action === 'openMenu') {
            app.classList.remove('hidden');
            screenHints.classList.add('visible');
            if (d.openKey) toggleKeyEl.textContent = d.openKey;
            if (d.maxProfiles) maxProfiles = d.maxProfiles;
            if (d.settings) sync(d.settings);
        } else if (d.action === 'closeMenu') {
            closeUI();
        } else if (d.action === 'updateSettings') {
            if (d.settings) sync(d.settings);
        } else if (d.action === 'updateProfiles') {
            renderProfiles(d.profiles);
        } else if (d.action === 'notify') {
            notify(d.message, d.type);
        } else if (d.action === 'updateFPS') {
            fpsEl.textContent = d.fps;
            fpsEl.className = d.fps >= 60 ? 'good' : d.fps >= 30 ? 'mid' : 'bad';
        }
    });

    function sync(s) {
        currentSettings = s;
        document.querySelectorAll('.chip').forEach(function (b) {
            b.classList.toggle('active', b.dataset.preset === s.graphicsPreset);
        });
        document.querySelectorAll('.seg').forEach(function (b) {
            b.classList.toggle('active', b.dataset.mode === s.performanceMode);
        });
        ['shadowDistance', 'objectQuality', 'characterQuality', 'vehicleDistance'].forEach(function (k) {
            var sl = document.getElementById('slider-' + k);
            var vl = document.getElementById('val-' + k);
            if (sl && s[k] !== undefined) {
                sl.value = s[k];
                if (vl) vl.textContent = s[k];
                fill(sl);
            }
        });
        ['toggleClearEvents', 'toggleLightReflections', 'toggleRainWind',
         'toggleBloodStains', 'toggleFireEffects', 'toggleScenarios'].forEach(function (k) {
            var cb = document.getElementById('toggle-' + k);
            if (cb && s[k] !== undefined) cb.checked = s[k];
        });
    }

    function fill(el) {
        var pct = ((el.value - el.min) / (el.max - el.min)) * 100;
        el.style.background =
            'linear-gradient(to right,rgba(245,166,35,0.35) 0%,rgba(245,166,35,0.55) ' +
            pct + '%,var(--bg-2) ' + pct + '%)';
    }

    function post(evt, data) {
        fetch('https://f5_boost/' + evt, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(function () {});
    }

    function switchTab(tab) {
        document.querySelectorAll('.rail-btn').forEach(function (b) { b.classList.remove('active'); });
        document.querySelectorAll('.view').forEach(function (v) { v.classList.remove('active'); });
        var btn = document.querySelector('.rail-btn[data-tab="' + tab + '"]');
        if (btn) btn.classList.add('active');
        var view = document.getElementById('view-' + tab);
        if (view) view.classList.add('active');
    }

    document.querySelectorAll('.rail-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
            switchTab(btn.dataset.tab);
        });
    });

    document.getElementById('close-btn').addEventListener('click', function () {
        closeUI();
        post('closeMenu');
    });

    document.querySelectorAll('.chip').forEach(function (btn) {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.chip').forEach(function (b) { b.classList.remove('active'); });
            btn.classList.add('active');
            currentSettings.graphicsPreset = btn.dataset.preset;
            post('applyGraphicsPreset', { preset: btn.dataset.preset });
        });
    });

    document.querySelectorAll('.seg').forEach(function (btn) {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.seg').forEach(function (b) { b.classList.remove('active'); });
            btn.classList.add('active');
            currentSettings.performanceMode = btn.dataset.mode;
            post('applyPerformanceMode', { mode: btn.dataset.mode });
        });
    });

    document.querySelectorAll('.range').forEach(function (sl) {
        fill(sl);
        sl.addEventListener('input', function () {
            var val = parseInt(sl.value);
            var vl = document.getElementById('val-' + sl.dataset.setting);
            if (vl) vl.textContent = val;
            fill(sl);
            currentSettings[sl.dataset.setting] = val;
            post('applySlider', { setting: sl.dataset.setting, value: val });
        });
    });

    document.querySelectorAll('.sr-only[data-setting]').forEach(function (cb) {
        cb.addEventListener('change', function () {
            currentSettings[cb.dataset.setting] = cb.checked;
            post('applyToggle', { setting: cb.dataset.setting, value: cb.checked });
        });
    });

    document.getElementById('reset-btn').addEventListener('click', function () {
        post('resetDefaults');
        notify(t('notify_settings_reset'));
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            closeUI();
            post('closeMenu');
        }
    });

    var head = document.querySelector('.head');
    var isDragging = false;
    var dragOffX = 0, dragOffY = 0;
    var positioned = false;

    head.addEventListener('mousedown', function (e) {
        if (e.button !== 0) return;
        if (e.target.closest('.close-btn') || e.target.closest('.fps-badge')) return;

        isDragging = true;
        app.classList.add('dragging');

        if (!positioned) {
            var rect = app.getBoundingClientRect();
            app.style.position = 'fixed';
            app.style.left = rect.left + 'px';
            app.style.top = rect.top + 'px';
            app.style.right = 'auto';
            app.style.transform = 'none';
            positioned = true;
        }

        var rect = app.getBoundingClientRect();
        dragOffX = e.clientX - rect.left;
        dragOffY = e.clientY - rect.top;
        e.preventDefault();
    });

    document.addEventListener('mousemove', function (e) {
        if (!isDragging) return;
        var x = Math.max(0, Math.min(e.clientX - dragOffX, window.innerWidth - app.offsetWidth));
        var y = Math.max(0, Math.min(e.clientY - dragOffY, window.innerHeight - app.offsetHeight));
        app.style.left = x + 'px';
        app.style.top = y + 'px';
    });

    document.addEventListener('mouseup', function () {
        if (isDragging) {
            isDragging = false;
            app.classList.remove('dragging');
        }
    });

    function renderProfiles(profiles) {
        profiles = profiles || [];
        profileListEl.innerHTML = '';

        if (profiles.length === 0) {
            profileListEl.style.display = 'none';
            profileEmptyEl.style.display = 'flex';
        } else {
            profileListEl.style.display = 'flex';
            profileEmptyEl.style.display = 'none';

            profiles.forEach(function (p) {
                var item = document.createElement('div');
                item.className = 'profile-item';
                var isDefault = !!p.is_default;

                item.innerHTML =
                    '<div class="profile-info">' +
                        '<button class="profile-star' + (isDefault ? ' active' : '') + '" data-slot="' + p.slot + '" data-tip="' + t(isDefault ? 'tip_unset_default' : 'tip_set_default') + '">' +
                            '<span class="material-symbols-rounded">star</span>' +
                        '</button>' +
                        '<span class="profile-name">' + escapeHtml(p.name) + '</span>' +
                    '</div>' +
                    '<div class="profile-actions">' +
                        '<button class="profile-overwrite" data-slot="' + p.slot + '" data-tip="' + t('tip_overwrite') + '">' +
                            '<span class="material-symbols-rounded">save</span>' +
                        '</button>' +
                        '<button class="profile-load" data-slot="' + p.slot + '" data-tip="' + t('tip_load') + '">' +
                            '<span class="material-symbols-rounded">download</span>' +
                        '</button>' +
                        '<button class="profile-delete" data-slot="' + p.slot + '" data-tip="' + t('tip_delete') + '">' +
                            '<span class="material-symbols-rounded">delete</span>' +
                        '</button>' +
                    '</div>';

                profileListEl.appendChild(item);
            });
        }

        profileCounterEl.textContent = profiles.length + ' / ' + maxProfiles;
        profileSaveSection.style.display = profiles.length >= maxProfiles ? 'none' : '';
    }

    profileListEl.addEventListener('click', function (e) {
        var btn = e.target.closest('button');
        if (!btn) return;
        var slot = parseInt(btn.dataset.slot);

        if (btn.classList.contains('profile-star')) {
            post('setDefault', { slot: btn.classList.contains('active') ? 0 : slot });
        } else if (btn.classList.contains('profile-overwrite')) {
            post('updateProfile', { slot: slot });
        } else if (btn.classList.contains('profile-load')) {
            post('loadProfile', { slot: slot });
        } else if (btn.classList.contains('profile-delete')) {
            post('deleteProfile', { slot: slot });
        }
    });

    profileSaveBtn.addEventListener('click', function () {
        var name = profileNameInput.value.trim();
        if (!name) return;
        post('saveProfile', { name: name });
        profileNameInput.value = '';
    });

    profileNameInput.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            profileSaveBtn.click();
        }
        if (e.key !== 'Escape') {
            e.stopPropagation();
        }
    });

    var presetMap = ['ultra', 'high', 'balanced', 'medium', 'low', 'potato', 'minimal', 'none'];
    var modeMap = ['quality', 'balanced', 'performance', 'none'];
    var toggleKeys = ['toggleClearEvents', 'toggleLightReflections', 'toggleRainWind',
                      'toggleBloodStains', 'toggleFireEffects', 'toggleScenarios'];

    var B32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

    function b32val(c) {
        if (c === 'O') c = '0';
        else if (c === 'I' || c === 'L') c = '1';
        return B32.indexOf(c);
    }

    function b32encode(n, len) {
        var s = '';
        for (var i = 0; i < len; i++) {
            s = B32[n % 32] + s;
            n = Math.floor(n / 32);
        }
        return s;
    }

    function b32decode(s) {
        var n = 0;
        for (var i = 0; i < s.length; i++) {
            var v = b32val(s[i]);
            if (v < 0) return -1;
            n = n * 32 + v;
        }
        return n;
    }

    function b32check(data) {
        var sum = 0;
        for (var i = 0; i < data.length; i++) {
            var v = b32val(data[i]);
            if (v < 0) return '';
            sum = (sum * 3 + v) % 31;
        }
        return B32[sum];
    }

    function clamp100(v) { return Math.max(0, Math.min(100, v || 0)); }

    function encodeSettings(s) {
        var p = presetMap.indexOf(s.graphicsPreset);
        var m = modeMap.indexOf(s.performanceMode);
        if (p < 0) p = 7;
        if (m < 0) m = 3;
        var bits = 0;
        for (var i = 0; i < toggleKeys.length; i++) {
            if (s[toggleKeys[i]]) bits |= (1 << i);
        }

        var n = p;
        n = n * 4 + m;
        n = n * 128 + clamp100(s.shadowDistance);
        n = n * 128 + clamp100(s.objectQuality);
        n = n * 128 + clamp100(s.characterQuality);
        n = n * 128 + clamp100(s.vehicleDistance);
        n = n * 64 + bits;

        var data = b32encode(n, 8);
        var code = data + b32check(data);
        return 'F5-' + code.substring(0, 3) + '-' + code.substring(3, 6) + '-' + code.substring(6, 9);
    }

    function decodeSettings(code) {
        if (!code) return null;
        var raw = code.trim().toUpperCase().replace(/[-\s]/g, '');
        if (raw.substring(0, 2) !== 'F5') return null;
        var payload = raw.substring(2);
        if (payload.length !== 9) return null;

        var data = payload.substring(0, 8);
        if (b32check(data) !== payload[8]) return null;

        var n = b32decode(data);
        if (n < 0) return null;

        var toggleBits = n % 64;  n = Math.floor(n / 64);
        var vehicle    = n % 128; n = Math.floor(n / 128);
        var character  = n % 128; n = Math.floor(n / 128);
        var object     = n % 128; n = Math.floor(n / 128);
        var shadow     = n % 128; n = Math.floor(n / 128);
        var m          = n % 4;   n = Math.floor(n / 4);
        var p          = n % 8;

        if (p >= presetMap.length || m >= modeMap.length) return null;
        if (shadow > 100 || object > 100 || character > 100 || vehicle > 100) return null;

        var s = {
            graphicsPreset: presetMap[p],
            performanceMode: modeMap[m],
            shadowDistance: shadow,
            objectQuality: object,
            characterQuality: character,
            vehicleDistance: vehicle
        };
        for (var j = 0; j < toggleKeys.length; j++) {
            s[toggleKeys[j]] = !!(toggleBits & (1 << j));
        }
        return s;
    }

    document.getElementById('profile-export-btn').addEventListener('click', function () {
        if (!currentSettings || !currentSettings.graphicsPreset) return;
        profileCodeInput.value = encodeSettings(currentSettings);
        profileCodeInput.select();
        notify(t('notify_code_generated'), 'info');
    });

    document.getElementById('profile-import-btn').addEventListener('click', function () {
        var settings = decodeSettings(profileCodeInput.value);
        if (!settings) {
            profileCodeInput.style.borderColor = 'var(--danger)';
            setTimeout(function () { profileCodeInput.style.borderColor = ''; }, 800);
            notify(t('notify_invalid_code'), 'error');
            return;
        }
        profileCodeInput.style.borderColor = '#34d399';
        setTimeout(function () { profileCodeInput.style.borderColor = ''; }, 800);
        post('importProfile', { settings: settings });
        notify(t('notify_settings_applied'));
        setTimeout(function () { switchTab('presets'); }, 300);
    });

    profileCodeInput.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            document.getElementById('profile-import-btn').click();
        }
        if (e.key !== 'Escape') {
            e.stopPropagation();
        }
    });

    var isRotating = false;

    document.addEventListener('mousedown', function (e) {
        if (e.button !== 0) return;
        if (isDragging) return;
        if (app.classList.contains('hidden')) return;
        if (e.target.closest('.app')) return;
        isRotating = true;
        document.body.classList.add('camera-active');
        post('startCameraControl');
    });

    document.addEventListener('mouseup', function (e) {
        if (e.button === 0 && isRotating) {
            isRotating = false;
            document.body.classList.remove('camera-active');
            post('stopCameraControl');
        }
    });

})();
