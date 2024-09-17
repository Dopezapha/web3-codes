import React from 'react';

const Button = ({ children, onClick, disabled, className = '' }) => (
  <button
    className={`button ${className}`}
    onClick={onClick}
    disabled={disabled}
  >
    {children}
  </button>
);

export default Button;
