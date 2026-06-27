package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.entity.Student;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Service
public class WhatsAppService {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppService.class);
    private final RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private SettingsService settingsService;

    public void sendPresentNotification(Student student, LocalDate date, LocalTime time) {
        String formattedDate = date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        String formattedTime = time.format(DateTimeFormatter.ofPattern("HH:mm"));

        String message = String.format(
                "Dear Parent,\n" +
                "Your child %s has been marked Present.\n" +
                "Date: %s\n" +
                "Time: %s\n" +
                "Class: %s\n" +
                "Thank you.",
                student.getName(),
                formattedDate,
                formattedTime,
                student.getClazz().getName()
        );

        sendWhatsApp(student.getParentWhatsApp(), message);
    }

    public void sendAbsentNotification(Student student, LocalDate date) {
        String message = String.format(
                "Dear Parent,\n" +
                "Your child %s has been marked Absent today.\n" +
                "Please contact the institute if required.\n" +
                "Thank you.",
                student.getName()
        );

        sendWhatsApp(student.getParentWhatsApp(), message);
    }

    private void sendWhatsApp(String whatsappNumber, String message) {
        boolean isMock = "true".equalsIgnoreCase(settingsService.getSetting("whatsapp_mock_mode"));
        String apiUrl = settingsService.getSetting("whatsapp_api_url");
        String apiKey = settingsService.getSetting("whatsapp_api_key");

        if (isMock) {
            log.info("\n--- [MOCK WHATSAPP NOTIFICATION SENT] ---\nTo: {}\nMessage:\n{}\n----------------------------------------", whatsappNumber, message);
        } else {
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                headers.set("Authorization", "Bearer " + apiKey);

                Map<String, Object> body = new HashMap<>();
                body.put("messaging_product", "whatsapp");
                body.put("to", whatsappNumber);
                body.put("type", "text");
                Map<String, String> textMap = new HashMap<>();
                textMap.put("body", message);
                body.put("text", textMap);

                HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
                restTemplate.postForObject(apiUrl, request, String.class);
                log.info("WhatsApp notification sent successfully to {}", whatsappNumber);
            } catch (Exception e) {
                log.error("Failed to send WhatsApp notification to {}: {}", whatsappNumber, e.getMessage());
            }
        }
    }
}
