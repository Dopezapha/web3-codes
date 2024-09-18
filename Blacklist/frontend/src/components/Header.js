import React from 'react';
import { useConnect } from '@stacks/connect-react';

const Header = () => {
  const { authenticated, userSession } = useConnect();

  return (
    <header className="header">
      <h1>STX Blacklist Manager</h1>
      {authenticated ? (
        <div className="user-info">
          <span>Logged in as: {userSession.loadUserData().profile.stxAddress.mainnet}</span>
          <button onClick={() => userSession.signUserOut()}>Logout</button>
        </div>
      ) : (
        <button onClick={() => userSession.redirectToSignIn()}>Login</button>
      )}
    </header>
  );
};

export default Header;
