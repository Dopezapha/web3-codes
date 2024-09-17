import React, { useState } from 'react';
import { Connect } from '@stacks/connect-react';
import { UserSession } from '@stacks/auth';
import AdminPanel from './components/AdminPanel';
import UserPanel from './components/UserPanel';
import Header from './components/Header';
import ErrorBoundary from './components/ErrorBoundary';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import './styles.css';

const App = () => {
  const [userSession] = useState(new UserSession());

  return (
    <Connect
      authOptions={{
        appDetails: {
          name: 'STX Blacklist Manager',
          icon: '/path/to/your/icon.png',
        },
        redirectTo: '/',
        userSession,
        onFinish: () => {
          window.location.reload();
        },
      }}
    >
      <ErrorBoundary>
        <div className="app-container">
          <Header />
          <main>
            <AdminPanel />
            <UserPanel />
          </main>
          <ToastContainer position="bottom-right" />
        </div>
      </ErrorBoundary>
    </Connect>
  );
};

export default App;