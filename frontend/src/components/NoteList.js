import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getAllNotes } from '../services/noteService';

const NoteList = () => {
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchNotes = async () => {
      try {
        const response = await getAllNotes();
        setNotes(response);
        setLoading(false);
      } catch (err) {
        console.error('Błąd podczas pobierania notatek:', err);
        setError('Nie udało się pobrać notatek. Spróbuj ponownie później.');
        setLoading(false);
      }
    };

    fetchNotes();
  }, []);

  if (loading) return <div className="text-center mt-5"><div className="spinner-border" role="status"></div></div>;
  if (error) return <div className="alert alert-danger mt-3">{error}</div>;

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Moje Notatki</h2>
        <Link to="/create" className="btn btn-success">+ Nowa Notatka</Link>
      </div>

      {notes.length === 0 ? (
        <div className="alert alert-info">Nie masz jeszcze żadnych notatek. Utwórz pierwszą!</div>
      ) : (
        <div className="row">
          {notes.map(note => (
            <div className="col-md-4 mb-3" key={note.id}>
              <div className="card h-100">
                <div className="card-body">
                  <h5 className="card-title">{note.title}</h5>
                  <p className="card-text">
                    {note.content && note.content.length > 100
                      ? `${note.content.substring(0, 100)}...`
                      : note.content}
                  </p>
                </div>
                <div className="card-footer bg-transparent">
                  <Link to={`/notes/${note.id}`} className="btn btn-primary btn-sm">
                    Szczegóły
                  </Link>
                  {note.attachmentUrl && (
                    <span className="ms-2 badge bg-info">
                      <i className="bi bi-paperclip"></i> Załącznik
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default NoteList;