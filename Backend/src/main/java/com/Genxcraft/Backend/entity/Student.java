package com.Genxcraft.Backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "students")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_id", nullable = false, unique = true)
    private String studentId;

    @Column(nullable = false)
    private String name;

    @Column(name = "roll_number", nullable = false)
    private String rollNumber;

    @ManyToOne(optional = false)
    @JoinColumn(name = "class_id", nullable = false)
    private Clazz clazz;

    @ManyToOne(optional = false)
    @JoinColumn(name = "batch_id", nullable = false)
    private Batch batch;

    @Column(name = "parent_name", nullable = false)
    private String parentName;

    @Column(name = "parent_mobile", nullable = false)
    private String parentMobile;

    @Column(name = "parent_whatsapp", nullable = false)
    private String parentWhatsApp;

    private String address;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "qr_code_token", nullable = false, unique = true)
    private String qrCodeToken;
}
