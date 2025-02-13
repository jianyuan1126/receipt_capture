import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SettingsService._init();

  Future<ResolutionPreset> getCameraQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final isHigh = prefs.getBool('highQualityImages') ?? true;
    return isHigh ? ResolutionPreset.high : ResolutionPreset.medium;
  }

  Future<bool> getSaveOriginalImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('saveOriginalImages') ?? true;
  }

  Future<String> getImageLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('imageLocation') ?? 'Internal Storage';
  }
} 