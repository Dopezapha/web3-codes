import React, { useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { StacksMainnet } from '@stacks/network';
import { toast } from 'react-toastify';
import { contractAddress, contractName } from '../config';
import Button from './Button';
import Input from './Input';

const AdminPanel = () => {
  const { doContractCall } = useConnect();
  const [formData, setFormData] = useState({
    targetAddress: '',
    newAdmin: '',
    newFee: '',
    newFeeRecipient: '',
  });
  const [loading, setLoading] = useState(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({ ...prevData, [name]: value }));
  };

  const handleContractCall = async (functionName, functionArgs) => {
    setLoading(true);
    try {
      await doContractCall({
        network: new StacksMainnet(),
        contractAddress,
        contractName,
        functionName,
        functionArgs,
        onFinish: (data) => {
          console.log('Transaction:', data);
          toast.success(`${functionName} operation successful`);
        },
      });
    } catch (error) {
      console.error('Error:', error);
      toast.error(`Error in ${functionName}: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleRestrictAddress = () => handleContractCall('restrict-address', [formData.targetAddress]);
  const handleUnrestrictAddress = () => handleContractCall('unrestrict-address', [formData.targetAddress]);
  const handleUpdateAdmin = () => handleContractCall('update-admin', [formData.newAdmin]);
  const handleSetTransferFee = () => handleContractCall('set-transfer-fee', [parseInt(formData.newFee)]);
  const handleSetFeeRecipient = () => handleContractCall('set-fee-recipient', [formData.newFeeRecipient]);

  return (
    <section className="panel admin-panel">
      <h2>Admin Panel</h2>
      <div className="form-group">
        <Input
          name="targetAddress"
          value={formData.targetAddress}
          onChange={handleInputChange}
          placeholder="Target Address"
        />
        <Button onClick={handleRestrictAddress} disabled={loading}>Restrict Address</Button>
        <Button onClick={handleUnrestrictAddress} disabled={loading}>Unrestrict Address</Button>
      </div>
      <div className="form-group">
        <Input
          name="newAdmin"
          value={formData.newAdmin}
          onChange={handleInputChange}
          placeholder="New Admin Address"
        />
        <Button onClick={handleUpdateAdmin} disabled={loading}>Update Admin</Button>
      </div>
      <div className="form-group">
        <Input
          type="number"
          name="newFee"
          value={formData.newFee}
          onChange={handleInputChange}
          placeholder="New Transfer Fee"
        />
        <Button onClick={handleSetTransferFee} disabled={loading}>Set Transfer Fee</Button>
      </div>
      <div className="form-group">
        <Input
          name="newFeeRecipient"
          value={formData.newFeeRecipient}
          onChange={handleInputChange}
          placeholder="New Fee Recipient"
        />
        <Button onClick={handleSetFeeRecipient} disabled={loading}>Set Fee Recipient</Button>
      </div>
    </section>
  );
};

export default AdminPanel;
