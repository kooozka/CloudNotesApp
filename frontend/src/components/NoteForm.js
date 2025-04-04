import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createNote } from '../services/noteService';

const NoteForm = () => {
  const navigate = useNavigate();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!title.trim() || !content.trim()) {
      setError('Tytuł i treść są wymagane');
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      const newNote = await createNote({
        title: title.trim(),
        content: content.trim()
      });
      
      navigate(`/notes/${newNote.id}`);
    } catch (err) {
      console.error('Błąd podczas tworzenia notatki:', err);
      setError('Nie udało się utworzyć notatki. Spróbuj ponownie później.');
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <div className="card-header">
        <h2>Nowa Notatka</h2>
      </div>
      <div className="card-body">
        {error && <div className="alert alert-danger">{error}</div>}
        
        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label htmlFor="title" className="form-label">Tytuł</label>
            <input 
              type="text"
              className="form-control"
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={loading}
              required
            />
          </div>
          
          <div className="mb-3">
            <label htmlFor="content" className="form-label">Treść</label>
            <textarea 
              className="form-control"
              id="content"
              rows="6"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              disabled={loading}
              required
            />
          </div>
          
          <div className="d-flex justify-content-between">
            <button 
              type="button" 
              className="btn btn-secondary"
              onClick={() => navigate('/')}
              disabled={loading}
            >
              Anuluj
            </button>
            <button 
              type="submit" 
              className="btn btn-primary"
              disabled={loading}
            >
              {loading ? 'Zapisywanie...' : 'Zapisz Notatkę'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NoteForm;