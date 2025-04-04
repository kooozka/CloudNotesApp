package com.example.notesapp.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Note {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Tytuł jest wymagany")
    @Size(max = 100, message = "Tytuł może mieć maksymalnie 100 znaków")
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String content;
    
    private String attachmentUrl;
    
    @CreationTimestamp
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    private LocalDateTime updatedAt;
    
    // Dodane pola dla Cognito
    private String userId; // ID użytkownika z Cognito
    private String userName; // Nazwa użytkownika (opcjonalna)
}