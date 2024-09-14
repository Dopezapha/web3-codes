import React from 'react';
import { Connect } from './components/Connect';
import { ContractInfo } from './components/ContractInfo';
import { UserActions } from './components/UserActions';
import { AdminActions } from './components/AdminActions';
import { useUser } from './contexts/UserContext';

function App() {
  const { userAddress } = useUser();

  return (
    <div className="App">
      <h1>STX Dividend Distribution</h1>
      <div className="card">
        <Connect />
      </div>
      {userAddress && (
        <>
          <div className="card">
            <ContractInfo />
          </div>
          <div className="card">
            <UserActions />
          </div>
          <div className="card">
            <AdminActions />
          </div>
        </>
      )}
    </div>
  );
}

export default App;
