import axios from 'axios';
import { getIdToken } from './authService';

// Bazowy URL do API - używa zmiennych środowiskowych dostępnych w window.env (injected at runtime)
// lub process.env (dostępne podczas budowania)
// lub fallback do localhost dla lokalnego rozwoju
const API_BASE_URL = (window.env && window.env.REACT_APP_API_URL) || 
                     process.env.REACT_APP_API_URL || 
                     'http://localhost:8080';

// Pomocnicza funkcja do dołączania tokena JWT do nagłówków
const getHeaders = async () => {
  const token = await getIdToken();
  return {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  };
};

// Pobieranie wszystkich notatek
export const getAllNotes = async () => {
  try {
    const headers = await getHeaders();
    const response = await axios.get(`${API_BASE_URL}/notes`, headers);
    return response.data;
  } catch (error) {
    console.error('Error fetching notes:', error);
    throw error;
  }
};

// Pobieranie pojedynczej notatki po ID
export const getNoteById = async (id) => {
  try {
    const headers = await getHeaders();
    const response = await axios.get(`${API_BASE_URL}/notes/${id}`, headers);
    return response.data;
  } catch (error) {
    console.error(`Error fetching note with id ${id}:`, error);
    throw error;
  }
};

// Tworzenie nowej notatki
export const createNote = async (noteData) => {
  try {
    const headers = await getHeaders();
    const response = await axios.post(`${API_BASE_URL}/notes`, noteData, headers);
    return response.data;
  } catch (error) {
    console.error('Error creating note:', error);
    throw error;
  }
};

// Przesyłanie pliku jako załącznika do notatki
export const uploadAttachment = async (noteId, formData) => {
  try {
    const token = await getIdToken();
    const response = await axios.post(`${API_BASE_URL}/notes/${noteId}/upload`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
        'Authorization': `Bearer ${token}`
      },
    });
    return response.data;
  } catch (error) {
    console.error('Error uploading attachment:', error);
    throw error;
  }
};