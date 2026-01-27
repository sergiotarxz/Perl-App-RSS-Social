import mGBA from '/wasm/mgba.js';

async function get_save() {
    const res = await fetch('/private/save/download/' + document.querySelector('#rom-name').value);
    if (res.status != 200) {
        console.log('No save');
        return;
    }
    try {
        const bytes = await res.bytes();
        return bytes;
    } catch (e) {
        console.log('No save ' + e);
    } 
    return;
}

const rom_name = document.querySelector('#rom-name').value;
fetch('/private/rom/download/' + rom_name).then( (res) => {
    get_save().then((save) => { 
        res.bytes().then( (bytes) => {
            let canvas_id = 'screen';
            Module = {
                canvas: (function () {
                    return document.getElementById(canvas_id);
                })()
            };
            mgba = mGBA;
            mGBA(Module).then(function (Module) {
                Module.FS.mkdir('/data');
                Module.FS.mount(Module.FS.filesystems.IDBFS, {autoPersist: true}, '/data');

                // mount auto save directory, this should auto persist, while the data mount should not
                Module.FS.mkdir('/autosave');
                Module.FS.mount(Module.FS.filesystems.IDBFS, { autoPersist: true }, '/autosave');

                // load data from IDBFS
                Module.FS.syncfs(true, (err) => {
                  if (err) {
                    reject(new Error(`Error syncing app data from IndexedDB: ${err}`));
                  }

                  // When we read from indexedb, these directories may or may not exist.
                  // If we mkdir and they already exist they throw, so just catch all of them.
                  try {
                    Module.FS.mkdir('/data/saves');
                  } catch (e) {}
                  try {
                    Module.FS.mkdir('/data/states');
                  } catch (e) {}
                  try {
                    Module.FS.mkdir('/data/games');
                  } catch (e) {}
                  try {
                    Module.FS.mkdir('/data/cheats');
                  } catch (e) {}
                  try {
                    Module.FS.mkdir('/data/screenshots');
                  } catch (e) {}
                  try {
                    Module.FS.mkdir('/data/patches');
                  } catch (e) {}

                  start(bytes, canvas_id, save);
                });
            });
        });
    });
});

function start(bytes, canvas_id, save_data) {
    try {
        Module.FS.unlink('/autosave/rom_auto.ss');
    } catch (e) { }
    Module.FS.writeFile('/data/games/rom.gba', bytes);
    const save = '/rom.sav';
    if (!Module.FS.analyzePath(save).exists) {
        if (!save_data) {
            console.log('Creating empty save');
        }
        Module.FS.writeFile(save, save_data ?? '');
    }
    Module.loadGame('/data/games/rom.gba', save);
    const fastForwardSelector = document.querySelector('#fast-forward-speed');
    Module.setFastForwardMultiplier(fastForwardSelector.options[fastForwardSelector.selectedIndex].value);
    fastForwardSelector.addEventListener('change', () => {
        Module.setFastForwardMultiplier(fastForwardSelector.options[fastForwardSelector.selectedIndex].value);
    });
    Module.toggleInput(false);
    const volumeSelector = document.querySelector('#volume-selector');
    Module.setVolume(volumeSelector.options[volumeSelector.selectedIndex].value);
    volumeSelector.addEventListener('change', () => {
        Module.setVolume(volumeSelector.options[volumeSelector.selectedIndex].value);
    });

    let last_value = false;
    document.getElementById('canvas-container').addEventListener('click', (e) => {
        last_value = !last_value;
        Module.toggleInput(last_value);
    });
    document.getElementById('canvas-container').addEventListener('contextmenu', (e) => {
        console.log('hola');
        e.preventDefault();
    }, true);
    document.getElementById('fullscreen-emulator').onclick = () => {
        Module.toggleInput(true);
        let url = new URL(window.location.href);
        url.pathname = "/size";
        url.searchParams.append('width', window.innerWidth);
        url.searchParams.append('height', window.innerHeight);
        fetch(url).then(() => {
            console.log('sent width/height to server');
        });
        document.getElementById('canvas-container').requestFullscreen();
    };
    let id_to_gamepad = {};
    let gamepads = navigator.getGamepads();
    for (let gamepad of gamepads) {
        id_to_gamepad[gamepad.id] = gamepad;
    }
    window.setInterval(() => {
        let gamepads = navigator.getGamepads();
        for (let gamepad of gamepads) {
            id_to_gamepad[gamepad.id] = gamepad;
        }
    }, 1000);
    window.setTimeout(() => {
        let select_gamepad = document.querySelector('select#gamepad');
        if (select_gamepad != null) {
            select_gamepad.innerHTML = '';
            for (let key of Object.keys(id_to_gamepad)) {
                console.log(key);
                const el = document.createElement('option');
                el.value = key;
                el.innerText = key;
                select_gamepad.appendChild(el);
            }
        }
    }, 2000);
    let pressed = {
        a: 0,
        b: 0,
        r: 0,
        l: 0,
        start: 0,
        select: 0,
        up: 0,
        down: 0,
        left: 0,
        right: 0,
    }
    let buttons = {
        a: 1,
        b: 0,
        r: 5,
        l: 4,
        start: 9,
        select: 8,
        up: 12,
        down: 13,
        left: 14,
        right: 15,

    };
    window.setInterval(() => {
        let final_presses = {};
        for (let button in pressed) {
            final_presses[button] = 0;
        }
        for (let gamepad of navigator.getGamepads()) {
            for (let button in buttons) {
                if (gamepad.buttons[buttons[button]].pressed) {
                    final_presses[button] = 1;
                }
            }
        } 
        for (let button in pressed) {
            if (final_presses[button] && !pressed[button]) {
                Module.buttonPress(button);
            }
            if (!final_presses[button] && pressed[button]) {
                Module.buttonUnpress(button);
            }
        }
        pressed = final_presses;
    }, 30);
    const addListenersButtons = (key) => {
        const button = document.querySelector('button.gba-button-' + key)
            ?? document.querySelector('button.gba-button-pad-'+key);;
        button.addEventListener('touchmove', (e) => {
            const touch = e.touches[0];
            if (key === 'super') {
                Module.buttonUnpress('up');
                Module.buttonUnpress('down');
                Module.buttonUnpress('right');
                Module.buttonUnpress('left');
                const rect = button.getBoundingClientRect();
                const x = touch.clientX - rect.left;
                const y = touch.clientY - rect.top;
                const width = rect.width;
                const height = rect.height;
                const distances = {
                    left:  x,
                    right: rect.width - x,
                    up:    y,
                    down:  rect.height - y
                };
                const nearestEdge = Object.keys(distances).reduce((a, b) =>
                  distances[a] < distances[b] ? a : b
                );
                Module.buttonPress(nearestEdge);
                e.preventDefault();
                return;
            }
        });
        button.addEventListener('touchstart', (e) => {
            const touch = e.touches[0];
            if (key === 'super') {
                const rect = button.getBoundingClientRect();
                const x = touch.clientX - rect.left;
                const y = touch.clientY - rect.top;
                const width = rect.width;
                const height = rect.height;
                const distances = {
                    left:  x,
                    right: rect.width - x,
                    up:    y,
                    down:  rect.height - y
                };
                const nearestEdge = Object.keys(distances).reduce((a, b) =>
                  distances[a] < distances[b] ? a : b
                );
                Module.buttonPress(nearestEdge);
                e.preventDefault();
                return;
            }
            Module.buttonPress(key);
        });
        button.addEventListener('touchend', () => {
            if (key === 'super') {
                Module.buttonUnpress('up');
                Module.buttonUnpress('down');
                Module.buttonUnpress('right');
                Module.buttonUnpress('left');
            }
            Module.buttonUnpress(key);
        });
        button.addEventListener('mousedown', () => {
            if (key === 'super') {
                return;
            }
            Module.buttonPress(key);
        });
        button.addEventListener('mouseup', () => {
            Module.buttonUnpress(key);
        });
        button.addEventListener('touchcancel', () => {
            Module.buttonUnpress(key);
        });
        button.addEventListener('touchmove', () => {
            Module.buttonPress(key);
        });
    };
    addListenersButtons('a');
    addListenersButtons('b');
    addListenersButtons('l');
    addListenersButtons('r');
    addListenersButtons('start');
    addListenersButtons('select');
    addListenersButtons('super');
    //addListenersButtons('up');
    //addListenersButtons('down');
    //addListenersButtons('left');
    //addListenersButtons('right');
    let last_digest;
    let last_date;
    window.setInterval(async () => {
        const save = Module.getSave();
        if (save != null) {
            const hash = new Uint8Array(await window.crypto.subtle.digest("SHA-256", save)).toHex();
            let valid_last_date = true;
            try {
                valid_last_date = last_date
                    !== Module.FS.stat('/rom.sav').mtime.toISOString();
            } catch (e) {
                console.log(e);
            }

            if ( valid_last_date && last_digest != null 
                    && hash !== last_digest) {
                const formData = new FormData();
                formData.append('date', Module.FS.stat('/rom.sav').mtime.toISOString());
                formData.append('save', new Blob([Module.getSave()]));
                fetch('/private/save/push/'
                        + document.querySelector('#rom-name').value, {
                    method: 'post',
                    body: formData,
                }).then((res) => {
                    console.log('Save upload response: ' + res.status);
                });
                last_date = Module.FS.stat('/rom.sav').mtime.toISOString();
            }    
            last_digest = hash;
        }
    }, 1000);
    for (const save of [...document.querySelectorAll('div.save img')]) {
        save.addEventListener('click', () => {
            if (confirm("Do you want to load a save? You will lose your unsaved progress.")) {
                (async () => {
                    const res = await fetch(save.src);
                    const bytes = await res.bytes();
                    Module.FS.writeFile('/data/states/rom.ss1', bytes);
                    Module.loadState(1);
                })();
            }
        });
    }
    document.querySelector('button#save-state-game').addEventListener('click', () => {
        Module.saveState(1);
        window.setTimeout(() => {
            const save = Module.FS.readFile('/data/states/rom.ss1');
            const formData = new FormData();
            formData.append('save_state', new Blob([save]));
            fetch('/private/save_state/push/'
                    + rom_name, {
                method: 'post',
                body: formData,
            }).then((res) => {
                // TODO: Proper notification system for users.
                alert('saved');
                console.log('Save state upload response: ' + res.status);
            });
        }, 1000);
    });
}

