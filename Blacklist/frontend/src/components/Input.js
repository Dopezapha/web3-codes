import React from 'react';

const Input = ({ type = 'text', name, value, onChange, placeholder }) => (
  <input
    type={type}
    name={name}
    value={value}
    onChange={onChange}
    placeholder={placeholder}
    className="input"
  />
);

export default Input;
