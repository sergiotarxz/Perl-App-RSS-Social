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

fetch('/private/rom/download/' + document.querySelector('#rom-name').value).then( (res) => {
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
    Module.setFastForwardMultiplier(12);
    Module.toggleInput(false);
    Module.setVolume(0);
    document.getElementById('canvas-container').addEventListener('contextmenu', (e) => {
        console.log('hola');
        e.preventDefault();
    }, true);
    document.getElementById('fullscreen-emulator').onclick = () => {
        Module.toggleInput(true);
        document.getElementById('canvas-container').requestFullscreen();
    };
    const addListenersButtons = (key) => {
        const button = document.querySelector('button.gba-button-' + key)
            ?? document.querySelector('button.gba-button-pad-'+key);;
        button.addEventListener('touchstart', () => {
            Module.buttonPress(key);
        });
        button.addEventListener('touchend', () => {
            Module.buttonUnpress(key);
        });
        button.addEventListener('mousedown', () => {
            Module.buttonPress(key);
        });
        button.addEventListener('mouseup', () => {
            Module.buttonUnpress(key);
        });
        let last_digest;
        window.setInterval(async () => {
            const save = Module.getSave();
            if (save != null) {
                const hash = new Uint8Array(await window.crypto.subtle.digest("SHA-256", save)).toHex();
                if (last_digest != null && hash !== last_digest) {
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
                }    
                last_digest = hash;
            }
        }, 5000);
    };
    addListenersButtons('a');
    addListenersButtons('b');
    addListenersButtons('l');
    addListenersButtons('r');
    addListenersButtons('start');
    addListenersButtons('select');
    addListenersButtons('up');
    addListenersButtons('down');
    addListenersButtons('left');
    addListenersButtons('right');
}

