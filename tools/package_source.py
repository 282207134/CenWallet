"""Create a portable source archive without build caches or machine paths."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parent.parent
output = root / 'dist' / 'CenWallet-source.zip'
output.parent.mkdir(exist_ok=True)
skip = {'build', '.dart_tool', '.git', 'dist', '.gradle', '.kotlin', 'Pods', '.symlinks', 'ephemeral'}
ignore = {'local.properties', 'Generated.xcconfig', 'flutter_export_environment.sh', '.flutter-plugins-dependencies', '.DS_Store', '.last_build_id'}
with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
    for file in sorted(root.rglob('*')):
        relative = file.relative_to(root)
        if file.is_file() and not any(part in skip for part in relative.parts) and file.name not in ignore:
            archive.write(file, Path('CenWallet') / relative)
print(f'{output} ({output.stat().st_size / 1024 / 1024:.1f} MB)')
