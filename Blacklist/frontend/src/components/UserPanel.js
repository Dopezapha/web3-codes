import React, { useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { callReadOnlyFunction } from '@stacks/transactions';
import { StacksMainnet } from '@stacks/network';
import { toast } from 'react-toastify';
import { contractAddress, contractName } from '../config';
import Button from './Button';
import Input from './Input';

const UserPanel = () => {
  const { doContractCall } = useConnect();
  const [formData, setFormData] = useState({
    amount: '',
    recipient: '',
    checkAddress: '',
  });
  const [isRestricted, setIsRestricted] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({ ...prevData, [name]: value }));
  };

  const handleSendSTX = async () => {
    setLoading(true);
    try {
      await doContractCall({
        network: new StacksMainnet(),
        contractAddress,
        contractName,
        functionName: 'send-stx',
        functionArgs: [parseInt(formData.amount), formData.recipient],
        onFinish: (data) => {
          console.log('Transaction:', data);
          toast.success('STX sent successfully');
        },
      });
    } catch (error) {
      console.error('Error:', error);
      toast.error(`Error sending STX: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleCheckRestricted = async () => {
    setLoading(true);
    try {
      const result = await callReadOnlyFunction({
        network: new StacksMainnet(),
        contractAddress,
        contractName,
        functionName: 'is-restricted',
        functionArgs: [formData.checkAddress],
      });
      setIsRestricted(result.value);
    } catch (error) {
      console.error('Error:', error);
      toast.error(`Error checking restriction: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="panel user-panel">
      <h2>User Panel</h2>
      <div className="form-group">
        <Input
          type="number"
          name="amount"
          value={formData.amount}
          onChange={handleInputChange}
          placeholder="Amount (in STX)"
        />
        <Input
          name="recipient"
          value={formData.recipient}
          onChange={handleInputChange}
          placeholder="Recipient Address"
        />
        <Button onClick={handleSendSTX} disabled={loading}>Send STX</Button>
      </div>
      <div className="form-group">
        <Input
          name="checkAddress"
          value={formData.checkAddress}
          onChange={handleInputChange}
          placeholder="Check Address"
        />
        <Button onClick={handleCheckRestricted} disabled={loading}>Check if Restricted</Button>
      </div>
      {isRestricted !== null && (
        <p className={`status ${isRestricted ? 'restricted' : 'not-restricted'}`}>
          Address is {isRestricted ? 'restricted' : 'not restricted'}
        </p>
      )}
    </section>
  );
};

export default UserPanel;
