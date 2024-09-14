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
  if (error) return <p className="error-message">Error: {error}</p>;

  return (
    <div>
      <h2>Contract Info</h2>
      <div className="data-display">
        <span className="data-label">Payouts per Token:</span>
        <span className="data-value"> {payoutsPerToken}</span>
      </div>
      <div className="data-display">
        <span className="data-label">Contract Holdings:</span>
        <span className="data-value"> {contractHoldings} STX</span>
      </div>
    </div>
  );
}
