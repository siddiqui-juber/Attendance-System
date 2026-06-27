package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.entity.AppSettings;
import com.Genxcraft.Backend.repository.AppSettingsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class SettingsService {

    @Autowired
    private AppSettingsRepository appSettingsRepository;

    private static final Map<String, String> DEFAULTS = new HashMap<>();

    static {
        DEFAULTS.put("whatsapp_mock_mode", "true");
        DEFAULTS.put("whatsapp_api_url", "https://api.whatsapp.com/v1/messages");
        DEFAULTS.put("whatsapp_api_key", "MOCK_TOKEN_12345");
        DEFAULTS.put("cloudinary_mock_mode", "true");
        DEFAULTS.put("cloudinary_cloud_name", "mock_cloud");
        DEFAULTS.put("cloudinary_api_key", "mock_key");
        DEFAULTS.put("cloudinary_api_secret", "mock_secret");
    }

    public String getSetting(String key) {
        return appSettingsRepository.findByKey(key)
                .map(AppSettings::getValue)
                .orElse(DEFAULTS.getOrDefault(key, ""));
    }

    public void updateSetting(String key, String value) {
        AppSettings setting = appSettingsRepository.findByKey(key)
                .orElse(AppSettings.builder().key(key).build());
        setting.setValue(value);
        appSettingsRepository.save(setting);
    }

    public Map<String, String> getAllSettings() {
        Map<String, String> settings = new HashMap<>(DEFAULTS);
        List<AppSettings> dbSettings = appSettingsRepository.findAll();
        for (AppSettings s : dbSettings) {
            settings.put(s.getKey(), s.getValue());
        }
        return settings;
    }
}
