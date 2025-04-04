package com.example.notesapp.service;

import com.example.notesapp.model.Note;
import com.example.notesapp.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.persistence.EntityNotFoundException;
import java.util.List;

@Service
public class NoteService {

    private final NoteRepository noteRepository;
    private final S3Service s3Service;
    
    @Autowired
    public NoteService(NoteRepository noteRepository, S3Service s3Service) {
        this.noteRepository = noteRepository;
        this.s3Service = s3Service;
    }
    
    // Zwraca notatki należące tylko do zalogowanego użytkownika
    public List<Note> getAllNotes() {
        String userId = getCurrentUserId();
        return noteRepository.findByUserId(userId);
    }
    
    // Pobiera notatkę tylko jeśli należy do zalogowanego użytkownika
    public Note getNoteById(Long id) {
        Note note = noteRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Note not found with id: " + id));
        
        if (!note.getUserId().equals(getCurrentUserId())) {
            throw new AccessDeniedException("You don't have permission to access this note");
        }
        
        return note;
    }
    
    public Note createNote(Note note) {
        String userId = getCurrentUserId();
        String userName = getCurrentUserName();
        
        note.setUserId(userId);
        note.setUserName(userName);
        
        return noteRepository.save(note);
    }
    
    public String uploadAttachment(Long noteId, MultipartFile file) {
        Note note = getNoteById(noteId);
        
        // Sprawdzenie uprawnień zostało już wykonane w metodzie getNoteById
        
        String fileUrl = s3Service.uploadFile(file);
        note.setAttachmentUrl(fileUrl);
        noteRepository.save(note);
        return fileUrl;
    }
    
    // Pomocnicza metoda do pobierania ID aktualnego użytkownika z tokenu JWT
    private String getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            return jwt.getSubject(); // subject tokenu to ID użytkownika w Cognito
        }
        throw new IllegalStateException("User not authenticated or invalid token");
    }
    
    // Pomocnicza metoda do pobierania nazwy użytkownika z tokenu JWT
    private String getCurrentUserName() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            return jwt.getClaimAsString("cognito:username"); // nazwa użytkownika w Cognito
        }
        return "Unknown User";
    }
}