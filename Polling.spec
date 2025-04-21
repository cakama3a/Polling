# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['C:\\Users\\cakam\\Documents\\GitHub\\Polling\\Python.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=['matplotlib.backends.backend_tkagg'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=['C:\\Users\\cakam\\AppData\\Local\\Temp\\PollingBuild_14346\\hook-matplotlib.py'],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='Polling',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['C:\\Users\\cakam\\Documents\\GitHub\\Polling\\icon.ico'],
)
