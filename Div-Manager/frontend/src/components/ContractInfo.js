import React, { useState, useEffect } from 'react';
import { getPayoutsPerToken, getContractHoldings } from '../api/contractInteractions';

export function ContractInfo() {
  const [payoutsPerToken, setPayoutsPerToken] = useState(0);
  const [contractHoldings, setContractHoldings] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchContractInfo = async () => {
      try {
        setLoading(true);
        const [ppt, holdings] = await Promise.all([
          getPayoutsPerToken(),
          getContractHoldings()
        ]);
        setPayoutsPerToken(ppt);
        setContractHoldings(holdings);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchContractInfo();
  }, []);

  if (loading) return <p>Loading contract info...</p>;
  if (error) return <p>Error: {error}</p>;

  return (
    <div>
      <h2>Contract Info</h2>
      <p>Payouts per Token: {payoutsPerToken}</p>
      <p>Contract Holdings: {contractHoldings} STX</p>
    </div>
  );
}
