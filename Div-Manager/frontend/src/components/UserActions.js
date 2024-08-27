import React, { useState, useEffect } from 'react';
import { updateHoldings, claimPayouts, getClaimableSum } from '../api/contractInteractions';
import { useUser } from '../contexts/UserContext';

export function UserActions() {
  const [claimableAmount, setClaimableAmount] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const { userAddress } = useUser();

  useEffect(() => {
    fetchClaimableAmount();
  }, [userAddress]);

  const fetchClaimableAmount = async () => {
    try {
      const amount = await getClaimableSum(userAddress);
      setClaimableAmount(amount);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleUpdateHoldings = async () => {
    try {
      setLoading(true);
      await updateHoldings();
      await fetchClaimableAmount();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleClaimPayouts = async () => {
    try {
      setLoading(true);
      await claimPayouts();
      await fetchClaimableAmount();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <p>Processing...</p>;
  if (error) return <p>Error: {error}</p>;

  return (
    <div>
      <h2>User Actions</h2>
      <button onClick={handleUpdateHoldings}>Update Holdings</button>
      <button onClick={handleClaimPayouts}>Claim Payouts</button>
      <p>Claimable Amount: {claimableAmount} STX</p>
    </div>
  );
}
