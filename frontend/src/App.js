import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';

// Komponenty
import NavBar from './components/NavBar';
import NoteList from './components/NoteList';
import NoteDetail from './components/NoteDetail';
import NoteForm from './components/NoteForm';
import Login from './components/Login';
import Register from './components/Register';
import ProtectedRoute from './components/ProtectedRoute';

function App() {
  return (
    <BrowserRouter>
      <div className="App">
        <NavBar />
        <div className="container mt-4">
          <Routes>
            {/* Ścieżki publiczne */}
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            
            {/* Ścieżki chronione, wymagające logowania */}
            <Route path="/" element={
              <ProtectedRoute>
                <NoteList />
              </ProtectedRoute>
            } />
            
            <Route path="/notes/:id" element={
              <ProtectedRoute>
                <NoteDetail />
              </ProtectedRoute>
            } />
            
            <Route path="/create" element={
              <ProtectedRoute>
                <NoteForm />
              </ProtectedRoute>
            } />
            
            {/* Przekierowanie dla nieznanych ścieżek */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;