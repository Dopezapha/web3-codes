import React, { useState } from 'react';
import { addPayouts, updateTokenSupply, withdrawUnclaimedPayouts } from '../api/contractInteractions';
import { useUser } from '../contexts/UserContext';
import { ADMIN_ADDRESS } from '../utils/constants';

export function AdminActions() {
  const [payoutAmount, setPayoutAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const { userAddress } = useUser();

  const isAdmin = userAddress === ADMIN_ADDRESS;

  const handleAddPayouts = async () => {
    try {
      setLoading(true);
      await addPayouts(parseInt(payoutAmount));
      setPayoutAmount('');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateTokenSupply = async () => {
    try {
      setLoading(true);
      await updateTokenSupply();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleWithdrawUnclaimed = async () => {
    try {
      setLoading(true);
      await withdrawUnclaimedPayouts();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (!isAdmin) return null;
  if (loading) return <p>Processing admin action...</p>;
  if (error) return <p>Error: {error}</p>;

  return (
    <div>
      <h2>Admin Actions</h2>
      <input
        type="number"
        value={payoutAmount}
        onChange={(e) => setPayoutAmount(e.target.value)}
        placeholder="Payout Amount"
      />
      <button onClick={handleAddPayouts}>Add Payouts</button>
      <button onClick={handleUpdateTokenSupply}>Update Token Supply</button>
      <button onClick={handleWithdrawUnclaimed}>Withdraw Unclaimed Payouts</button>
    </div>
  );
}
