# Building the lab's native library

Godot 4.7.2 (official), godot-cpp (master, built with Godot 4.7.2's own `extension_api.json`), scons, g++ and
mingw-w64 (posix threads).

```bash
godot --headless --dump-extension-api           # writes extension_api.json
git clone https://github.com/godotengine/godot-cpp /opt/lab/godot-cpp
cd /opt/lab/godot-cpp && scons platform=linux target=template_debug custom_api_file=/opt/lab/extension_api.json
cd /opt/lab/godot-cpp && scons platform=windows use_mingw=yes target=template_debug custom_api_file=/opt/lab/extension_api.json
cd lab/traversal_procedural/native && scons platform=linux target=template_debug custom_api_file=/opt/lab/extension_api.json
cd lab/traversal_procedural/native && scons platform=windows use_mingw=yes target=template_debug custom_api_file=/opt/lab/extension_api.json
```

The built `bin/liblabproc.*` files are committed so the project opens and plays on Windows without building.
