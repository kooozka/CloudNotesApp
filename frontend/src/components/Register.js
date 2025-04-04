import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signUp, confirmSignUp } from '../services/authService';

const Register = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [stage, setStage] = useState('SIGN_UP'); // SIGN_UP, CONFIRM_CODE
  const [verificationCode, setVerificationCode] = useState('');
  
  const navigate = useNavigate();
  
  const handleSignUp = async (e) => {
    e.preventDefault();
    
    if (password !== confirmPassword) {
      setError('Hasła nie są identyczne');
      return;
    }
    
    setLoading(true);
    setError(null);
    
    try {
      await signUp(email, password, name);
      setStage('CONFIRM_CODE');
    } catch (err) {
      setError(err.message || 'Wystąpił błąd podczas rejestracji');
    } finally {
      setLoading(false);
    }
  };
  
  const handleConfirmCode = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      await confirmSignUp(email, verificationCode);
      // Rejestracja zakończona pomyślnie, przekieruj do logowania
      navigate('/login');
    } catch (err) {
      setError(err.message || 'Wystąpił błąd podczas weryfikacji kodu');
    } finally {
      setLoading(false);
    }
  };
  
  const renderSignUpForm = () => (
    <form onSubmit={handleSignUp}>
      <div className="mb-3">
        <label htmlFor="name" className="form-label">Imię i nazwisko</label>
        <input
          type="text"
          className="form-control"
          id="name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          disabled={loading}
          required
        />
      </div>
      
      <div className="mb-3">
        <label htmlFor="email" className="form-label">Email</label>
        <input
          type="email"
          className="form-control"
          id="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={loading}
          required
        />
      </div>
      
      <div className="mb-3">
        <label htmlFor="password" className="form-label">Hasło</label>
        <input
          type="password"
          className="form-control"
          id="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={loading}
          required
          minLength="8"
        />
        <small className="form-text text-muted">
          Hasło musi mieć co najmniej 8 znaków, w tym małe i wielkie litery oraz cyfry.
        </small>
      </div>
      
      <div className="mb-3">
        <label htmlFor="confirmPassword" className="form-label">Potwierdź hasło</label>
        <input
          type="password"
          className="form-control"
          id="confirmPassword"
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          disabled={loading}
          required
        />
      </div>
      
      <div className="d-grid gap-2">
        <button
          type="submit"
          className="btn btn-primary"
          disabled={loading}
        >
          {loading ? 'Rejestracja...' : 'Zarejestruj się'}
        </button>
      </div>
    </form>
  );
  
  const renderConfirmCodeForm = () => (
    <form onSubmit={handleConfirmCode}>
      <div className="mb-3">
        <label htmlFor="verificationCode" className="form-label">Kod weryfikacyjny</label>
        <input
          type="text"
          className="form-control"
          id="verificationCode"
          value={verificationCode}
          onChange={(e) => setVerificationCode(e.target.value)}
          disabled={loading}
          required
        />
        <small className="form-text text-muted">
          Wprowadź kod weryfikacyjny wysłany na adres email: {email}
        </small>
      </div>
      
      <div className="d-grid gap-2">
        <button
          type="submit"
          className="btn btn-primary"
          disabled={loading}
        >
          {loading ? 'Weryfikacja...' : 'Weryfikuj kod'}
        </button>
      </div>
    </form>
  );
  
  return (
    <div className="container mt-5">
      <div className="row justify-content-center">
        <div className="col-md-6">
          <div className="card">
            <div className="card-header">
              <h3>{stage === 'SIGN_UP' ? 'Zarejestruj się' : 'Weryfikacja kodu'}</h3>
            </div>
            <div className="card-body">
              {error && <div className="alert alert-danger">{error}</div>}
              
              {stage === 'SIGN_UP' ? renderSignUpForm() : renderConfirmCodeForm()}
              
              <div className="mt-3 text-center">
                <p>Masz już konto? <span className="link-primary" role="button" onClick={() => navigate('/login')}>Zaloguj się</span></p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;