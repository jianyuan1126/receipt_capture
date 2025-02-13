import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _highQualityImages = true;
  bool _saveOriginalImages = true;
  bool _darkMode = false;
  String _imageLocation = 'Internal Storage';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highQualityImages = prefs.getBool('highQualityImages') ?? true;
      _saveOriginalImages = prefs.getBool('saveOriginalImages') ?? true;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _imageLocation = prefs.getString('imageLocation') ?? 'Internal Storage';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SettingsHeader('Camera Settings'),
          SwitchListTile(
            title: const Text('High Quality Images'),
            subtitle: const Text('Capture images in high resolution'),
            value: _highQualityImages,
            onChanged: (value) {
              setState(() {
                _highQualityImages = value;
                _saveSetting('highQualityImages', value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Save Original Images'),
            subtitle: const Text('Keep original images after processing'),
            value: _saveOriginalImages,
            onChanged: (value) {
              setState(() {
                _saveOriginalImages = value;
                _saveSetting('saveOriginalImages', value);
              });
            },
          ),
          const _SettingsHeader('Storage'),
          ListTile(
            title: const Text('Image Storage Location'),
            subtitle: Text(_imageLocation),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Location'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        title: const Text('Internal Storage'),
                        value: 'Internal Storage',
                        groupValue: _imageLocation,
                        onChanged: (value) {
                          setState(() {
                            _imageLocation = value.toString();
                            _saveSetting('imageLocation', value);
                            Navigator.pop(context);
                          });
                        },
                      ),
                      RadioListTile(
                        title: const Text('External Storage'),
                        value: 'External Storage',
                        groupValue: _imageLocation,
                        onChanged: (value) {
                          setState(() {
                            _imageLocation = value.toString();
                            _saveSetting('imageLocation', value);
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const _SettingsHeader('App Settings'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
                _saveSetting('darkMode', value);
              });
            },
          ),
          const _SettingsHeader('About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Developer'),
            subtitle: const Text('Ng Jian Yuan'),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;

  const _SettingsHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 