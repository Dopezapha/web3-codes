import React from 'react';
import { useConnect } from '@stacks/connect-react';
import { useUser } from '../contexts/UserContext';

export function Connect() {
  const { doOpenAuth } = useConnect();
  const { userAddress, setUserAddress } = useUser();

  const handleConnect = () => {
    doOpenAuth();
  };

  const handleSignOut = () => {
    setUserAddress(null);
  };

  return (
    <div>
      {!userAddress ? (
        <button onClick={handleConnect}>Connect Wallet</button>
      ) : (
        <div>
          <p className="info-text">Connected: {userAddress}</p>
          <button onClick={handleSignOut}>Sign Out</button>
        </div>
      )}
    </div>
  );
}
