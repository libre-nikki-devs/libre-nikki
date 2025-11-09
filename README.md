# Libre Nikki

Libre Nikki is a surreal walking simulator running on Godot Engine, heavily inspired by Yume Nikki and open for collaboration.

## Downloading

Official builds of the game can be downloaded from the [Libre Nikki's Releases page](https://github.com/libre-nikki-devs/libre-nikki/releases/latest).

## Exporting

To export the project to an executable, you will need:
* [Godot 4.5](https://godotengine.org/releases/4.5) (exact version; C# support is not required),
* at least 4 GiB of free disk space.

### Exporting from GUI:

* Go to the [Libre Nikki's Repository page](https://github.com/libre-nikki-devs/libre-nikki).
* Press **Code > Download ZIP**.
* Open Godot Engine.
* Press **Import** and select the project's ZIP file.
* Once imported, select the project and press **Edit**.
* Navigate to **Project > Export...** and select a preset. Presets for Windows and Linux are available.
  * Before exporting the project, make sure that you have Godot export templates installed. If they are missing, press **Manage Export Templates**. In the Export Template Manager, select **Official Github Releases mirror** and then press **Download and Install**.
* Press **Export Project... > Save**. By default, the project is exported to `build/`.

### Exporting from CLI (Linux):

* Clone the repository using `git`:
  ```sh
  git clone https://github.com/libre-nikki-devs/libre-nikki
  ```
* Change the current directory to the project's root directory:
  ```sh
  cd libre-nikki
  ```
* Before exporting the project, make sure that you have Godot export templates installed. If they are missing, download the export templates using `wget` and then extract them with `7z` to `$XDG_DATA_HOME/godot/export_templates/4.5.stable/`:
  ```sh
  wget https://github.com/godotengine/godot-builds/releases/download/4.5-stable/Godot_v4.5-stable_export_templates.tpz && 7z e Godot_v4.5-stable_export_templates.tpz -o${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.5.stable/ && rm Godot_v4.5-stable_export_templates.tpz
  ```
* Export the project:
  ```sh
  godot --headless --export-debug "Linux"
  ```
* Once the project has been exported, the game can be run with:
  ```sh
  ./build/libre_nikki_linux.x86_64
  ```

## Contributing

Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for how to get started with contributing to Libre Nikki.

## Licensing

Libre Nikki's source code is licensed under the terms of the GNU General Public License Version 3.

Libre Nikki features assets that use licenses compatible with the GPL-3. See [ASSET_LICENSING](./ASSET_LICENSING) for the detailed asset licensing information.

Licenses' terms and conditions are located in the [LICENSES](./LICENSES) directory.
