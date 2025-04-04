import { signUp as amplifySignUp, confirmSignUp as amplifyConfirmSignUp, signIn as amplifySignIn, signOut as amplifySignOut, getCurrentUser as amplifyGetCurrentUser, fetchAuthSession } from 'aws-amplify/auth';

// Rejestracja nowego użytkownika
export const signUp = async (email, password, name) => {
  try {
    const { isSignUpComplete, userId, nextStep } = await amplifySignUp({
      username: email,
      password,
      options: {
        userAttributes: {
          email,
          name
        }
      }
    });
    return { isSignUpComplete, userId, nextStep };
  } catch (error) {
    console.error('Error signing up:', error);
    throw error;
  }
};

// Potwierdzenie rejestracji kodem z maila
export const confirmSignUp = async (email, code) => {
  try {
    const { isSignUpComplete, nextStep } = await amplifyConfirmSignUp({
      username: email,
      confirmationCode: code
    });
    return isSignUpComplete;
  } catch (error) {
    console.error('Error confirming sign up:', error);
    throw error;
  }
};

// Logowanie użytkownika
export const signIn = async (email, password) => {
  try {
    const { isSignedIn, nextStep } = await amplifySignIn({
      username: email,
      password
    });
    return { isSignedIn, nextStep };
  } catch (error) {
    console.error('Error signing in:', error);
    throw error;
  }
};

// Wylogowanie użytkownika
export const signOut = async () => {
  try {
    await amplifySignOut();
  } catch (error) {
    console.error('Error signing out:', error);
    throw error;
  }
};

// Pobranie aktualnego użytkownika
export const getCurrentUser = async () => {
  try {
    return await amplifyGetCurrentUser();
  } catch (error) {
    console.error('Error getting current user:', error);
    return null;
  }
};

// Pobranie tokenu JWT dla aktualnego użytkownika
export const getCurrentSession = async () => {
  try {
    const session = await fetchAuthSession();
    return session;
  } catch (error) {
    console.error('Error getting current session:', error);
    return null;
  }
};

// Pobranie tokenu JWT (do użycia w żądaniach API)
export const getIdToken = async () => {
  try {
    const session = await fetchAuthSession();
    return session.tokens?.idToken?.toString();
  } catch (error) {
    console.error('Error getting id token:', error);
    return null;
  }
};