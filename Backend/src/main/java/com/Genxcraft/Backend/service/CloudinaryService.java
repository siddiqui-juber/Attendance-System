package com.Genxcraft.Backend.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;

@Service
public class CloudinaryService {

    @Autowired
    private SettingsService settingsService;

    private static final String UPLOAD_DIR = "uploads";

    public String uploadImage(MultipartFile file) throws IOException {
        String mockMode = settingsService.getSetting("whatsapp_mock_mode"); // reusing or reading settings

        boolean isMock = "true".equalsIgnoreCase(settingsService.getSetting("cloudinary_mock_mode"));

        if (isMock) {
            return saveLocally(file);
        } else {
            try {
                Cloudinary cloudinary = new Cloudinary(ObjectUtils.asMap(
                        "cloud_name", settingsService.getSetting("cloudinary_cloud_name"),
                        "api_key", settingsService.getSetting("cloudinary_api_key"),
                        "api_secret", settingsService.getSetting("cloudinary_api_secret")
                ));
                Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.emptyMap());
                return (String) uploadResult.get("secure_url");
            } catch (Exception e) {
                // Fallback to local storage on error
                return saveLocally(file);
            }
        }
    }

    private String saveLocally(MultipartFile file) throws IOException {
        Path uploadPath = Paths.get(UPLOAD_DIR);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        String extension = getFileExtension(file.getOriginalFilename());
        String fileName = UUID.randomUUID().toString() + extension;
        Path filePath = uploadPath.resolve(fileName);

        Files.write(filePath, file.getBytes());

        // Assuming server runs on localhost:8080. If not, it can be customized.
        return "/uploads/" + fileName;
    }

    private String getFileExtension(String fileName) {
        if (fileName == null) return ".jpg";
        int lastIndex = fileName.lastIndexOf(".");
        return lastIndex == -1 ? ".jpg" : fileName.substring(lastIndex);
    }
}
