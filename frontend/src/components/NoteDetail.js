import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getNoteById, uploadAttachment } from '../services/noteService';

const NoteDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [note, setNote] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    const fetchNote = async () => {
      try {
        const data = await getNoteById(id);
        setNote(data);
        setLoading(false);
      } catch (err) {
        console.error('Błąd podczas pobierania notatki:', err);
        setError('Nie udało się pobrać notatki. Spróbuj ponownie później.');
        setLoading(false);
      }
    };

    fetchNote();
  }, [id]);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return;

    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      await uploadAttachment(id, formData);
      
      // Odświeżenie danych notatki po wgraniu pliku
      const updatedNote = await getNoteById(id);
      setNote(updatedNote);
      setFile(null);
      setUploading(false);
    } catch (err) {
      console.error('Błąd podczas wgrywania pliku:', err);
      setUploading(false);
    }
  };

  if (loading) return <div className="text-center mt-5"><div className="spinner-border" role="status"></div></div>;
  if (error) return <div className="alert alert-danger mt-3">{error}</div>;

  return (
    <div className="card">
      <div className="card-header">
        <div className="d-flex justify-content-between align-items-center">
          <h2>{note.title}</h2>
          <button 
            className="btn btn-outline-secondary"
            onClick={() => navigate('/')}
          >
            Powrót
          </button>
        </div>
      </div>
      <div className="card-body">
        <p className="text-muted mb-2">
          <small>Utworzono: {new Date(note.createdAt).toLocaleString()}</small>
        </p>
        {note.updatedAt && note.updatedAt !== note.createdAt && (
          <p className="text-muted mb-3">
            <small>Zaktualizowano: {new Date(note.updatedAt).toLocaleString()}</small>
          </p>
        )}
        
        <h5>Treść:</h5>
        <p style={{ whiteSpace: "pre-wrap" }}>{note.content}</p>
        
        {note.attachmentUrl && (
          <div className="mt-4">
            <h5>Załącznik:</h5>
            <div>
              <a 
                href={note.attachmentUrl} 
                target="_blank" 
                rel="noopener noreferrer"
                className="btn btn-info btn-sm"
              >
                Pobierz załącznik
              </a>
            </div>
          </div>
        )}
        
        <div className="mt-4">
          <h5>Dodaj załącznik:</h5>
          <form onSubmit={handleUpload}>
            <div className="input-group mb-3">
              <input 
                type="file" 
                className="form-control" 
                onChange={handleFileChange} 
                disabled={uploading}
              />
              <button 
                type="submit" 
                className="btn btn-primary" 
                disabled={!file || uploading}
              >
                {uploading ? 'Wgrywanie...' : 'Wgraj plik'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default NoteDetail;