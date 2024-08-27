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
      <Connect />
      {userAddress && (
        <>
          <ContractInfo />
          <UserActions />
          <AdminActions />
        </>
      )}
    </div>
  );
}

export default App;
